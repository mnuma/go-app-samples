package logging

import (
	"github.com/Sirupsen/logrus"
	"github.com/lestrrat/go-file-rotatelogs"
	"path/filepath"
	"os"
	"log"
	"time"
	"io"
	"runtime"
	"fmt"
	"strconv"
)

var (
	// App is logger for app
	App *logrus.Logger
)

func Setup() {
	App = SetupAppLogger()
}

// SetupAppLogger returns api logger
func SetupAppLogger() *logrus.Logger {

	path, err := filepath.Abs("app.log.%Y%m%d")
	if err != nil {
		log.Fatalf("Log level error %v\n", err)
	}

	rl, err := rotatelogs.New(
		path,
		rotatelogs.WithMaxAge(86400 * time.Second),
		rotatelogs.WithRotationTime(86400 * time.Second),
		rotatelogs.WithLinkName("/tmp/app.log"),
	)
	if err != nil {
		log.Fatalf("Setup log rotate error. error %v\n", err)
	}

	out := io.MultiWriter(os.Stdout, rl)
	logger := logrus.Logger{
		Formatter: &logrus.JSONFormatter{},
		Level:     logrus.DebugLevel,
		Out:       out,
	}

	return &logger
}

// AppWithField returns log entry with custom field
func AppWithField() *logrus.Entry {
	_, file, line, ok := runtime.Caller(1)
	if !ok {
		file = ""
	}
	fileInfo := fmt.Sprintf("%s:%s", file, strconv.Itoa(line))
	return App.WithField("file", fileInfo)
}