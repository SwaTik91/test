package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"image"
	"image/color"
	"math"
)

func EncodeSPR(frames []*image.NRGBA) ([]byte, error) {
	if len(frames) == 0 {
		return nil, fmt.Errorf("no frames")
	}
	var buf bytes.Buffer
	buf.WriteString("SP")
	buf.WriteByte(1) // minor
	buf.WriteByte(2) // major 2.1
	writeU16(&buf, 0)
	writeU16(&buf, uint16(len(frames)))
	for i, img := range frames {
		if img == nil {
			return nil, fmt.Errorf("frame %d is nil", i)
		}
		w, h := img.Bounds().Dx(), img.Bounds().Dy()
		writeU16(&buf, uint16(w))
		writeU16(&buf, uint16(h))
		for y := 0; y < h; y++ {
			srcY := h - 1 - y
			for x := 0; x < w; x++ {
				c := img.NRGBAAt(img.Bounds().Min.X+x, img.Bounds().Min.Y+srcY)
				if c.A == 0 {
					c = color.NRGBA{}
				}
				buf.WriteByte(c.A)
				buf.WriteByte(c.B)
				buf.WriteByte(c.G)
				buf.WriteByte(c.R)
			}
		}
	}
	buf.Write(make([]byte, 1024))
	return buf.Bytes(), nil
}

func EncodeACT(act ACT) ([]byte, error) {
	if act.VersionMajor == 0 {
		act.VersionMajor = 2
		act.VersionMinor = 5
	}
	var buf bytes.Buffer
	buf.WriteString("AC")
	buf.WriteByte(byte(act.VersionMinor))
	buf.WriteByte(byte(act.VersionMajor))
	writeU16(&buf, uint16(len(act.Actions)))
	buf.Write(make([]byte, 10))
	for _, action := range act.Actions {
		writeU32(&buf, uint32(len(action.Animations)))
		for _, anim := range action.Animations {
			buf.Write(make([]byte, 32))
			writeU32(&buf, uint32(len(anim.Layers)))
			for _, layer := range anim.Layers {
				writeI32(&buf, layer.X)
				writeI32(&buf, layer.Y)
				writeI32(&buf, layer.Index)
				if layer.Mirror {
					writeI32(&buf, 1)
				} else {
					writeI32(&buf, 0)
				}
				writeColor(&buf, layer.Color)
				writeF32(&buf, nzScale(layer.ScaleX))
				writeF32(&buf, nzScale(layer.ScaleY))
				writeI32(&buf, layer.Angle)
				writeI32(&buf, layer.SPRType)
				writeI32(&buf, layer.Width)
				writeI32(&buf, layer.Height)
			}
			writeI32(&buf, int32(anim.Sound))
			writeI32(&buf, int32(len(anim.Pos)))
			for _, pos := range anim.Pos {
				writeI32(&buf, 0)
				writeI32(&buf, pos.X)
				writeI32(&buf, pos.Y)
				writeI32(&buf, pos.Attr)
			}
		}
	}
	writeI32(&buf, int32(len(act.Sounds)))
	for _, sound := range act.Sounds {
		raw := make([]byte, 40)
		copy(raw, sound)
		buf.Write(raw)
	}
	for _, action := range act.Actions {
		delay := action.DelayMS
		if delay <= 0 {
			delay = 150
		}
		writeF32(&buf, delay/25)
	}
	return buf.Bytes(), nil
}

func nzScale(v float32) float32 {
	if v == 0 {
		return 1
	}
	return v
}

func writeColor(buf *bytes.Buffer, c [4]float32) {
	for i := 0; i < 4; i++ {
		v := c[i]
		if v == 0 && i < 3 {
			v = 1
		}
		if c[0] == 0 && c[1] == 0 && c[2] == 0 && c[3] == 0 {
			v = 1
		}
		buf.WriteByte(byte(clamp01(v) * 255))
	}
}

func clamp01(v float32) float32 {
	if v < 0 {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

func writeU16(buf *bytes.Buffer, v uint16) {
	var tmp [2]byte
	binary.LittleEndian.PutUint16(tmp[:], v)
	buf.Write(tmp[:])
}

func writeU32(buf *bytes.Buffer, v uint32) {
	var tmp [4]byte
	binary.LittleEndian.PutUint32(tmp[:], v)
	buf.Write(tmp[:])
}

func writeI32(buf *bytes.Buffer, v int32) { writeU32(buf, uint32(v)) }

func writeF32(buf *bytes.Buffer, v float32) {
	writeU32(buf, math.Float32bits(v))
}
