FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 安装所有依赖在一个层中
RUN apt-get update && apt-get install -y \
    curl wget git unzip zip python3 python3-pip \
    libglu1-mesa libxcursor-dev libxrandr-dev libxinerama-dev libxi-dev \
    libx11-xcb-dev libgtk-3-0 libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcb1 libx11-6 libxcomposite1 \
    libxdamage1 libxext6 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
    libcairo2 libasound2 openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Flutter 3.38.5
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"
RUN mkdir -p $FLUTTER_HOME && \
    cd $FLUTTER_HOME && \
    wget --no-verbose --show-progress --progress=dot:mega -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.38.5-stable.tar.xz && \
    tar xf flutter_linux_3.38.5-stable.tar.xz --strip-components=1 && \
    rm flutter_linux_3.38.5-stable.tar.xz

# Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget --no-verbose --show-progress --progress=dot:mega -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# 接受许可证并安装 SDK 组件
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses
RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-35" "platforms;android-36" \
    "build-tools;34.0.0" "build-tools;36.0.0" \
    "cmake;3.22.1" \
    "ndk;28.2.13676358"

ENV PATH="/usr/local/bin:${PATH}"

# 预装 coscmd
RUN pip3 install coscmd

# Git 安全目录 (使用 --system 使所有用户可读)
RUN git config --system --add safe.directory /opt/flutter

# 预下载 Flutter 依赖
RUN flutter config --no-analytics && flutter precache && \
    flutter config --enable-android && flutter doctor --android-licenses

# 预缓存 Gradle distributions（可选，如遇网络问题可删除此步）
# ENV GRADLE_CACHE=/opt/gradle-cache
# RUN mkdir -p $GRADLE_CACHE/wrapper/dists && \
#     cd /tmp && \
#     wget -q https://services.gradle.org/distributions/gradle-8.12-bin.zip -O gradle-8.12.zip && \
#     unzip -q gradle-8.12.zip -d $GRADLE_CACHE/wrapper/dists/ && rm gradle-8.12.zip

WORKDIR /workspace
