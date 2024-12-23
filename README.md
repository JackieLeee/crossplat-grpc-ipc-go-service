# 跨平台Go gRPC IPC 服务库
[![Build Status](https://github.com/JackieLeee/crossplat-grpc-ipc-go-service/actions/workflows/makefile.yml/badge.svg)](https://github.com/JackieLeee/crossplat-grpc-ipc-go-service/actions)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## 目录
- [简介](#简介)
- [目录说明](#目录说明)
  - [文件和目录描述](#文件和目录描述)
- [使用方法](#使用方法)
- [环境准备](#环境准备)
  - [安装NDK](#安装ndk)
  - [安装CMake](#安装cmake)
  - [动态链接库生成](#动态链接库生成)
- [相关仓库](#相关仓库)

## 简介

本仓库提供了一个用Go语言实现的gRPC服务动态链接库（DLL），用于跨平台进程间通信（IPC）。此服务可以轻松集成到各种客户端应用程序中，支持高效、可靠的IPC。

## 目录说明

项目遵循清晰的组织结构，下面列出了主要目录及其内容：
```
.
|-- CHANGELOG.md
|-- Makefile
|-- README.md
|-- api
|   `-- grpc_api.go
|-- cmd
|   `-- cgo
|       `-- cgo_functions.go
|-- go.mod
|-- go.sum
|-- internal
|   |-- native_grpc
|   |   |-- call_options.go
|   |   |-- headers.go
|   |   |-- method_invoker.go
|   |   `-- parameter.go
|   `-- pb
|       `-- greeter
|           |-- greeter.pb.go
|           `-- greeter_grpc.pb.go
|-- pkg
|   `-- sdk
|       |-- arm64-v8a
|       |   |-- libgrpc_server.h
|       |   `-- libgrpc_server.so
|       `-- armeabi-v7a
|           |-- libgrpc_server.h
|           `-- libgrpc_server.so
|-- protobuf
|   |-- README.md
|   `-- xxx
|       `-- xxx.proto
|-- scripts
|   `-- compile_protos.sh
`-- test
    `-- api
        |-- grpc_api_test.go
        |-- helloRequest.json
        `-- helloRequest.pb
```

### 文件和目录描述
- `CHANGELOG.md`: 记录了项目的变更历史。 
- `Makefile`: 包含了用于编译和其他任务的命令。 
- `api`: 存放gRPC服务的API接口实现。 
- `cmd`: 包含构建和运行服务的命令行工具代码。 
  - `cgo/cgo_functions.go`: C语言与Go语言交互的函数定义。 
- `internal`: 内部实现细节。 
  - `native_grpc/`: 底层gRPC传输的实现。
  - `pb/xxx/`: Protocol Buffers生成的代码。 
- `pkg/sdk/`: 预编译的动态链接库（DLL）文件。 
  - `arm64-v8a/` 和 `armeabi-v7a/`: 不同架构下的SDK文件。 
- `protobuf`: Protocol Buffers相关的文件和配置。 
  - `xxx/xxx.proto`: 定义了gRPC服务的消息格式。 
- `scripts`: 脚本文件，用于自动化任务。 
  - `compile_protos.sh`: 编译protobuf文件的脚本。
- `test/xxx/`: 测试代码目录，包含单元测试用例。 
  - `xxx_test.go`: 测试代码文件。

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