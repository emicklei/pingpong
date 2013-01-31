package pingpong

import (
	fs "bitbucket.org/emicklei/firespark"
	"testing"
)

var balls = []ball{
	ball{0, 0, 1, 1}, ball{0, 0, 1, 1},
	ball{2, 4, 1, 1}, ball{3, 5, 1, 1},
	ball{13, 25, 1, 1}, ball{13, 25, 1, 1},
	ball{10, 10, 10, 0}, ball{4, 10, -10, 0},
	ball{10, 20, 0, 10}, ball{10, 18, 0, -10},
}

func TestMove(t *testing.T) {
	bounds := fs.Rectangle{2, 4, 10, 20}
	for i := 0; i < len(balls)-1; i += 2 {
		actual := balls[i]
		if actual.isInside(bounds) {
			actual.moveIn(bounds)
		}
		assertBall(actual, balls[i+1], t)
	}
}

func assertBall(this ball, that ball, t *testing.T) {
	if !this.equals(that) {
		t.Fatalf("expected:%#v actual:%#v", that, this)
	}
}
