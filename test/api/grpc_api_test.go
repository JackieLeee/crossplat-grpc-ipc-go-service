package api

import (
	"encoding/json"
	"os"
	"testing"

	"google.golang.org/protobuf/proto"

	"ClientGrpcDemo/protocol/v1/greeter"
)

var (
	helloRequest = &greeter.HelloRequest{
		Name: "Jackie",
		Data: []*greeter.DataStruct{
			{
				Message: []string{
					"1", "9",
				},
			},
			{
				Message: []string{
					"abc", "DEF",
				},
			},
		},
	}
	jsonFileName = "helloRequest.json"
	pbFileName   = "helloRequest.pb"
)

func TestSerialization(t *testing.T) {
	// proto
	bytes, err := proto.Marshal(helloRequest)
	if err != nil {
		t.Fatal(err)
	}

	// 创建并存储到文件
	pbFile, err := os.Create(pbFileName)
	if err != nil {
		t.Fatal(err)
	}
	defer pbFile.Close()
	if _, err := pbFile.Write(bytes); err != nil {
		t.Fatal(err)
	}

	// json
	bytes, err = json.Marshal(helloRequest)
	if err != nil {
		t.Fatal(err)
	}
	// 创建并存储到文件
	jsonFile, err := os.Create(jsonFileName)
	if err != nil {
		t.Fatal(err)
	}
	defer jsonFile.Close()
	if _, err := jsonFile.Write(bytes); err != nil {
		t.Fatal(err)
	}
}

func TestPrintFileSize(t *testing.T) {
	// 输出两个文件的大小(字节)
	pbFileInfo, err := os.Stat(pbFileName)
	if err != nil {
		t.Fatal(err)
	}
	jsonFileInfo, err := os.Stat(jsonFileName)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Size of %s: %d bytes", pbFileName, pbFileInfo.Size())
	t.Logf("Size of %s: %d bytes", jsonFileName, jsonFileInfo.Size())
}

func TestProtobufDeserialization(t *testing.T) {
	file, err := os.Open("helloRequest.pb")
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()
	bytes, err := os.ReadFile("helloRequest.pb")
	if err != nil {
		t.Fatal(err)
	}
	var helloRequest2 = &greeter.HelloRequest{}
	err = proto.Unmarshal(bytes, helloRequest2)
	if err != nil {
		t.Fatal(err)
	}
	t.Log(proto.Equal(helloRequest2, helloRequest))
}
