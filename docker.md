# 编译docker

## 构建镜像

```bash
make docker
```

## 运行容器

```bash
make build
```

## 编译
在docker中执行：
```bash
$ ./gradlew build
$ ./gradlew packageDebugAndroidTest
```

## 输出的apk

* app/build/outputs/apk/release/app-release.apk
* app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
