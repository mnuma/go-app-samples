package main

import (
	"github.com/mnuma/go-app-samples/logging"
)

func init() {
	logging.Setup()
}

func main() {
	logging.App.Infof("%s", "sample info log")
	logging.AppWithField().Infof("%s", "sample info log with file info")
}
