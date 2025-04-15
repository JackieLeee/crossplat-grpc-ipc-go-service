package main

/*
typedef struct {
    const char* method_name;
    const unsigned char* request_bytes;
    size_t request_len;
    const char* options_json;
    const char* headers_json;
} GrpcRequest;

typedef struct {
    unsigned char* response_bytes;
    size_t response_len;
    int status_code;
    char* status_message;
    char* trailers_json;
} GrpcResponse;
*/
import "C"
import (
	"sync"
	"unsafe"

	"ClientGrpcDemo/api"
	"ClientGrpcDemo/internal/transport/inline_grpc"
)

func main() {}

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

// InvokeMethod 供C语言调用的函数，负责预处理参数、调用业务方法、返回结果
//
//export invokeMethod
func invokeMethod(req C.GrpcRequest, resp *C.GrpcResponse) {
	// 将 C struct 转换为 Go struct
	goReq := inline_grpc.GrpcRequest{
		MethodName:   C.GoString(req.method_name),
		RequestBytes: C.GoBytes(unsafe.Pointer(req.request_bytes), C.int(req.request_len)),
		OptionsJSON:  C.GoString(req.options_json),
		HeadersJSON:  C.GoString(req.headers_json),
	}
	if errMsg := goReq.Valid(); errMsg != "" {
		resp.status_message = C.CString(errMsg)
		return
	}

	// 调用业务方法
	goResp, err := getMethodInvoker().InvokeMethod(goReq)
	if err != nil {
		resp.status_message = C.CString(err.Error()) // 返回调用错误信息
		return
	}
	resp.response_bytes = (*C.uchar)(unsafe.Pointer(C.CBytes(goResp.ResponseBytes)))
	resp.response_len = C.size_t(len(goResp.ResponseBytes))
	return
}
