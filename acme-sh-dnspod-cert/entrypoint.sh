#!/bin/bash
set -e

ACME_BIN="/usr/local/bin/acme.sh"
CONFIG_FILE="${CONFIG_FILE:-/app/config.yml}"
LOG_FILE="/app/logs/cert-update.log"
LOG_DIR="/app/logs"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 发送企业微信通知
send_wecom() {
    local msgtype="$1"
    local content="$2"
    local webhook_url=$(grep "webhook_url:" "$CONFIG_FILE" | sed 's/.*webhook_url: *//' | tr -d '"')
    log "webhook_url=$webhook_url"

    local mentioned_list=$(grep "mentions:" "$CONFIG_FILE" -A 10 | grep "^-" | sed 's/^- *//' | tr '\n' ',' | sed 's/,$//')

    local payload
    if [ "$msgtype" = "markdown" ]; then
        payload=$(jq -n --arg content "$content" '{
            msgtype: "markdown",
            markdown: {
                content: $content
            }
        }')
    else
        payload=$(jq -n --arg content "$content" --argjson mentioned_list '[""]' '{
            msgtype: "text",
            text: {
                content: $content,
                mentioned_list: $mentioned_list
            }
        }')
    fi

    curl -s -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "$payload" >> "$LOG_FILE" 2>&1
}

# 上传证书到腾讯云并更新 CLB
upload_and_update_clb() {
    local domain="$1"
    local cert_alias="${2:-${domain}-letsencrypt}"

    log "上传证书到腾讯云: $domain"

    # 上传证书到腾讯云 SSL
    local cert_result
    cert_result=$(tccli ssl UploadCertificate \
        --cli-unfold-argument \
        --CertificatePublicKey "$(cat /tmp/${domain}.fullchain.cer)" \
        --CertificatePrivateKey "$(cat /tmp/${domain}.key)" \
        --Alias "$cert_alias" \
        2>> "$LOG_FILE")

    log "上传结果: $cert_result"

    # 提取证书 ID
    local cert_id
    cert_id=$(echo "$cert_result" | jq -r '.CertificateId // empty')

    if [ -z "$cert_id" ]; then
        log "证书上传失败，无法获取 CertificateId"
        return 1
    fi

    log "新证书 ID: $cert_id"

    echo "$cert_id"
}

# 处理单个域名的证书申请
process_domain() {
    local base_domain="$1"
    shift
    local -a wildcards=("$@")

    for wc in "${wildcards[@]}"; do
        # 通配符格式: * -> *.  ,  qa -> *.qa.
        if [ "$wc" = "*" ]; then
            local domain="*.${base_domain}"
        else
            local domain="*.${wc}.${base_domain}"
        fi
        log "申请证书: $domain (wc=$wc)"

        # 先申请证书 (DNS API 验证)
        log "acme.sh 路径: $(which acme.sh 2>/dev/null || echo 'not found')"
        log "acme.sh 目录: $(ls -la /root/.acme.sh/ 2>/dev/null | head -5)"

        ACME_BIN="/usr/local/bin/acme.sh"
        log "执行: $ACME_BIN --issue --dns dns_dp -d \"$domain\""
        log "DNSPOD_DP_Id=$DNSPOD_DP_ID, DNSPOD_DP_Key length=${#DNSPOD_DP_KEY}"

        # 设置 DNS 变量后执行
        export DP_Id="$DNSPOD_DP_ID"
        export DP_Key="$DNSPOD_DP_KEY"

        log "exported DP_Id=$DP_Id, DP_Key length=${#DP_Key}"

        # 直接执行，输出到 stdout（实时）
        $ACME_BIN --issue --dns dns_dp -d "$domain" --server letsencrypt 2>&1 | while IFS= read -r line; do log "ACME: $line"; done
        local exit_code=${PIPESTATUS[0]}
        log "acme.sh --issue 退出码: $exit_code"

        if [ $exit_code -ne 0 ]; then
            log "证书申请失败: $domain (exit=$exit_code)"
            log "错误详情: $acme_output"
            continue
        fi

        # 安装证书并配置 reloadcmd
        local reload_cmd="bash /app/upload-cert.sh \"$domain\" \"${domain}-letsencrypt\""

        log "执行: $ACME_BIN --install-cert -d \"$domain\" ..."
        $ACME_BIN --install-cert -d "$domain" \
            --key-file "/tmp/${domain}.key" \
            --fullchain-file "/tmp/${domain}.fullchain.cer" \
            --reloadcmd "$reload_cmd" \
            2>&1 | tee -a "$LOG_FILE" || log "证书安装失败: $domain"
    done
}

# 主流程
main() {
    # 确保日志目录存在
    mkdir -p /app/logs

    log "===== 开始证书更新 ====="

    # 读取配置
    log "读取配置文件: $CONFIG_FILE"
    ACME_EMAIL=$(grep "email:" "$CONFIG_FILE" | head -1 | sed 's/.*email: *//' | tr -d '"')
    log "ACME_EMAIL=$ACME_EMAIL"

    # 读取 DNSPod 配置
    log "读取 DNSPod 配置..."
    log "原始 dp_id grep 结果: $(grep -A5 "dnspod:" "$CONFIG_FILE" | grep "dp_id:" | cat)"
    log "原始 dp_key grep 结果: $(grep -A5 "dnspod:" "$CONFIG_FILE" | grep "dp_key:" | cat)"

    # 读取并展开 ${VAR} 格式的环境变量
    local raw_dp_id=$(grep -A5 "dnspod:" "$CONFIG_FILE" | grep "dp_id:" | sed 's/.*dp_id: *//' | tr -d '"')
    local raw_dp_key=$(grep -A5 "dnspod:" "$CONFIG_FILE" | grep "dp_key:" | sed 's/.*dp_key: *//' | tr -d '"')

    # 展开 ${VAR} 格式的环境变量
    DNSPOD_DP_ID=$(eval echo "$raw_dp_id" 2>/dev/null || echo "$raw_dp_id")
    DNSPOD_DP_KEY=$(eval echo "$raw_dp_key" 2>/dev/null || echo "$raw_dp_key")

    log "DNSPOD_DP_ID=$DNSPOD_DP_ID"
    log "DNSPOD_DP_KEY=[$DNSPOD_DP_KEY] (len=${#DNSPOD_DP_KEY})"

    # 读取腾讯云配置
    TC_SECRET_ID=$(grep "secret_id:" "$CONFIG_FILE" | sed 's/.*secret_id: *//' | tr -d '${}')
    TC_SECRET_KEY=$(grep "secret_key:" "$CONFIG_FILE" | sed 's/.*secret_key: *//' | tr -d '${}')
    TC_REGION=$(grep "region:" "$CONFIG_FILE" | sed 's/.*region: *//' | tr -d '"')
    log "TC_SECRET_ID=$TC_SECRET_ID"

    log "配置腾讯云 CLI"
    tccli configure set secretId "$TC_SECRET_ID" secretKey "$TC_SECRET_KEY" region "$TC_REGION"

    log "注册 acme.sh 账户: $ACME_EMAIL"
    # 清除旧的 acme.sh 账户数据（安装时用的 example.com），用真实邮箱重新注册
    rm -rf /root/.acme.sh/account.conf 2>/dev/null || true
    $ACME_BIN --register-account -m "$ACME_EMAIL" --server letsencrypt 2>&1 | while IFS= read -r line; do
        log "ACME: $line"
    done

    # 配置 DNSPod API 环境变量
    export DP_Id="$DNSPOD_DP_ID"
    export DP_Key="$DNSPOD_DP_KEY"

    # 解析域名配置 - 使用 awk 更精确
    # 期望格式:
    # domains:
    #   - base_domain: example.com
    #     wildcard_levels:
    #       - "*"
    #       - "qa"

    local domains_data=$(awk '
    BEGIN { in_domains=0; in_wildcards=0; bd=""; wc_list="" }
    /^domains:/ { in_domains=1; next }
    !in_domains { next }
    /base_domain:/ {
        # 处理前一个域名
        if (bd != "" && wc_list != "") {
            # 去掉末尾逗号
            gsub(/,$/, "", wc_list)
            print bd ":" wc_list
        }
        # 提取新的 base_domain
        sub(/.*base_domain:\s*/, "")
        gsub(/[ "]/, "", $0)
        bd = $0
        wc_list = ""
        in_wildcards = 0
        next
    }
    /wildcard_levels:/ { in_wildcards = 1; next }
    /^[^ ]/ { in_wildcards = 0; next }
    in_wildcards && /^\s+-\s+"/ {
        sub(/.*-\s*"/, "")
        sub(/".*/, "")
        gsub(/ /, "", $0)
        if ($0 != "") wc_list = wc_list $0 ","
    }
    END {
        if (bd != "" && wc_list != "") {
            gsub(/,$/, "", wc_list)
            print bd ":" wc_list
        }
    }
    ' "$CONFIG_FILE")

    log "解析到的域名数据: $domains_data"

    # 逐行处理域名数据
    echo "$domains_data" | while IFS= read -r line; do
        [ -z "$line" ] && continue
        local base=$(echo "$line" | cut -d: -f1)
        local wildcards=$(echo "$line" | cut -d: -f2)
        log "DEBUG: base=$base wildcards=$wildcards"
        # 使用 printf + read -ra 避免 * 被 glob 展开
        printf -v wildcards_str '%s' "$wildcards"
        IFS=',' read -ra wc_array <<< "$wildcards_str"
        for wc in "${wc_array[@]}"; do
            log "DEBUG: wc=$wc"
        done
        process_domain "$base" "${wc_array[@]}"
    done

    # 配置定时任务
    CRON_ENABLED=$(grep "enabled:" "$CONFIG_FILE" | sed 's/^  enabled: *//' | tr -d '"')
    if [ "$CRON_ENABLED" = "true" ]; then
        CRON_SCHEDULE=$(grep "schedule:" "$CONFIG_FILE" | sed 's/^  schedule: *//' | tr -d '"')
        log "配置定时任务: $CRON_SCHEDULE"
        echo "$CRON_SCHEDULE /app/entrypoint.sh >> /app/logs/cert-cron.log 2>&1" > /etc/crontabs/root
        crond -f &
    fi

    log "===== 证书更新完成 ====="
}

main "$@"
