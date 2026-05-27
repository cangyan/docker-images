FROM alpine:3.18

# 安装依赖
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    tzdata \
    py3-pip \
    dcron \
    && pip3 install --no-cache-dir tccli

# 安装 acme.sh
RUN apk add --no-cache git openssl && \
    git clone https://github.com/acmesh-official/acme.sh.git /tmp/acme && \
    cd /tmp/acme && \
    ./acme.sh --install --email default@example.com --force && \
    cp acme.sh /usr/local/bin/ && \
    cd / && rm -rf /tmp/acme

# 复制脚本
COPY entrypoint.sh /app/entrypoint.sh
COPY upload-cert.sh /app/upload-cert.sh
RUN chmod +x /app/entrypoint.sh /app/upload-cert.sh

# 创建证书目录
RUN mkdir -p /app/certs /app/logs

WORKDIR /app

# 默认执行证书更新
CMD ["/app/entrypoint.sh"]