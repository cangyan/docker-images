ARG ALPINE_VERSION=3.16
FROM python:3.10.8-alpine${ALPINE_VERSION} as aws-cli-builder

# Install build dependencies
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake

# Clone awscli
ARG AWS_CLI_VERSION=2.9.20
RUN git clone https://github.com/aws/aws-cli.git --single-branch -b ${AWS_CLI_VERSION} awscli

# Build process
WORKDIR awscli
# RUN sed -i'' 's/PyInstaller.*/PyInstaller==5.2/g' requirements-build.txt
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

# Remove examples as unnecessary
RUN rm -rf /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

FROM alpine:3.17.1 as builder

RUN apk update \
    && apk add --no-cache ca-certificates curl bash \
    && curl -Lo /usr/local/bin/aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64 \
    && chmod +x /usr/local/bin/aws-iam-authenticator \
    && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    && chmod +x get_helm.sh \
    && VERIFY_CHECKSUM=false ./get_helm.sh \
    && rm get_helm.sh \
    && curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.9/2023-01-11/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl \
    && rm /var/cache/apk/*


FROM alpine:3.17.1
RUN apk add --no-cache curl
COPY --from=aws-cli-builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws-cli-builder /aws-cli-bin/ /usr/local/bin/
COPY --from=builder /usr/local/bin/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl


