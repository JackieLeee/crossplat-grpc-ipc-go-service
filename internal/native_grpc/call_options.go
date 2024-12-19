package native_grpc

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

// CallOptions grpc调用选项
type CallOptions struct {
	Deadline               string
	Authority              string
	CallCredentials        string
	Executor               string
	CompressorName         string
	CustomOptions          []string
	WaitForReady           bool
	MaxInboundMessageSize  int
	MaxOutboundMessageSize int
	OnReadyThreshold       int
	StreamTracerFactories  string
}

// CallOptions 解析grpc callOptions
func parseCallOptions(callOptionsStr string) (CallOptions, error) {
	var options CallOptions

	// 使用正则表达式匹配键值对
	re := regexp.MustCompile(`(\w+)=(.*?)(?:,\s|\)|$)`)

	// 遍历所有匹配项
	matches := re.FindAllStringSubmatch(callOptionsStr, -1)
	for _, match := range matches {
		if len(match) < 3 {
			continue // 跳过不完整的匹配
		}
		key := strings.TrimSpace(match[1])
		value := strings.TrimSpace(match[2])

		switch key {
		case "deadline":
			options.Deadline = value
		case "authority":
			options.Authority = value
		case "callCredentials":
			options.CallCredentials = value
		case "executor":
			options.Executor = value
		case "compressorName":
			options.CompressorName = value
		case "customOptions":
			// 假设 customOptions 是一个逗号分隔的字符串列表
			if value != "<null>" && value != "[]" {
				options.CustomOptions = strings.Split(value[1:len(value)-1], ", ")
			}
		case "waitForReady":
			options.WaitForReady = value == "true"
		case "maxInboundMessageSize":
			maxInbound, err := strconv.Atoi(strings.ReplaceAll(value, " ", ""))
			if err != nil {
				return options, fmt.Errorf("invalid maxInboundMessageSize: %v", err)
			}
			options.MaxInboundMessageSize = maxInbound
		case "maxOutboundMessageSize":
			maxOutbound, err := strconv.Atoi(strings.ReplaceAll(value, " ", ""))
			if err != nil {
				return options, fmt.Errorf("invalid maxOutboundMessageSize: %v", err)
			}
			options.MaxOutboundMessageSize = maxOutbound
		case "onReadyThreshold":
			onReady, err := strconv.Atoi(strings.ReplaceAll(value, " ", ""))
			if err != nil {
				return options, fmt.Errorf("invalid onReadyThreshold: %v", err)
			}
			options.OnReadyThreshold = onReady
		case "streamTracerFactories":
			options.StreamTracerFactories = value
		default:
			fmt.Printf("Unknown key: %s\n", key)
		}
	}

	return options, nil
}
