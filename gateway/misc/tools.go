package misc

import (
	"sync"

	"github.com/gin-gonic/gin"
)

func ConcurrentExecution(tasks []func() map[string]string) map[string]string {
	var wg sync.WaitGroup
	resultChannel := make(chan map[string]string, len(tasks))
	finalResults := make(map[string]string)

	for _, task := range tasks {
		wg.Add(1)
		go func(task func() map[string]string) {
			defer wg.Done()
			resultChannel <- task()
		}(task)
	}

	go func() {
		wg.Wait()
		close(resultChannel)
	}()

	for res := range resultChannel {
		for k, v := range res {
			finalResults[k] = v
		}
	}

	return finalResults
}

func GinErrWrapper(c *gin.Context, err error) {
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
	} else {
		c.JSON(200, gin.H{"status": "ok"})
	}
}
