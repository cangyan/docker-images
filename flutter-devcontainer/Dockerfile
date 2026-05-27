# 使用 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 设置非交互式安装
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    # 基础工具
    curl \
    wget \
    git \
    unzip \
    zip \
    vim \
    nano \
    sudo \
    software-properties-common \
    # Flutter 依赖
    libglu1-mesa \
    libxcursor-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxi-dev \
    libx11-xcb-dev \
    libgtk-3-0 \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcb1 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    # Android 开发依赖
    openjdk-17-jdk \
    # 网络和工具
    net-tools \
    iputils-ping \
    lcov \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    # 清理
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 设置 Java 环境变量
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# 下载并安装 Flutter 3.38.5
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN mkdir -p $FLUTTER_HOME && \
    cd $FLUTTER_HOME && \
    wget -q https://storage.flutter-io.cn/flutter_infra_release/releases/stable/linux/flutter_linux_3.38.5-stable.tar.xz && \
    tar xf flutter_linux_3.38.5-stable.tar.xz --strip-components=1 && \
    rm flutter_linux_3.38.5-stable.tar.xz

# 安装 Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# 设置 Android 环境变量
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# 接受 Android 许可证
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses

# 安装 Android SDK 组件（Android API 35）
RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" \
    # "emulator" \
    # "system-images;android-35;google_apis;x86_64" \
    # "system-images;android-35;google_apis_playstore;x86_64" \
    "ndk;26.1.10909125"

# 为兼容性安装 Android API 34
# RUN ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager \
#     "platforms;android-34" \
#     "build-tools;34.0.0" \
#     "system-images;android-34;google_apis;x86_64"

# 安装 CocoaPods 依赖（如果需要 iOS 开发）
# RUN apt-get update && apt-get install -y ruby-full && \
#     gem install cocoapods

# 配置 Git 安全目录（解决 Flutter 仓库权限问题）
RUN git config --global --add safe.directory /opt/flutter

# 创建非 root 用户
# ARG USERNAME=flutter
# ARG USER_UID=1000
# ARG USER_GID=$USER_UID
# RUN groupadd --gid $USER_GID $USERNAME && \
#     useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
#     echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
#     chmod 0440 /etc/sudoers

# 设置工作目录和权限
WORKDIR /workspace
# RUN chown -R $USERNAME:$USERNAME $FLUTTER_HOME && \
#     chown -R $USERNAME:$USERNAME $ANDROID_SDK_ROOT
#
# # 切换到非 root 用户
# USER $USERNAME

# 预下载 Flutter 依赖
RUN flutter config --no-analytics && \
    flutter precache && \
    flutter config --enable-android

# 预下载 Android 工具
RUN flutter doctor --android-licenses

# 验证安装
# RUN echo "Flutter 版本:" && flutter --version && \
#     echo -e "\nDart 版本:" && dart --version && \
#     echo -e "\nJava 版本:" && java -version && \
#     echo -e "\nAndroid SDK 版本:" && ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --list | grep "platforms;android-35"
