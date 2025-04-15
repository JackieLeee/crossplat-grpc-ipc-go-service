package inline_grpc

import (
	"encoding/base64"
	"fmt"
	"strings"
)

// 解析Metadata字符串
func parseHeader(metadataStr string) (map[string]string, error) {
	// 预估映射大小以减少扩容次数
	pairCount := strings.Count(metadataStr, ",") + 1
	metadata := make(map[string]string, pairCount)

	// 去除开头和结尾的 "Metadata(" 和 ")"
	metadataStr = strings.TrimPrefix(metadataStr, "Metadata(")
	metadataStr = strings.TrimSuffix(metadataStr, ")")

	// 定义辅助函数用于解码Base64并存储结果
	decodeAndStore := func(key, value string) error {
		decoded, err := base64.StdEncoding.WithPadding(base64.NoPadding).DecodeString(value)
		if err != nil {
			return fmt.Errorf("failed to decode base64 value for key %s with value %s: %v", key, value, err)
		}
		metadata[key] = string(decoded)
		return nil
	}

	// 开始解析键值对
	for metadataStr != "" {
		// 找到下一个逗号或结束位置
		end := strings.IndexByte(metadataStr, ',')
		if end == -1 {
			end = len(metadataStr)
		}

		// 分割键和值
		kv := strings.SplitN(metadataStr[:end], "=", 2)
		if len(kv) != 2 {
			return nil, fmt.Errorf("invalid key-value pair: %s", metadataStr[:end])
		}
		key, value := kv[0], kv[1]

		// 检查是否是二进制数据并进行 Base64 解码
		if strings.HasSuffix(key, "-bin") {
			if err := decodeAndStore(key, value); err != nil {
				return nil, err
			}
		} else {
			metadata[key] = value
		}

		// 更新剩余字符串
		if end < len(metadataStr) {
			metadataStr = metadataStr[end+1:]
		} else {
			break
		}
	}

	return metadata, nil
}
