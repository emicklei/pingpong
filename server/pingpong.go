package main

import (
	"bitbucket.org/emicklei/firespark"
	"bitbucket.org/emicklei/pingpong"
	"flag"
)

func main() {
	flag.Parse()
	firespark.Run(firespark.NewOrganizer(NewGame))
}

func NewGame(id string) firespark.Game { 
	pp := new(pingpong.Game)
	pp.SetName(id)
	return pp
}