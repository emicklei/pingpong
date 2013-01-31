package pingpong

import (
	"encoding/json"
	"testing"
)

type Message struct {
	Timestamp int64
	Action    string
	Source    string
	RacketY   float64
	BallX     float64
	BallY     float64
}

func TestMessage(t *testing.T) {
	m := Message{Timestamp: 1, Source: "source", Action: "action", RacketY: 3.14, BallX: 6.18, BallY: -12}
	json, _ := json.Marshal(m)
	t.Log(string(json))
}
