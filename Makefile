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
RED = \033[31m
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
OUTPUT_DIR := ./output
OUTPUT_NAME := libgrpc_server

# 定义测试根目录
TEST_ROOT := ./test

# 定义目标
TARGETS := armeabi-v7a arm64-v8a android_archive ios_framework

# 声明伪目标
.PHONY: test clean build all arm64-v8a armeabi-v7a android_archive ios_framework

# 默认目标
all: test build

build:
	@echo "Starting build process..."
	@for target in $(TARGETS); do \
		$(MAKE) $$target; \
	done

android_archive:
	@export GOARCH=arm && \
	export GOOS=android && \
	export CGO_ENABLED=1 && \
	gomobile bind -target=android -androidapi 21 -javapkg=com.mobvoyage.sdk -o $(OUTPUT_DIR)/android_archive/$(OUTPUT_NAME).aar ./cmd/gomobile && \
	printf "$(GREEN)Build android aar success$(RESET)\n" || \
	printf "$(RED)Build android aar failed$(RESET)\n"

ios_framework:
	@export GOARCH=arm64 && \
	export GOOS=ios && \
	export CGO_ENABLED=1 && \
	gomobile bind -target=ios -o $(OUTPUT_DIR)/ios_framework/$(OUTPUT_NAME).framework ./cmd/gomobile && \
	printf "$(GREEN)Build iOS framework success$(RESET)\n" || \
	printf "$(RED)Build iOS framework failed$(RESET)\n"

armeabi-v7a:
	@export GOARCH=arm && \
	export GOOS=android && \
	export CGO_ENABLED=1 && \
	export CC=$(ANDROID_NDK_HOME_UNIX)/toolchains/llvm/prebuilt/$(ARCH)/bin/armv7a-linux-androideabi21-clang && \
	go build -trimpath -buildmode=c-shared -o $(OUTPUT_DIR)/armeabi-v7a/$(OUTPUT_NAME).so -ldflags "-s -w" ./cmd/cgo/cgo_functions.go && \
	printf "$(GREEN)Build armeabi-v7a success$(RESET)\n" || \
	printf "$(RED)Build armeabi-v7a failed$(RESET)\n"

arm64-v8a:
	@export GOARCH=arm64 && \
	export GOOS=android && \
	export CGO_ENABLED=1 && \
	export CC=$(ANDROID_NDK_HOME_UNIX)/toolchains/llvm/prebuilt/$(ARCH)/bin/aarch64-linux-android21-clang && \
	go build -trimpath -buildmode=c-shared -o $(OUTPUT_DIR)/arm64-v8a/$(OUTPUT_NAME).so -ldflags "-s -w" ./cmd/cgo/cgo_functions.go && \
	printf "$(GREEN)Build arm64-v8a success$(RESET)\n" || \
	printf "$(RED)Build arm64-v8a failed$(RESET)\n"

# 清理规则
clean:
# 遍历TARGETS去清理
	@printf "$(YELLOW)Cleaning up...$(RESET)\n"
	@for target in $(TARGETS); do \
		if [ -e $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).so ]; then \
			printf "$(YELLOW)Removing $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).so$(RESET)\n"; \
			rm -rf $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).so; \
		fi; \
		if [ -e $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).h ]; then \
			printf "$(YELLOW)Removing $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).h$(RESET)\n"; \
			rm -rf $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).h; \
		fi; \
		if [ -e $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).aar ]; then \
			printf "$(YELLOW)Removing $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).aar$(RESET)\n"; \
			rm -rf $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).aar; \
		fi; \
		if [ -e $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME)-sources.jar ]; then \
			printf "$(YELLOW)Removing $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME)-sources.jar$(RESET)\n"; \
			rm -rf $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME)-sources.jar; \
		fi; \
		if [ -e $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).framework ]; then \
			printf "$(YELLOW)Removing $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).framework$(RESET)\n"; \
			rm -rf $(OUTPUT_DIR)/$$target/$(OUTPUT_NAME).framework; \
		fi; \
	done
	@printf "$(GREEN)Cleanup complete$(RESET)\n"

test:
	@echo "Running all Go tests in the test directory..."
	@go test -failfast -race $(TEST_ROOT)/...
	@if [ $$? -eq 0 ]; then \
		echo "All tests passed."; \
	else \
		echo "Some tests failed."; \
		exit 1; \
	fi