# go build 参数说明
# -trimpath: 去掉编译路径(移除源码路径信息,减小文件大小)
# -buildmode: 指定编译模式(默认为exe)
#   c-shared: 生成动态库文件
#   c-archive: 生成静态库文件
#   plugin: 指定插件
# -o: 指定输出文件名
# -ldflags: 指定链接参数(减小文件大小,提高启动速度)
#   -s: 去掉符号表
#   -w: 去掉调试信息

# 定义颜色，用于日志输出
GREEN = \033[32m
YELLOW = \033[33m
RESET = \033[0m

# 判断当前操作系统
ifeq ($(shell uname), Linux)
    ARCH := linux-x86_64
else ifeq ($(shell uname), Darwin)
    ARCH := darwin-x86_64
else ifeq ($(findstring MINGW32_NT-,$(shell uname -s)),MINGW32_NT-)
    ARCH := windows-x86_64
else ifeq ($(findstring MINGW64_NT-,$(shell uname -s)),MINGW64_NT-)
    ARCH := windows-x86_64
else ifeq ($(findstring CYGWIN_NT-,$(shell uname -s)),CYGWIN_NT-)
    ARCH := windows-x86_64
else
    $(error Unsupported OS type: $(shell uname -s))
endif

# 替换路径中的反斜杠为正斜杠
ANDROID_NDK_HOME_UNIX := $(subst \,/,$(ANDROID_NDK_HOME))

# 定义输出目录和文件名
OUT_DIR := ./pkg/sdk
OUT_FILE_NAME := libgrpc_server

# 定义目标
TARGETS := armeabi-v7a arm64-v8a

# 默认目标
all: $(TARGETS)

# 定义规则
armeabi-v7a:
	@printf "$(GREEN)Building armeabi-v7a$(RESET)\n"
	@export GOARCH=arm && \
	export GOOS=android && \
	export CGO_ENABLED=1 && \
	export CC=$(ANDROID_NDK_HOME_UNIX)/toolchains/llvm/prebuilt/$(ARCH)/bin/armv7a-linux-androideabi21-clang && \
		printf "$(YELLOW)Executing command: go build -trimpath -buildmode=c-shared -o $(OUT_DIR)/armeabi-v7a/$(OUT_FILE_NAME).so -ldflags \"-s -w\" ./cmd/cgo/cgo_functions.go$(RESET)\n" && \
	go build -trimpath -buildmode=c-shared -o $(OUT_DIR)/armeabi-v7a/$(OUT_FILE_NAME).so -ldflags "-s -w" ./cmd/cgo/cgo_functions.go
	@printf "$(GREEN)Build armeabi-v7a success$(RESET)\n"

arm64-v8a:
	@printf "$(GREEN)Building arm64-v8a$(RESET)\n"
	@export GOARCH=arm64 && \
	export GOOS=android && \
	export CGO_ENABLED=1 && \
	export CC=$(ANDROID_NDK_HOME_UNIX)/toolchains/llvm/prebuilt/$(ARCH)/bin/aarch64-linux-android21-clang && \
		printf "$(YELLOW)Executing command: go build -trimpath -buildmode=c-shared -o $(OUT_DIR)/arm64-v8a/$(OUT_FILE_NAME).so -ldflags \"-s -w\" ./cmd/cgo/cgo_functions.go$(RESET)\n" && \
	go build -trimpath -buildmode=c-shared -o $(OUT_DIR)/arm64-v8a/$(OUT_FILE_NAME).so -ldflags "-s -w" ./cmd/cgo/cgo_functions.go
	@printf "$(GREEN)Build arm64-v8a success$(RESET)\n"

# 清理规则
clean:
# 遍历TARGETS去清理
	@printf "$(YELLOW)Cleaning up...$(RESET)\n"
	@for target in $(TARGETS); do \
  		printf "$(YELLOW)Removing $(OUT_DIR)/$$target/$(OUT_FILE_NAME).so$(RESET)\n"; \
		rm -rf $(OUT_DIR)/$$target/$(OUT_FILE_NAME).so; \
				printf "$(YELLOW)Removing $(OUT_DIR)/$$target/$(OUT_FILE_NAME).h$(RESET)\n"; \
		rm -rf $(OUT_DIR)/$$target/$(OUT_FILE_NAME).h; \
	done
	@printf "$(GREEN)Cleanup complete$(RESET)\n"

