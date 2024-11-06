package misc

import (
	"time"

	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

type Rule struct {
	DeviceID  string
	Condition string
	Action    string
}

func (r Rule) String() string {
	return r.DeviceID + ":" + r.Condition + ":" + r.Action
}

func (r Rule) Match(condition string) bool {
	if r.Condition == condition {
		return true
	}
	return false
}

type Rules []Rule

// v0.1.0 only support time condition
func (r Rules) Match(condition string) Rules {
	res := Rules{}
	for _, rule := range r {
		if rule.Match(condition) {
			res = append(res, rule)
		}
	}
	return res
}

// entry point of automation
func RunAutomation(db *gorm.DB, conns map[string]*websocket.Conn) {
	for range time.Tick(1 * time.Minute) {
		rules := new(Rules)
		db.Find(rules)
		for _, rule := range rules.Match(time.Now().String()) {
			RunAction(rule.DeviceID, rule.Action, db, conns[rule.DeviceID])
		}
	}
}
