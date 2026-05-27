# acme-sh-dnspod-cert

使用 acme.sh + DNSPod API 自动为指定域名生成通配符证书，并上传到腾讯云 CLB/CDN。

## 功能

- acme.sh DNS API 模式自动申请通配符证书
- 支持多级通配符：`*.example.com`、`*.qa.example.com`
- tccli 上传证书到腾讯云
- 自动更新 CLB 监听器证书、CDN 证书
- 企业微信机器人推送执行结果
- 定时自动执行（每周一次）

## 环境变量

| 变量 | 说明 |
|------|------|
| `ACME_EMAIL` | acme.sh 注册邮箱 |
| `DNSPOD_DP_ID` | DNSPod API ID |
| `DNSPOD_DP_KEY` | DNSPod API Key |
| `TC_SECRET_ID` | 腾讯云 SecretId |
| `TC_SECRET_KEY` | 腾讯云 SecretKey |
| `WECOM_ROBOT_WEBHOOK` | 企业微信机器人 Webhook URL |

## 配置

编辑 `config.yml` 配置域名和云服务：

```yaml
acme:
  email: "${ACME_EMAIL}"

dnspod:
  dp_id: "${DNSPOD_DP_ID}"
  dp_key: "${DNSPOD_DP_KEY}"

domains:
  - base_domain: example.com
    wildcard_levels:
      - "*"           # *.example.com
      - "qa"          # *.qa.example.com

tencent:
  region: ap-guangzhou
  services:
    clb:
      - name: web-lb
        listener_ids: ["lbl-xxx"]
    cdn:
      - domains: ["*.example.com"]

wecom:
  webhook_url: "${WECOM_ROBOT_WEBHOOK}"

cron:
  schedule: "0 3 * * 7"  # 每周日凌晨3点
  enabled: true
```

## 使用

### 构建镜像

```bash
docker build -t acme-sh-dnspod-cert:latest .
```

### 运行

```bash
# 手动执行证书更新
docker run --rm \
  -v $(pwd)/config.yml:/app/config.yml:ro \
  -e ACME_EMAIL="admin@example.com" \
  -e DNSPOD_DP_ID="12345" \
  -e DNSPOD_DP_KEY="abcdef" \
  -e TC_SECRET_ID="xxx" \
  -e TC_SECRET_KEY="yyy" \
  -e WECOM_ROBOT_WEBHOOK="https://qyapi.weixin.qq.com/..." \
  acme-sh-dnspod-cert:latest
```

### 定时任务

容器启动后自动配置 cron 任务，每周日 03:00 自动执行。

## 证书路径

- 证书文件: `/app/certs/`
- 日志文件: `/app/logs/cert-update.log`

## 通知示例

成功时发送 Markdown 报告：
```markdown
## 证书更新报告

**状态**: ✅ 成功
**执行时间**: 2026-05-27 03:00:00

**CLB更新**: web-lb ✅
**CDN更新**: 3个域名 ✅
```

失败时发送告警：
```markdown
⚠️ 证书更新失败

**原因**: DNSPod API 限流
**时间**: 2026-05-27 03:00:00
```