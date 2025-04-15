#!/bin/bash

# 新增统一日志函数
log() {
    # 颜色定义
    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    RESET="\033[0m"

    # 新增日志级别控制 (INFO/WARN/ERROR/DEBUG)
    LOG_LEVEL=${LOG_LEVEL:-INFO}
    # 新增日志前缀模板
    LOG_PREFIX="[$(date +'%T')] ${YELLOW}PROTO_BUILDER${RESET}"

    local level=$1
    shift
    local message="$*"
    local color=""

    case "$level" in
        INFO)  color="$GREEN"  ;;
        WARN)  color="$YELLOW" ;;
        ERROR) color="$RED"    ;;
        DEBUG) color="$BLUE"   ;;
    esac

    # 日志级别过滤
    [[ "$level" == "DEBUG" && "$LOG_LEVEL" != "DEBUG" ]] && return

    echo -e "${LOG_PREFIX} ${color}[${level}]${RESET} ${message}"
}

# 初始化
init() {
    # 获取项目根目录
    if ! PROJECT_ROOT=$(git rev-parse --show-toplevel); then
        log ERROR "Failed to determine project root. Ensure you are in a Git repository."
        exit 1
    fi

    log INFO "Project Root: ${PROJECT_ROOT}"

    # 设置源目录和目标目录
    PROTOBUF_DIR="${PROJECT_ROOT}/protobuf"
    OUTPUT_DIR="${PROJECT_ROOT}/protocol"
    # 配置文件路径
    CONFIG_FILE="${PROJECT_ROOT}/scripts/proto_build.conf"

    # 初始化数组
    declare -a ENABLED_MODULES=()
    declare -a EXCLUDED_MODULES=()
}

# 解析配置
parse_config() {
    log INFO "Loading build config from: ${CONFIG_FILE}"
    [[ ! -f "$CONFIG_FILE" ]] && {
        log WARN "No config file found, building all modules"
        return
    }

    local section=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Enhanced line processing
        line="${line%%#*}"  # Remove comments
        line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -z "$line" ]] && continue

        # Section detection
        if [[ "$line" =~ ^\[([a-zA-Z]+)\]$ ]]; then
            section="${BASH_REMATCH[1],,}"
            log DEBUG "Found section: ${section}"
            continue
        fi

        # Pattern validation and array assignment
        case "$section" in
            include)
                [[ "$line" =~ ^[^.]+\.[^.]+$ ]] || {
                    log ERROR "Invalid pattern: '${line}' (must contain exactly one dot)"
                    exit 1
                }
                ENABLED_MODULES+=("$line")
                log DEBUG "Added include pattern: ${line}"
                ;;
            exclude)
                [[ "$line" =~ ^[^.]+\.[^.]+$ ]] || {
                    log ERROR "Invalid pattern: '${line}' (must contain exactly one dot)"
                    exit 1
                }
                EXCLUDED_MODULES+=("$line")
                log DEBUG "Added exclude pattern: ${line}"
                ;;
            *)
                [[ -n "$section" ]] && {
                    echo -e "${RED}Error: Undefined section '${section}'${RESET}"
                    exit 1
                }
                ;;
        esac
    done < "$CONFIG_FILE"

    # Debug output
    log DEBUG "Parsed configuration:\nENABLED_MODULES: ${ENABLED_MODULES[*]}\nEXCLUDED_MODULES: ${EXCLUDED_MODULES[*]}"
}

# 生成构建列表
generate_build_list() {
    log INFO "=== GENERATING BUILD LIST ==="
    log INFO "Include Patterns: ${ENABLED_MODULES[*]}"
    log INFO "Exclude Patterns: ${EXCLUDED_MODULES[*]}"

    declare -gA BUILD_LIST=()

    # Process includes with wildcards
    for pattern in "${ENABLED_MODULES[@]}"; do
        IFS='.' read -r ver_pat svc_pat <<< "$pattern"
        log DEBUG "Processing pattern: ${ver_pat}.${svc_pat}"

        while IFS= read -r -d $'\0' dir; do
            version=$(basename "$(dirname "$dir")")
            service=$(basename "$dir")
            BUILD_LIST["${version}/${service}"]=1
            log DEBUG "Matched: ${version}/${service}"
        done < <(find "${PROTOBUF_DIR}" -type d \
                -path "${PROTOBUF_DIR}/${ver_pat}/${svc_pat}" -print0 2>/dev/null)
    done

    # Process excludes
    for pattern in "${EXCLUDED_MODULES[@]}"; do
        IFS='.' read -r ver_pat svc_pat <<< "$pattern"
        log DEBUG "Excluding pattern: ${ver_pat}.${svc_pat}"

        while IFS= read -r -d $'\0' dir; do
            version=$(basename "$(dirname "$dir")")
            service=$(basename "$dir")
            unset 'BUILD_LIST["'"${version}/${service}"'"]'
            log DEBUG "Excluded: ${version}/${service}"
        done < <(find "${PROTOBUF_DIR}" -type d \
                -path "${PROTOBUF_DIR}/${ver_pat}/${svc_pat}" -print0 2>/dev/null)
    done

    log INFO "Active Build Targets (${#BUILD_LIST[@]}):"
    for target in "${!BUILD_LIST[@]}"; do
        log INFO "  ➔ ${target}"  # 统一使用 INFO 级别
    done
    [[ ${#BUILD_LIST[@]} -eq 0 ]] && log WARN "No build targets matched"
}

# 编译proto文件
compile_protos(){
    if [[ ${#BUILD_LIST[@]} -eq 0 ]]; then
        log ERROR "No valid proto modules found to compile"
        log WARN "TIPS: Check your proto_build.conf or repository structure"
        exit 3
    fi

    log INFO "=== STARTING PROTO COMPILATION ==="
    local total=0
    for target in "${!BUILD_LIST[@]}"; do
        ((total++))
        IFS='/' read -r version service <<< "$target"
        log INFO "(${total}/${#BUILD_LIST[@]}) Compiling ${version}/${service}"

        # 创建服务输出目录（按需可选）
        service_output_dir="${OUTPUT_DIR}/${version}/${service}"
        mkdir -p "${service_output_dir}"

        # 编译proto文件
        protoc \
            --proto_path="${PROTOBUF_DIR}" \
            --go_out="${OUTPUT_DIR}" \
            --go_opt=paths=source_relative \
            --go-grpc_out="${OUTPUT_DIR}" \
            --go-grpc_opt=paths=source_relative \
            --validate_out="lang=go:${OUTPUT_DIR}" \
            --validate_opt=paths=source_relative \
            -I="${PROTOBUF_DIR}" \
            "${PROTOBUF_DIR}/${version}/${service}/*.proto" 2>&1 | while read -r line; do
            log DEBUG "protoc: $line"
        done

        # 增加编译结果校验
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            log DEBUG "Successfully compiled ${version}/${service}"
        else
            log ERROR "Failed to compile ${version}/${service}"
            exit 4
        fi
    done
    log INFO "=== COMPILED ${total} MODULES ==="
}

# 执行解析
init
parse_config
generate_build_list
compile_protos