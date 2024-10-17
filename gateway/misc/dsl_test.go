package misc_test

import (
	"gateway/misc"
	"log"
	"os"
	"testing"
)

func TestDSLParser(t *testing.T) {
	dslExamples := []string{
		"ping",
		"status:200",
		"data.temperature[50]:12.3",
		"data.status:online",
		"114514.1919[810]:\"ok///sdfasd;flmas;ldfa;\"",
	}
	logFile := "dsl_test.log"
	file, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		log.Fatal(err)
	}
	logger := log.New(file, "", log.LstdFlags)
	for _, dsl := range dslExamples {
		msg, err := misc.ParseDSL(dsl)
		if err != nil {
			logger.Println("Error:", err)
		}
		logger.Printf("Parsed Message: %+v\n", msg)
	}
}
