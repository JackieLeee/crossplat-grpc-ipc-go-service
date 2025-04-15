package api

import (
	"context"
	"log"

	"ClientGrpcDemo/protocol/v1/greeter"
)

var GrpcServer = &server{}

type server struct {
	greeter.UnimplementedGreeterServer
}

func (s *server) SayHello(ctx context.Context, in *greeter.HelloRequest) (*greeter.HelloReply, error) {
	log.Printf("Received: %v", in.GetName())
	return &greeter.HelloReply{
		Message: "Message:" + in.GetName(),
		Data:    in.Data,
	}, nil
}
