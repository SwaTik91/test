package main

import (
	"image"
	"image/color"
	"testing"
)

func TestEncodeSPRRoundTripRGBA(t *testing.T) {
	img := image.NewNRGBA(image.Rect(0, 0, 2, 2))
	img.SetNRGBA(0, 0, color.NRGBA{R: 10, G: 20, B: 30, A: 128})
	img.SetNRGBA(1, 0, color.NRGBA{R: 255, G: 0, B: 128, A: 255})
	img.SetNRGBA(0, 1, color.NRGBA{A: 0})
	img.SetNRGBA(1, 1, color.NRGBA{R: 1, G: 2, B: 3, A: 4})

	data, err := EncodeSPR([]*image.NRGBA{img})
	if err != nil {
		t.Fatal(err)
	}
	spr, err := ParseSPR(data)
	if err != nil {
		t.Fatal(err)
	}
	if spr.IndexedCount != 0 || spr.RGBACount != 1 {
		t.Fatalf("counts indexed=%d rgba=%d", spr.IndexedCount, spr.RGBACount)
	}
	got, ok := spr.FrameImage(0, SPRFrameRGBA)
	if !ok {
		t.Fatal("missing frame")
	}
	assertPixel(t, got, 0, 0, 10, 20, 30, 128)
	assertPixel(t, got, 1, 0, 255, 0, 128, 255)
	assertPixel(t, got, 0, 1, 0, 0, 0, 0)
	assertPixel(t, got, 1, 1, 1, 2, 3, 4)
}

func TestEncodeACTRoundTrip(t *testing.T) {
	act := ACT{
		VersionMajor: 2,
		VersionMinor: 5,
		Actions: []ACTAction{{
			DelayMS: 150,
			Animations: []ACTAnimation{{
				Sound: -1,
				Layers: []ACTLayer{{
					X: 0, Y: -8, Index: 2, Mirror: true,
					ScaleX: 1, ScaleY: 1,
					Color:   [4]float32{1, 1, 1, 1},
					SPRType: SPRFrameRGBA,
					Width:   64,
					Height:  64,
				}},
			}},
		}},
	}
	data, err := EncodeACT(act)
	if err != nil {
		t.Fatal(err)
	}
	got, err := ParseACT(data)
	if err != nil {
		t.Fatal(err)
	}
	if len(got.Actions) != 1 {
		t.Fatalf("actions=%d", len(got.Actions))
	}
	layer := got.Actions[0].Animations[0].Layers[0]
	if layer.Index != 2 || !layer.Mirror || layer.SPRType != SPRFrameRGBA || layer.Y != -8 {
		t.Fatalf("layer %+v", layer)
	}
	if got.Actions[0].DelayMS < 149 || got.Actions[0].DelayMS > 151 {
		t.Fatalf("delay %f", got.Actions[0].DelayMS)
	}
}

func TestBuildPoringACTHasMonsterFamilies(t *testing.T) {
	frames := make([]*image.NRGBA, frameCount)
	tiny := image.NewNRGBA(image.Rect(0, 0, 8, 8))
	for i := range frames {
		frames[i] = tiny
	}
	act := buildPoringACT(frames)
	if len(act.Actions) != 40 {
		t.Fatalf("actions=%d, want 40", len(act.Actions))
	}
	if len(act.Actions[4*8].Animations) < 2 {
		t.Fatal("death should be animated")
	}
	if act.Actions[0].Animations[0].Layers[0].SPRType != SPRFrameRGBA {
		t.Fatal("idle should use RGBA")
	}
}

func assertPixel(t *testing.T, img *image.NRGBA, x, y int, r, g, b, a uint8) {
	t.Helper()
	got := img.NRGBAAt(x, y)
	if got.R != r || got.G != g || got.B != b || got.A != a {
		t.Fatalf("pixel %d,%d = %+v, want %d %d %d %d", x, y, got, r, g, b, a)
	}
}
