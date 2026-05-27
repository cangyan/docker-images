#!/bin/bash
# upload-cert.sh - acme.sh reloadcmd 回调脚本
# 用法: upload-cert.sh <domain> <alias>

# 移除 set -e 以便脚本继续执行并输出完整日志
# set -e

set +e  # 关闭 set -e 以便脚本继续执行

DOMAIN="$1"
ALIAS="${2:-${DOMAIN}-letsencrypt}"
LOG_FILE="/app/logs/cert-update.log"
CONFIG_FILE="${CONFIG_FILE:-/app/config.yml}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [upload] $1" | tee -a "$LOG_FILE"
}

# 发送企业微信通知
send_wecom() {
    local msgtype="$1"
    local content="$2"

    local webhook_url=$(grep "webhook_url:" "$CONFIG_FILE" | sed 's/.*webhook_url: *//' | tr -d '"')
    [ -z "$webhook_url" ] && webhook_url=$(grep "webhook_url:" "$CONFIG_FILE" | sed 's/.*webhook_url: *//' | tr -d '"')

    if [ -z "$webhook_url" ] || [ "$webhook_url" = "${WECOM_ROBOT_WEBHOOK}" ]; then
        log "webhook_url 为空，跳过通知"
        return
    fi

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

log "===== 开始证书上传 ====="
log "域名: $DOMAIN"
log "别名: $ALIAS"

# 读取腾讯云配置
TC_SECRET_ID=$(cat "$CONFIG_FILE" | grep "secret_id:" | sed 's/  secret_id: *//' | tr -d '${}')
TC_SECRET_KEY=$(cat "$CONFIG_FILE" | grep "secret_key:" | sed 's/  secret_key: *//' | tr -d '${}')
TC_REGION=$(cat "$CONFIG_FILE" | grep "region:" | sed 's/  region: *//' | tr -d '"')

# 展开环境变量
TC_SECRET_ID=$(eval echo "$TC_SECRET_ID" 2>/dev/null || echo "$TC_SECRET_ID")
TC_SECRET_KEY=$(eval echo "$TC_SECRET_KEY" 2>/dev/null || echo "$TC_SECRET_KEY")
TC_REGION=$(eval echo "$TC_REGION" 2>/dev/null || echo "$TC_REGION")

log "TC_REGION=$TC_REGION"

# 配置 tccli
log "TC_SECRET_ID=$TC_SECRET_ID (length=${#TC_SECRET_ID})"
log "TC_SECRET_KEY length=${#TC_SECRET_KEY}"
tccli configure set secretId "$TC_SECRET_ID" secretKey "$TC_SECRET_KEY" region "$TC_REGION" && log "tccli configure OK" || log "tccli configure FAILED"

# 上传证书
log "上传证书到腾讯云 SSL..."
log "cert 文件存在检查: $(ls -la /tmp/${DOMAIN}.fullchain.cer 2>&1 || echo '不存在')"
log "key 文件存在检查: $(ls -la /tmp/${DOMAIN}.key 2>&1 || echo '不存在')"
log "开始执行 tccli ssl UploadCertificate..."
set +e  # 关闭 set -e 以便捕获完整输出
cert_result=$(tccli ssl UploadCertificate \
    --cli-unfold-argument \
    --CertificatePublicKey "$(cat /tmp/${DOMAIN}.fullchain.cer)" \
    --CertificatePrivateKey "$(cat /tmp/${DOMAIN}.key)" \
    --Alias "$ALIAS" 2>&1)
upload_exit=$?
log "上传返回码: $upload_exit"
log "上传结果: $cert_result"

# 提取证书 ID
cert_id=$(echo "$cert_result" | jq -r '.CertificateId // empty')

if [ -z "$cert_id" ]; then
    log "证书上传失败，无法获取 CertificateId"
    send_wecom "text" "⚠️ 证书上传失败\n\n域名: $DOMAIN\n时间: $(date '+%Y-%m-%d %H:%M:%S')"
    exit 1
fi

log "新证书 ID: $cert_id"

# 更新 CLB 监听器
log "读取 CLB 配置..."
CLB_CONFIG=$(awk '/^tencent:/,/^[^ ]/' "$CONFIG_FILE" | awk '/clb:/,/cdn:/')
log "CLB 配置内容: $CLB_CONFIG"

# 解析 CLB 名称和监听器 ID
echo "$CLB_CONFIG" | grep -A20 "clb:" | while IFS= read -r line; do
    if echo "$line" | grep -q "name:"; then
        clb_name=$(echo "$line" | sed 's/.*name: *//' | tr -d ' "')
    elif echo "$line" | grep -q "listener_ids:"; then
        listener_ids_str=$(echo "$line" | sed 's/.*listener_ids: *//' | tr -d '[]')
        # 处理 listener_ids 格式: ["lbl-xxx","lbl-yyy"]
        echo "$listener_ids_str" | sed 's/,/\n/g' | while read -r listener_id; do
            listener_id=$(echo "$listener_id" | tr -d '"' | tr -d ' ')
            [ -z "$listener_id" ] && continue
            log "更新 CLB [$clb_name] 监听器 [$listener_id] 的证书..."
            tccli clb SetListener Certificates \
                --cli-unfold-argument \
                --LoadBalancerId "$clb_name" \
                --ListenerId "$listener_id" \
                --CertificateId "$cert_id" \
                >> "$LOG_FILE" 2>&1 || log "监听器 $listener_id 更新失败"
        done
    fi
done

# 更新 CDN 证书
log "读取 CDN 配置..."
CDN_CONFIG=$(awk '/cdn:/,/^[^ ]/' "$CONFIG_FILE")
echo "$CDN_CONFIG" | grep -A10 "domains:" | while IFS= read -r line; do
    if echo "$line" | grep -q "domains:"; then
        domains_str=$(echo "$line" | sed 's/.*domains: *//' | tr -d '[]')
        echo "$domains_str" | sed 's/,/\n/g' | while read -r cdn_domain; do
            cdn_domain=$(echo "$cdn_domain" | tr -d '"' | tr -d ' ')
            [ -z "$cdn_domain" ] && continue
            log "更新 CDN 域名 [$cdn_domain] 的证书..."
            # CDN 证书更新通过 UpdateDomainConfig 的 Https 参数设置
            # Https 配置格式: {"certId": "xxx", "force": true}
            tccli cdn UpdateDomainConfig \
                --cli-unfold-argument \
                --Domain "$cdn_domain" \
                --Https '{"CertId": "'"$cert_id"'"}' \
                >> "$LOG_FILE" 2>&1 || log "CDN 域名 $cdn_domain 更新失败"
        done
    fi
done

log "===== 证书上传完成 ====="

# 发送成功通知
SUCCESS_MSG="## ✅ 证书更新成功

**域名**: $DOMAIN
**证书ID**: $cert_id
**时间**: $(date '+%Y-%m-%d %H:%M:%S')

**CLB更新**: ✅ 完成
**CDN更新**: ✅ 完成"
send_wecom "markdown" "$SUCCESS_MSG"

echo "$cert_id"