package main

import (
	"image"
	"image/color"
	"testing"
)

func TestRemoveStudioWhiteKeepsPinkCore(t *testing.T) {
	img := image.NewNRGBA(image.Rect(0, 0, 5, 5))
	white := color.NRGBA{R: 255, G: 255, B: 255, A: 255}
	pink := color.NRGBA{R: 255, G: 120, B: 170, A: 255}
	for y := 0; y < 5; y++ {
		for x := 0; x < 5; x++ {
			img.SetNRGBA(x, y, white)
		}
	}
	img.SetNRGBA(2, 2, pink)
	got := removeStudioWhite(img)
	if got.NRGBAAt(0, 0).A != 0 {
		t.Fatal("edge white should be removed")
	}
	if c := got.NRGBAAt(2, 2); c.R != 255 || c.A != 255 {
		t.Fatalf("pink core = %+v", c)
	}
}

func TestFitOnCanvasPlacesBodyAboveBottomPad(t *testing.T) {
	src := image.NewNRGBA(image.Rect(0, 0, 20, 20))
	for y := 4; y < 16; y++ {
		for x := 4; x < 16; x++ {
			src.SetNRGBA(x, y, color.NRGBA{R: 200, G: 40, B: 80, A: 255})
		}
	}
	got := fitOnCanvas(src, 32, 4)
	if got.Bounds().Dx() != 32 {
		t.Fatalf("canvas %d", got.Bounds().Dx())
	}
	bottom := 0
	for y := 0; y < 32; y++ {
		for x := 0; x < 32; x++ {
			if got.NRGBAAt(x, y).A > 0 && y > bottom {
				bottom = y
			}
		}
	}
	if bottom < 26 || bottom > 28 {
		t.Fatalf("content bottom=%d, want near 27", bottom)
	}
}
