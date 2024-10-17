package misc

import (
	"fmt"
	"regexp"
	"strconv"
)

type Message struct {
	Type  string
	Key   string
	Limit int
	Value string
}

func ParseDSL(dsl string) (*Message, error) {
	re := regexp.MustCompile(`^(\w+)(?:\.(\w+))?(?:\[(\d+)\])?(?::(.+))?$`)
	matches := re.FindStringSubmatch(dsl)
	if matches == nil {
		return nil, fmt.Errorf("invalid DSL format")
	}

	typePart := matches[1]
	keyPart := matches[2]
	limit := 0
	if matches[3] != "" {
		limit, _ = strconv.Atoi(matches[3])
	}
	value := matches[4]

	return &Message{
		Type:  typePart,
		Key:   keyPart,
		Limit: limit,
		Value: value,
	}, nil
}
