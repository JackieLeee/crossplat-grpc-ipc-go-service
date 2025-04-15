package grpc

import (
	"sync"

	"ClientGrpcDemo/api"
	"ClientGrpcDemo/internal/transport/inline_grpc"

	_ "golang.org/x/mobile/bind"
)

// Request Mobile SDK request structure
type Request struct {
	MethodName   string
	RequestBytes []byte
	OptionsJSON  string
	HeadersJSON  string
}

// Response Mobile SDK response structure
type Response struct {
	ResponseBytes []byte
	StatusCode    int32
	StatusMessage string
	TrailersJSON  string
}

var (
	methodInvoker *inline_grpc.GrpcMethodInvoker
	once          sync.Once
)

func getMethodInvoker() *inline_grpc.GrpcMethodInvoker {
	once.Do(func() {
		methodInvoker = inline_grpc.NewGrpcMethodInvoker(api.GrpcServer)
	})
	return methodInvoker
}

// InvokeMethod A method that can be called by a mobile client and is responsible for handling gRPC requests
func InvokeMethod(req *Request) (*Response, error) {
	if req == nil {
		return nil, nil
	}

	// 转换为内部请求格式
	goReq := inline_grpc.GrpcRequest{
		MethodName:   req.MethodName,
		RequestBytes: req.RequestBytes,
		OptionsJSON:  req.OptionsJSON,
		HeadersJSON:  req.HeadersJSON,
	}

	if errMsg := goReq.Valid(); errMsg != "" {
		return &Response{
			StatusMessage: errMsg,
		}, nil
	}

	// Invoke business methods
	goResp, err := getMethodInvoker().InvokeMethod(goReq)
	if err != nil {
		return &Response{
			StatusMessage: err.Error(),
		}, nil
	}

	return &Response{
		ResponseBytes: goResp.ResponseBytes,
	}, nil
}
