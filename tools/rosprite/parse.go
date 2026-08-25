package main

import (
	"encoding/binary"
	"fmt"
	"math"
)

func ParseSPR(data []byte) (*SPR, error) {
	r := binReader{data: data}
	if string(r.bytes(2)) != "SP" {
		return nil, fmt.Errorf("spr invalid header")
	}
	spr := &SPR{VersionMinor: int(r.u8()), VersionMajor: int(r.u8())}
	spr.IndexedCount = int(r.u16())
	if spr.versionAtLeast(1, 2) {
		spr.RGBACount = int(r.u16())
	}
	spr.RGBAIndex = spr.IndexedCount
	spr.Frames = make([]SPRFrame, spr.IndexedCount+spr.RGBACount)
	for i := 0; i < spr.RGBACount; i++ {
		width := int(r.i16())
		height := int(r.i16())
		pixels := r.bytes(width * height * 4)
		if r.err != nil {
			return nil, r.err
		}
		spr.Frames[spr.RGBAIndex+i] = SPRFrame{
			Type: SPRFrameRGBA, Width: width, Height: height,
			Data: append([]byte(nil), pixels...),
		}
	}
	if r.err != nil {
		return nil, r.err
	}
	return spr, nil
}

func ParseACT(data []byte) (*ACT, error) {
	r := binReader{data: data}
	if string(r.bytes(2)) != "AC" {
		return nil, fmt.Errorf("act invalid header")
	}
	act := &ACT{VersionMinor: int(r.u8()), VersionMajor: int(r.u8())}
	actionCount := int(r.u16())
	r.skip(10)
	act.Actions = make([]ACTAction, actionCount)
	for i := range act.Actions {
		anims, err := readACTAnimations(&r, act)
		if err != nil {
			return nil, err
		}
		act.Actions[i] = ACTAction{Animations: anims, DelayMS: 150}
	}
	if act.versionAtLeast(2, 1) {
		soundCount := int(r.i32())
		act.Sounds = make([]string, soundCount)
		for i := range act.Sounds {
			act.Sounds[i] = string(r.bytes(40))
		}
		if act.versionAtLeast(2, 2) {
			for i := range act.Actions {
				act.Actions[i].DelayMS = r.f32() * 25
			}
		}
	}
	if r.err != nil {
		return nil, r.err
	}
	return act, nil
}

func readACTAnimations(r *binReader, act *ACT) ([]ACTAnimation, error) {
	count := int(r.u32())
	anims := make([]ACTAnimation, count)
	for i := range anims {
		r.skip(32)
		anim, err := readACTLayers(r, act)
		if err != nil {
			return nil, err
		}
		anims[i] = anim
	}
	return anims, r.err
}

func readACTLayers(r *binReader, act *ACT) (ACTAnimation, error) {
	count := int(r.u32())
	anim := ACTAnimation{Layers: make([]ACTLayer, count), Sound: -1}
	for i := range anim.Layers {
		layer := ACTLayer{
			X: r.i32(), Y: r.i32(), Index: r.i32(), Mirror: r.i32() != 0,
			ScaleX: 1, ScaleY: 1, Color: [4]float32{1, 1, 1, 1},
		}
		if act.versionAtLeast(2, 0) {
			layer.Color[0] = float32(r.u8()) / 255
			layer.Color[1] = float32(r.u8()) / 255
			layer.Color[2] = float32(r.u8()) / 255
			layer.Color[3] = float32(r.u8()) / 255
			layer.ScaleX = r.f32()
			if act.versionAtLeast(2, 4) {
				layer.ScaleY = r.f32()
			} else {
				layer.ScaleY = layer.ScaleX
			}
			layer.Angle = r.i32()
			layer.SPRType = r.i32()
			if act.versionAtLeast(2, 5) {
				layer.Width = r.i32()
				layer.Height = r.i32()
			}
		}
		anim.Layers[i] = layer
	}
	if act.versionAtLeast(2, 0) {
		anim.Sound = int(r.i32())
	}
	if act.versionAtLeast(2, 3) {
		n := int(r.i32())
		anim.Pos = make([]ACTPosition, n)
		for i := range anim.Pos {
			r.skip(4)
			anim.Pos[i] = ACTPosition{X: r.i32(), Y: r.i32(), Attr: r.i32()}
		}
	}
	return anim, r.err
}

type binReader struct {
	data   []byte
	offset int
	err    error
}

func (r *binReader) bytes(n int) []byte {
	if r.err != nil {
		return nil
	}
	if n < 0 || r.offset+n > len(r.data) {
		r.err = fmt.Errorf("truncated at %d reading %d", r.offset, n)
		return nil
	}
	out := r.data[r.offset : r.offset+n]
	r.offset += n
	return out
}

func (r *binReader) skip(n int) { _ = r.bytes(n) }

func (r *binReader) u8() byte {
	b := r.bytes(1)
	if r.err != nil {
		return 0
	}
	return b[0]
}

func (r *binReader) u16() uint16 {
	b := r.bytes(2)
	if r.err != nil {
		return 0
	}
	return binary.LittleEndian.Uint16(b)
}

func (r *binReader) u32() uint32 {
	b := r.bytes(4)
	if r.err != nil {
		return 0
	}
	return binary.LittleEndian.Uint32(b)
}

func (r *binReader) i16() int16 { return int16(r.u16()) }
func (r *binReader) i32() int32 { return int32(r.u32()) }

func (r *binReader) f32() float32 {
	b := r.bytes(4)
	if r.err != nil {
		return 0
	}
	return math.Float32frombits(binary.LittleEndian.Uint32(b))
}
