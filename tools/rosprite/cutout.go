package main

import (
	"image"
	"image/color"
	"image/png"
	"os"
)

func writePNG(path string, img *image.NRGBA) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return png.Encode(f, img)
}

func loadPNG(path string) (*image.NRGBA, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	img, err := png.Decode(f)
	if err != nil {
		return nil, err
	}
	return toNRGBA(img), nil
}

func toNRGBA(img image.Image) *image.NRGBA {
	if n, ok := img.(*image.NRGBA); ok {
		return n
	}
	b := img.Bounds()
	out := image.NewNRGBA(image.Rect(0, 0, b.Dx(), b.Dy()))
	for y := b.Min.Y; y < b.Max.Y; y++ {
		for x := b.Min.X; x < b.Max.X; x++ {
			out.Set(x-b.Min.X, y-b.Min.Y, img.At(x, y))
		}
	}
	return out
}

func removeStudioWhite(src *image.NRGBA) *image.NRGBA {
	b := src.Bounds()
	out := image.NewNRGBA(image.Rect(0, 0, b.Dx(), b.Dy()))
	copy(out.Pix, src.Pix)
	w, h := b.Dx(), b.Dy()
	visited := make([]bool, w*h)
	queue := make([]int, 0, w*h/4)
	push := func(x, y int) {
		if x < 0 || y < 0 || x >= w || y >= h {
			return
		}
		i := y*w + x
		if visited[i] {
			return
		}
		c := out.NRGBAAt(x, y)
		if !isStudioWhite(c) {
			return
		}
		visited[i] = true
		queue = append(queue, i)
	}
	for x := 0; x < w; x++ {
		push(x, 0)
		push(x, h-1)
	}
	for y := 0; y < h; y++ {
		push(0, y)
		push(w-1, y)
	}
	for len(queue) > 0 {
		i := queue[0]
		queue = queue[1:]
		x, y := i%w, i/w
		out.SetNRGBA(x, y, color.NRGBA{})
		push(x+1, y)
		push(x-1, y)
		push(x, y+1)
		push(x, y-1)
	}
	return out
}

func isStudioWhite(c color.NRGBA) bool {
	if c.A < 8 {
		return true
	}
	mx := max3(c.R, c.G, c.B)
	mn := min3(c.R, c.G, c.B)
	return mx >= 246 && mn >= 232 && (mx-mn) <= 20
}

func contentBounds(img *image.NRGBA) image.Rectangle {
	b := img.Bounds()
	minX, minY := b.Max.X, b.Max.Y
	maxX, maxY := b.Min.X, b.Min.Y
	for y := b.Min.Y; y < b.Max.Y; y++ {
		for x := b.Min.X; x < b.Max.X; x++ {
			if img.NRGBAAt(x, y).A < 16 {
				continue
			}
			if x < minX {
				minX = x
			}
			if y < minY {
				minY = y
			}
			if x >= maxX {
				maxX = x + 1
			}
			if y >= maxY {
				maxY = y + 1
			}
		}
	}
	if maxX <= minX || maxY <= minY {
		return image.Rect(0, 0, 1, 1)
	}
	return image.Rect(minX, minY, maxX, maxY)
}

func fitOnCanvas(src *image.NRGBA, canvas int, bottomPad int) *image.NRGBA {
	box := contentBounds(src)
	cw, ch := box.Dx(), box.Dy()
	maxBody := canvas - bottomPad - 8
	scale := 1.0
	if cw > maxBody || ch > maxBody {
		sx := float64(maxBody) / float64(cw)
		sy := float64(maxBody) / float64(ch)
		scale = sx
		if sy < sx {
			scale = sy
		}
	}
	dw := int(float64(cw)*scale + 0.5)
	dh := int(float64(ch)*scale + 0.5)
	if dw < 1 {
		dw = 1
	}
	if dh < 1 {
		dh = 1
	}
	out := image.NewNRGBA(image.Rect(0, 0, canvas, canvas))
	ox := (canvas - dw) / 2
	oy := canvas - bottomPad - dh
	if oy < 4 {
		oy = 4
	}
	for y := 0; y < dh; y++ {
		sy := box.Min.Y + int(float64(y)/scale)
		if sy >= box.Max.Y {
			sy = box.Max.Y - 1
		}
		for x := 0; x < dw; x++ {
			sx := box.Min.X + int(float64(x)/scale)
			if sx >= box.Max.X {
				sx = box.Max.X - 1
			}
			c := src.NRGBAAt(sx, sy)
			if c.A < 16 {
				continue
			}
			out.SetNRGBA(ox+x, oy+y, c)
		}
	}
	return out
}

func max3(a, b, c uint8) uint8 {
	if b > a {
		a = b
	}
	if c > a {
		a = c
	}
	return a
}

func min3(a, b, c uint8) uint8 {
	if b < a {
		a = b
	}
	if c < a {
		a = c
	}
	return a
}
