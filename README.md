# 跨平台Go gRPC IPC 服务库

## 简介

本仓库提供了一个用Go语言实现的gRPC服务动态链接库（DLL），用于跨平台进程间通信（IPC）。此服务可以轻松集成到各种客户端应用程序中，支持高效、可靠的IPC。

## 使用方法

将生成的DLL文件添加到您的项目中，并调用提供的API接口即可使用服务。

## 环境准备

在开始之前，请根据您的操作系统安装并配置以下工具：

### 安装NDK

下载[NDK](https://developer.android.google.cn/ndk/downloads)并设置环境变量`ANDROID_NDK_HOME`：

```shell
# Windows
set ANDROID_NDK_HOME=<path_to_ndk>

# macOS/Linux
export ANDROID_NDK_HOME=<path_to_ndk>
```

### 安装CMake

下载并安装[cmake](https://cmake.org/download/)，然后将路径添加到环境变量`PATH`中：

```shell
# Windows
set PATH=%PATH%;<path_to_cmake_bin>

# macOS/Linux
export PATH=$PATH:<path_to_cmake_bin>
```

### 动态链接库生成

在项目根目录下运行以下命令以生成so文件：

```shell
make
```

## 相关仓库

了解整个项目的其他组件，请访问以下仓库：

- Protocol Buffers定义：[crossplat-grpc-ipc-protobuf-defs](https://github.com/JackieLeee/crossplat-grpc-ipc-protobuf-defs)

- Android客户端实现：[crossplat-grpc-ipc-android-client](https://github.com/JackieLeee/crossplat-grpc-ipc-android-client)