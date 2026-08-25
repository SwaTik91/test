package main

import "image"

const (
	SPRFramePalette = 0
	SPRFrameRGBA    = 1
)

type SPR struct {
	VersionMajor int
	VersionMinor int
	IndexedCount int
	RGBACount    int
	RGBAIndex    int
	Frames       []SPRFrame
}

type SPRFrame struct {
	Type   int
	Width  int
	Height int
	Data   []byte
}

type ACT struct {
	VersionMajor int
	VersionMinor int
	Actions      []ACTAction
	Sounds       []string
}

type ACTAction struct {
	Animations []ACTAnimation
	DelayMS    float32
}

type ACTAnimation struct {
	Layers []ACTLayer
	Sound  int
	Pos    []ACTPosition
}

type ACTLayer struct {
	X       int32
	Y       int32
	Index   int32
	Mirror  bool
	ScaleX  float32
	ScaleY  float32
	Color   [4]float32
	Angle   int32
	SPRType int32
	Width   int32
	Height  int32
}

type ACTPosition struct {
	X    int32
	Y    int32
	Attr int32
}

func (s *SPR) versionAtLeast(major, minor int) bool {
	return s.VersionMajor > major || (s.VersionMajor == major && s.VersionMinor >= minor)
}

func (a *ACT) versionAtLeast(major, minor int) bool {
	return a.VersionMajor > major || (a.VersionMajor == major && a.VersionMinor >= minor)
}

func (s *SPR) FrameImage(index int, sprType int) (*image.NRGBA, bool) {
	if sprType == SPRFrameRGBA {
		index += s.RGBAIndex
	}
	if index < 0 || index >= len(s.Frames) {
		return nil, false
	}
	frame := s.Frames[index]
	if frame.Width <= 0 || frame.Height <= 0 {
		return nil, false
	}
	out := image.NewNRGBA(image.Rect(0, 0, frame.Width, frame.Height))
	if frame.Type != SPRFrameRGBA {
		return nil, false
	}
	for y := 0; y < frame.Height; y++ {
		srcRow := y * frame.Width * 4
		dstRow := (frame.Height - y - 1) * out.Stride
		for x := 0; x < frame.Width; x++ {
			src := srcRow + x*4
			dst := dstRow + x*4
			out.Pix[dst+0] = frame.Data[src+3]
			out.Pix[dst+1] = frame.Data[src+2]
			out.Pix[dst+2] = frame.Data[src+1]
			out.Pix[dst+3] = frame.Data[src+0]
			if out.Pix[dst+3] == 0 {
				out.Pix[dst+0] = 0
				out.Pix[dst+1] = 0
				out.Pix[dst+2] = 0
			}
		}
	}
	return out, true
}
