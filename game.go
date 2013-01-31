package pingpong

import (
	"bitbucket.org/emicklei/firespark"
	"encoding/json"
	"time"
	"math/rand"
)

type Message struct {
	Timestamp int64
	Action    string
	Source    string
	Parameter string
}

type Game struct {
	firespark.TwoPlayerGame
}

func (g *Game) PlayerSentMessage(encodedMsg string, player *firespark.Player) {
	msg := firespark.Message{}
	if err := json.Unmarshal([]byte(encodedMsg), &msg); err != nil {
		firespark.Printf("[pingpong] invalid json:%v", err)
		return
	}
	g.passItOn(msg.Source, encodedMsg)
}

func (g *Game) Start() {
	g.Started = time.Now()
	random := rand.Intn(2)
	start := firespark.MessageForGameStart(g.Name())
	startWithServe := Message{Timestamp:start.Timestamp, 
		Action:start.Action, 
		Source:start.Source,
		Parameter: "Serve"}
	if random == 0 {
		firespark.Printf("[pingpong] player 1 may serve")
		firespark.Send(g.One.Connection,startWithServe)
		firespark.Send(g.Two.Connection,start)
	} else {
		firespark.Printf("[pingpong] player 2 may serve")
		firespark.Send(g.Two.Connection,startWithServe)
		firespark.Send(g.One.Connection,start)	
	}
}

func (g Game) passItOn(from, encodedMsg string) {
	if !g.IsReady() {
		firespark.Printf("[pingpong] not ready (missing player or empty id)")
		return
	}
	if from == g.One.Id {
		// one -> two
		firespark.Send(g.Two.Connection, encodedMsg)
	}
	if from == g.Two.Id {
		// two -> one
		firespark.Send(g.One.Connection, encodedMsg)
	}
}
