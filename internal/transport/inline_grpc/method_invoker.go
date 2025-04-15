package inline_grpc

import (
	"context"
	"fmt"
	"reflect"
	"sync"

	"google.golang.org/protobuf/proto"
)

// GrpcMethodInvoker 用于缓存和获取方法
type GrpcMethodInvoker struct {
	obj           interface{}              // 被调用的目标对象
	cachedMethods map[string]reflect.Value // 缓存的方法映射
	mu            sync.RWMutex             // 读写锁，保证并发安全
	messageCache  sync.Map
	bufferPool    sync.Pool
}

// NewGrpcMethodInvoker 创建并初始化 GrpcMethodInvoker
func NewGrpcMethodInvoker(obj interface{}) *GrpcMethodInvoker {
	return &GrpcMethodInvoker{
		obj:           obj,
		cachedMethods: make(map[string]reflect.Value),
		messageCache:  sync.Map{},
		bufferPool: sync.Pool{ // 对字节切片进行内存池优化，减少 GC 压力
			New: func() interface{} {
				return make([]byte, 0, 1024) // 初始化一个容量为1024字节的切片
			},
		},
	}
}

// getMethod 获取指定方法名的方法，若缓存中已有则直接返回，否则从对象中反射获取并缓存
func (gmi *GrpcMethodInvoker) getMethod(methodName string) (reflect.Value, error) {
	gmi.mu.RLock() // 获取读锁，避免多线程争抢
	method, exists := gmi.cachedMethods[methodName]
	gmi.mu.RUnlock()
	if exists {
		return method, nil
	}

	// 如果缓存中没有，从对象中反射获取方法
	objValue := reflect.ValueOf(gmi.obj)
	method = objValue.MethodByName(methodName)
	if !method.IsValid() {
		return reflect.Value{}, fmt.Errorf("method '%s' not found", methodName)
	}

	// 检查方法签名是否有效
	methodType := method.Type()
	if methodType.NumIn() != 2 || methodType.NumOut() != 2 {
		return reflect.Value{}, fmt.Errorf("method '%s' has an invalid signature", methodName)
	}

	// 方法通过检查，缓存起来以便下次使用
	gmi.mu.Lock() // 获取写锁
	gmi.cachedMethods[methodName] = method
	gmi.mu.Unlock()

	return method, nil
}

// InvokeMethod 调用指定方法，处理反射和方法调用
func (gmi *GrpcMethodInvoker) InvokeMethod(req GrpcRequest) (*GrpcResponse, error) {
	// 获取方法
	method, fetchErr := gmi.getMethod(req.MethodName)
	if fetchErr != nil {
		return nil, fetchErr
	}

	// 解码输入消息
	methodType := method.Type()
	inputMessage, decodeErr := gmi.decodeMessage(methodType.In(1), req.RequestBytes)
	if decodeErr != nil {
		return nil, decodeErr
	}
	// 调用方法
	results := method.Call([]reflect.Value{
		reflect.ValueOf(context.Background()),
		reflect.ValueOf(inputMessage),
	})

	// 处理返回值
	bytes, err := gmi.handleMethodResults(results, req.MethodName)
	if err != nil {
		return nil, err
	}
	return &GrpcResponse{
		ResponseBytes: bytes,
	}, nil
}

// handleMethodResults 处理方法的返回值，序列化返回的消息
func (gmi *GrpcMethodInvoker) handleMethodResults(results []reflect.Value, methodName string) ([]byte, error) {
	if len(results) != 2 {
		return nil, fmt.Errorf("method '%s' returned unexpected result count", methodName)
	}
	// 获取返回的消息和错误
	outputMessage, ok := results[0].Interface().(proto.Message)
	if !ok {
		return nil, fmt.Errorf("method '%s' returned invalid message type", methodName)
	}

	// 获取返回的错误值并检查类型
	errValue := results[1].Interface()
	if errValue != nil {
		if typedErr, ok := errValue.(error); ok {
			return nil, typedErr
		}
		return nil, fmt.Errorf("method '%s' returned invalid error type", methodName)
	}

	// 使用内存池管理字节缓冲区以避免频繁的内存分配
	buf := gmi.bufferPool.Get().([]byte)[:0]
	defer gmi.bufferPool.Put(buf) // 确保函数返回时将缓冲区归还到池中

	// 序列化返回消息
	outputBytes, err := proto.MarshalOptions{UseCachedSize: true}.MarshalAppend(buf, outputMessage)
	if err != nil {
		return nil, fmt.Errorf("failed to serialize output: %w", err)
	}

	return outputBytes, nil
}

// decodeMessage 解码输入的字节数组为相应的消息对象，并缓存解码后的结果
func (gmi *GrpcMethodInvoker) decodeMessage(messageType reflect.Type, input []byte) (proto.Message, error) {
	// 使用输入字节数组作为缓存键
	cacheKey := string(input)
	if cached, ok := gmi.messageCache.Load(cacheKey); ok {
		return cached.(proto.Message), nil
	}

	// 创建新的消息对象并进行解码
	message := reflect.New(messageType.Elem()).Interface().(proto.Message)
	if err := proto.Unmarshal(input, message); err != nil {
		return nil, fmt.Errorf("failed to parse input: %w", err)
	}

	// 缓存解码后的消息对象
	gmi.messageCache.Store(cacheKey, message)
	return message, nil
}
