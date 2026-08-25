package main

import (
	"fmt"
	"os"
)

func main() {
	frameDir := "docs/ro-client-mockups/origin-poring/frames"
	outDir := "docs/ro-client-mockups/origin-poring"
	if len(os.Args) >= 3 {
		frameDir = os.Args[1]
		outDir = os.Args[2]
	}
	if err := buildPoringPack(frameDir, outDir); err != nil {
		fmt.Fprintf(os.Stderr, "rosprite: %v\n", err)
		os.Exit(1)
	}
}
