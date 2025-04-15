package main

import (
	"flag"
	"fmt"
	"log"
	"net"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"ClientGrpcDemo/api"
	"ClientGrpcDemo/protocol/v1/greeter"
)

func main() {
	// 通过命令行入参设定端口，默认端口9000，开启一个grpc服务器
	port := flag.Int("port", 9000, "gRPC server port")
	flag.Parse()

	// 初始化服务
	grpcServer := grpc.NewServer(
		grpc.MaxRecvMsgSize(1024*1024*16), // 16MB
		grpc.MaxSendMsgSize(1024*1024*16), // 16MB
	)

	// 注册服务
	greeter.RegisterGreeterServer(grpcServer, api.GrpcServer)

	// 确保反射服务正确注册
	log.Println("Registering reflection service...")
	reflection.Register(grpcServer)

	// 启动 gRPC 服务器
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	log.Printf("Starting gRPC server on port %d", *port)
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
