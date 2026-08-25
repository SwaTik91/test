package main

import (
	"fmt"
	"image"
	"os"
	"path/filepath"
)

const (
	frameIdleFront = 0
	frameIdle34    = 1
	frameIdleSide  = 2
	frameIdleBack  = 3
	frameWalk      = 4
	frameHurt      = 5
	frameDie       = 6
	frameCount     = 7
)

// dirFrame maps RO direction 0..7 to a source frame and optional mirror.
// 0 south, 1 SW, 2 west, 3 NW, 4 north, 5 NE, 6 east, 7 SE.
var dirFrame = []struct {
	idle   int32
	mirror bool
}{
	{frameIdleFront, false},
	{frameIdle34, false},
	{frameIdleSide, false},
	{frameIdleBack, false},
	{frameIdleBack, false},
	{frameIdle34, true},
	{frameIdleSide, true},
	{frameIdle34, true},
}

func buildPoringPack(frameDir, outDir string) error {
	names := []string{
		"origin-poring-idle.png",
		"origin-poring-idle-34.png",
		"origin-poring-idle-side.png",
		"origin-poring-idle-back.png",
		"origin-poring-walk.png",
		"origin-poring-hurt.png",
		"origin-poring-die.png",
	}
	frames := make([]*image.NRGBA, frameCount)
	for i, name := range names {
		img, err := loadPNG(filepath.Join(frameDir, name))
		if err != nil {
			return fmt.Errorf("%s: %w", name, err)
		}
		frames[i] = fitOnCanvas(removeStudioWhite(img), 128, 10)
	}
	spr, err := EncodeSPR(frames)
	if err != nil {
		return err
	}
	act, err := EncodeACT(buildPoringACT(frames))
	if err != nil {
		return err
	}
	monsterDir := filepath.Join(outDir, "data", "sprite", "monster")
	if err := os.MkdirAll(monsterDir, 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(monsterDir, "poring.spr"), spr, 0o644); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(monsterDir, "poring.act"), act, 0o644); err != nil {
		return err
	}
	previewDir := filepath.Join(outDir, "frames", "cutout")
	if err := os.MkdirAll(previewDir, 0o755); err != nil {
		return err
	}
	for i, img := range frames {
		if err := writePNG(filepath.Join(previewDir, fmt.Sprintf("%02d.png", i)), img); err != nil {
			return err
		}
	}
	return nil
}

func buildPoringACT(frames []*image.NRGBA) ACT {
	actions := make([]ACTAction, 40)
	for dir := 0; dir < 8; dir++ {
		d := dirFrame[dir]
		w, h := frameSize(frames, int(d.idle))
		walkW, walkH := frameSize(frames, frameWalk)
		hurtW, hurtH := frameSize(frames, frameHurt)
		dieW, dieH := frameSize(frames, frameDie)

		actions[0*8+dir] = ACTAction{DelayMS: 180, Animations: []ACTAnimation{
			rgbaLayer(d.idle, d.mirror, w, h, 0),
		}}
		actions[1*8+dir] = ACTAction{DelayMS: 120, Animations: []ACTAnimation{
			rgbaLayer(d.idle, d.mirror, w, h, 0),
			walkLayer(dir, d, walkW, walkH, w, h),
		}}
		actions[2*8+dir] = ACTAction{DelayMS: 90, Animations: []ACTAnimation{
			walkLayer(dir, d, walkW, walkH, w, h),
			rgbaLayer(d.idle, d.mirror, w, h, 0),
		}}
		actions[3*8+dir] = ACTAction{DelayMS: 80, Animations: []ACTAnimation{
			rgbaLayer(frameHurt, d.mirror, hurtW, hurtH, 0),
		}}
		actions[4*8+dir] = ACTAction{DelayMS: 140, Animations: []ACTAnimation{
			rgbaLayer(frameHurt, d.mirror, hurtW, hurtH, 0),
			rgbaLayer(frameDie, false, dieW, dieH, 4),
			rgbaLayer(frameDie, false, dieW, dieH, 4),
		}}
	}
	return ACT{VersionMajor: 2, VersionMinor: 5, Actions: actions}
}

func walkLayer(dir int, d struct {
	idle   int32
	mirror bool
}, walkW, walkH, idleW, idleH int32) ACTAnimation {
	if dir == 0 || dir == 1 || dir == 7 {
		return rgbaLayer(frameWalk, dir == 7, walkW, walkH, -6)
	}
	return rgbaLayerScaled(d.idle, d.mirror, idleW, idleH, 1.08, 0.88, 0)
}

func frameSize(frames []*image.NRGBA, index int) (int32, int32) {
	if index < 0 || index >= len(frames) || frames[index] == nil {
		return 128, 128
	}
	b := frames[index].Bounds()
	return int32(b.Dx()), int32(b.Dy())
}

func rgbaLayer(index int32, mirror bool, w, h, y int32) ACTAnimation {
	return rgbaLayerScaled(index, mirror, w, h, 1, 1, y)
}

func rgbaLayerScaled(index int32, mirror bool, w, h int32, sx, sy float32, y int32) ACTAnimation {
	return ACTAnimation{
		Sound: -1,
		Layers: []ACTLayer{{
			X: 0, Y: y + groundY(h), Index: index, Mirror: mirror,
			ScaleX: sx, ScaleY: sy,
			Color:   [4]float32{1, 1, 1, 1},
			SPRType: SPRFrameRGBA,
			Width:   w,
			Height:  h,
		}},
	}
}

func groundY(h int32) int32 {
	// Image is drawn centered; shift so the lower body sits on the actor origin.
	return -(h / 2) + 16
}
