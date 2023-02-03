FROM amazon/aws-cli:2.9.20

RUN yum -y install tar gzip \
    && curl -Lo /usr/local/bin/aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64 \
    && chmod +x /usr/local/bin/aws-iam-authenticator \
    && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    && chmod +x get_helm.sh \
    && VERIFY_CHECKSUM=false ./get_helm.sh \
    && rm get_helm.sh \
    && curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.9/2023-01-11/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl


