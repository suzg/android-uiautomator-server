FROM ubuntu:18.04 as downloader
MAINTAINER suzg
RUN sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list && \
    sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list

RUN apt-get update && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ARG cmdline_tools=https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip
RUN mkdir /downloads && \
    wget --progress=bar:force -O /downloads/commandlinetools-linux-6858069_latest.zip "${cmdline_tools}" && \
    wget --progress=bar:force -O /downloads/gradle-4.6-all.zip https://services.gradle.org/distributions/gradle-4.6-all.zip

FROM ubuntu:18.04  AS final
MAINTAINER suzg

RUN sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list && \
    sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget curl ca-certificates gnupg2 software-properties-common unzip xz-utils file \
        openssh-client make git git-lfs zip libxml2 libxml2-dev build-essential vim \
        locales libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386 \
        openjdk-8-jdk-headless less tzdata exuberant-ctags \
        socat sudo && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ant && \
    dpkg-reconfigure -f noninteractive tzdata && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure -f noninteractive locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG home=/home/user
ARG android_home=/opt/android/sdk

ENV ANDROID_HOME=${android_home} \
    ANDROID_SDK_ROOT=${android_home} \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    HOME=${home} \
    GRADLE_USER_HOME=${home}/.gradle
ENV PATH=${ANDROID_SDK_ROOT}/cmdline-tools/bin:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${NDK}:${PATH}

COPY --from=downloader /downloads/commandlinetools-linux-6858069_latest.zip /tmp/cmdline-tools.zip
RUN mkdir -p ${android_home} && \
    unzip -q /tmp/cmdline-tools.zip -d ${android_home} && \
    rm /tmp/cmdline-tools.zip

RUN mkdir -p ${home}/.android && echo '### User Sources for Android SDK Manager' > ${home}/.android/repositories.cfg
RUN yes | sdkmanager --licenses --sdk_root=$ANDROID_SDK_ROOT && \
    yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT \
        "platforms;android-28" \
        "build-tools;28.0.3" \
        && \
    rm -rf /opt/android/sdk/emulator

COPY app ${home}/project/app
COPY permission ${home}/project/permission
COPY gradle ${home}/project/gradle
COPY build.gradle ${home}/project/build.gradle
COPY gradlew ${home}/project/gradlew
COPY settings.gradle ${home}/project/settings.gradle
COPY gradle.properties ${home}/project/gradle.properties
COPY release.keystore ${home}/project/release.keystore
COPY debug.keystore ${home}/.android/debug.keystore
COPY debug.keystore ${home}/project/debug.keystore

COPY --from=downloader /downloads/gradle-4.6-all.zip ${home}/project/gradle/wrapper/gradle-4.6-all.zip
RUN cd ${home}/project && \
    ./gradlew --no-daemon build && \
    ./gradlew --no-daemon packageDebugAndroidTest && \
    rm ${home}/project/gradle/wrapper/gradle-4.6-all.zip && \
    rm -rf ${home}/project && \
    chmod -R 777 ${GRADLE_USER_HOME} && \
    chmod -R 777 /home/user/.android

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR ${home}/project
