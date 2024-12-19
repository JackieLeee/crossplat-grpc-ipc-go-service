package native_grpc

// GrpcRequest 包含所有需要传递给 gRPC 调用的信息。
type GrpcRequest struct {
	MethodName   string
	RequestBytes []byte
	OptionsJSON  string
	HeadersJSON  string
}

func (req GrpcRequest) Valid() string {
	if req.MethodName == "" {
		return "MethodName is empty"
	}
	return ""
}

// GrpcResponse 包含从 gRPC 调用返回的所有信息。
type GrpcResponse struct {
	ResponseBytes []byte
	StatusCode    int
	StatusMessage string
	TrailersJSON  string
}
