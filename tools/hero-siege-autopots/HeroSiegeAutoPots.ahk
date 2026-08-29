#Requires AutoHotkey v2.0
#SingleInstance Force
#WinActivateForce
SetTitleMatchMode 2
SendMode "Event"
SetKeyDelay 15, 25
CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
CoordMode "ToolTip", "Screen"

; =============================================================================
;  Hero Siege — автопоты (AHK v2)
;
;  Скрипт смотрит цвет HP/MP-полосок и жмёт клавиши банок, пока открыто окно
;  Hero Siege. Координаты задаются калибровкой и хранятся как доли окна, поэтому
;  перенос на другое разрешение обычно не ломает работу.
;
;  F6        калибровка HP (навести курсор, НЕ кликать)
;  F7        калибровка MP (так же)
;  F8        вкл / выкл автопотов
;  F9        цвет и координаты под курсором
;  F10       настройки
;  F11       оверлей в другой угол (не перекрывает HP)
;  Shift+Esc выход
;
;  Калибруй на ПОЛНОМ HP (и MP). Банки в игре повесь на те же клавиши, что в
;  настройках скрипта (по умолчанию 1 = HP, 2 = MP).
; =============================================================================

DllCall("User32.dll\SetThreadDpiAwarenessContext", "ptr", -4)
Cfg.Load()
Overlay.Init()
TrayMenu.Init()
OnExit((*) => (DxgiGrab.Free(), Pix.PrintFree()))
if !DxgiGrab.Init()
    Overlay.ShowHint("DXGI не поднялся: " DxgiGrab.err "  (закрой OBS/Xbox Game Bar и перезапусти)")
SetTimer(() => AutoPots.Tick(), Cfg.tickMs)
TrayTip("Hero Siege AutoPots", "F8 — вкл/выкл   F6 — калибровка HP   F10 — настройки", "Iconi")

F6:: Calib.OnHp()
F7:: Calib.OnMp()
F8:: AutoPots.Toggle()
F9:: Probe.Show()
F10:: SettingsUi.Show()
F11:: Overlay.CycleCorner()
+Esc:: ExitApp()

; -----------------------------------------------------------------------------
;  Конфиг
; -----------------------------------------------------------------------------

class Cfg {
    static file := A_ScriptDir "\autopots.ini"
    static hpKeys := "1"
    static mpKeys := "2"
    static hpPct := 40
    static mpPct := 25
    static cdMs := 750
    static tickMs := 60
    static colorTol := 90
    static pixelMode := "Slow"
    static pixelMethod := "dxgi"
    static overlayCorner := "br"
    static calibratedHp := false
    static calibratedMp := false
    static hpX1 := 0.08, hpY1 := 0.055, hpX2 := 0.22, hpY2 := 0.055, hpFill := 0xC42B2B
    static mpX1 := 0.08, mpY1 := 0.078, mpX2 := 0.22, mpY2 := 0.078, mpFill := 0x2B6EC4

    static Load() {
        f := this.file
        this.hpKeys := IniRead(f, "general", "hpKeys", this.hpKeys)
        this.mpKeys := IniRead(f, "general", "mpKeys", this.mpKeys)
        this.hpPct := SafeInt(IniRead(f, "general", "hpPct", this.hpPct), this.hpPct)
        this.mpPct := SafeInt(IniRead(f, "general", "mpPct", this.mpPct), this.mpPct)
        this.cdMs := SafeInt(IniRead(f, "general", "cdMs", this.cdMs), this.cdMs)
        this.tickMs := SafeInt(IniRead(f, "general", "tickMs", this.tickMs), this.tickMs)
        this.colorTol := SafeInt(IniRead(f, "general", "colorTol", this.colorTol), this.colorTol)
        this.pixelMode := IniRead(f, "general", "pixelMode", this.pixelMode)
        this.pixelMethod := IniRead(f, "general", "pixelMethod", "dxgi")
        if IniRead(f, "general", "dxgiMigrated", "0") != "1" {
            this.pixelMethod := "dxgi"
            try {
                IniWrite("1", f, "general", "dxgiMigrated")
                IniWrite("dxgi", f, "general", "pixelMethod")
            }
        }
        this.overlayCorner := IniRead(f, "general", "overlayCorner", this.overlayCorner)
        this.calibratedHp := IniRead(f, "hp", "calibrated", "0") = "1"
        this.hpX1 := SafeFloat(IniRead(f, "hp", "x1", this.hpX1), this.hpX1)
        this.hpY1 := SafeFloat(IniRead(f, "hp", "y1", this.hpY1), this.hpY1)
        this.hpX2 := SafeFloat(IniRead(f, "hp", "x2", this.hpX2), this.hpX2)
        this.hpY2 := SafeFloat(IniRead(f, "hp", "y2", this.hpY2), this.hpY2)
        this.hpFill := SafeInt(IniRead(f, "hp", "fill", this.hpFill), this.hpFill)
        this.calibratedMp := IniRead(f, "mp", "calibrated", "0") = "1"
        this.mpX1 := SafeFloat(IniRead(f, "mp", "x1", this.mpX1), this.mpX1)
        this.mpY1 := SafeFloat(IniRead(f, "mp", "y1", this.mpY1), this.mpY1)
        this.mpX2 := SafeFloat(IniRead(f, "mp", "x2", this.mpX2), this.mpX2)
        this.mpY2 := SafeFloat(IniRead(f, "mp", "y2", this.mpY2), this.mpY2)
        this.mpFill := SafeInt(IniRead(f, "mp", "fill", this.mpFill), this.mpFill)
        if this.tickMs < 30
            this.tickMs := 30
        if this.cdMs < 200
            this.cdMs := 200
    }

    static Save() {
        f := this.file
        IniWrite(this.hpKeys, f, "general", "hpKeys")
        IniWrite(this.mpKeys, f, "general", "mpKeys")
        IniWrite(this.hpPct, f, "general", "hpPct")
        IniWrite(this.mpPct, f, "general", "mpPct")
        IniWrite(this.cdMs, f, "general", "cdMs")
        IniWrite(this.tickMs, f, "general", "tickMs")
        IniWrite(this.colorTol, f, "general", "colorTol")
        IniWrite(this.pixelMode, f, "general", "pixelMode")
        IniWrite(this.pixelMethod, f, "general", "pixelMethod")
        IniWrite(this.overlayCorner, f, "general", "overlayCorner")
        IniWrite(this.calibratedHp ? "1" : "0", f, "hp", "calibrated")
        IniWrite(Format("{:.5f}", this.hpX1), f, "hp", "x1")
        IniWrite(Format("{:.5f}", this.hpY1), f, "hp", "y1")
        IniWrite(Format("{:.5f}", this.hpX2), f, "hp", "x2")
        IniWrite(Format("{:.5f}", this.hpY2), f, "hp", "y2")
        IniWrite(Format("0x{:06X}", this.hpFill), f, "hp", "fill")
        IniWrite(this.calibratedMp ? "1" : "0", f, "mp", "calibrated")
        IniWrite(Format("{:.5f}", this.mpX1), f, "mp", "x1")
        IniWrite(Format("{:.5f}", this.mpY1), f, "mp", "y1")
        IniWrite(Format("{:.5f}", this.mpX2), f, "mp", "x2")
        IniWrite(Format("{:.5f}", this.mpY2), f, "mp", "y2")
        IniWrite(Format("0x{:06X}", this.mpFill), f, "mp", "fill")
    }
}

; -----------------------------------------------------------------------------
;  Окно игры
; -----------------------------------------------------------------------------

class Game {
    static IsActive() {
        return WinActive("Hero Siege")
            || WinActive("ahk_exe Hero_Siege.exe")
            || WinActive("ahk_exe HeroSiege.exe")
            || WinActive("ahk_exe hero_siege.exe")
    }

    static Exists() {
        return WinExist("Hero Siege")
            || WinExist("ahk_exe Hero_Siege.exe")
            || WinExist("ahk_exe HeroSiege.exe")
            || WinExist("ahk_exe hero_siege.exe")
    }

    static ClientSize(&w, &h) {
        WinGetClientPos(, , &w, &h, "A")
        if w < 1
            w := A_ScreenWidth
        if h < 1
            h := A_ScreenHeight
    }
}

; -----------------------------------------------------------------------------
;  Цвет
; -----------------------------------------------------------------------------

class Col {
    static R(c) => (c >> 16) & 0xFF
    static G(c) => (c >> 8) & 0xFF
    static B(c) => c & 0xFF
    static Hex(c) => Format("0x{:06X}", c)

    static Dist(a, b) {
        dr := this.R(a) - this.R(b)
        dg := this.G(a) - this.G(b)
        db := this.B(a) - this.B(b)
        return Sqrt(dr * dr + dg * dg + db * db)
    }

    static IsRed(c) {
        r := this.R(c), g := this.G(c), b := this.B(c)
        return r >= 88 && r > g + 22 && r > b + 22
    }

    static IsBlue(c) {
        r := this.R(c), g := this.G(c), b := this.B(c)
        return b >= 88 && b > r + 18 && b >= g - 12
    }

    ; Типичная заливка GDI-окна Hero Siege, когда кадр с GPU не читается.
    static IsDeadGdi(c) {
        return Col.Dist(c, 0x3F3949) <= 14 || Col.Dist(c, 0x000000) <= 2
    }
}

; -----------------------------------------------------------------------------
;  Пиксель: DirectX не рисует в DC окна, поэтому GetPixel по клиенту часто
;  возвращает одну и ту же заливку 0x3F3949. Читаем уже составленный рабочий стол.
; -----------------------------------------------------------------------------

class Pix {
    static printHdc := 0
    static printBmp := 0
    static printOld := 0
    static printTick := -1
    static printHwnd := 0

    static Get(cx, cy) {
        method := Cfg.pixelMethod
        if method = "dxgi" && !DxgiGrab.ready
            method := "screen"
        switch method {
            case "window": return this.AhkClient(cx, cy, "Slow")
            case "alt":    return this.AhkScreen(cx, cy, "Alt")
            case "slow":   return this.AhkScreen(cx, cy, "Slow")
            case "print":  return this.PrintGet(cx, cy)
            case "screen": return this.Screen(cx, cy)
            default:
                this.ToScreen(cx, cy, &sx, &sy)
                return DxgiGrab.Color(sx, sy)
        }
    }

    static FromColorRef(col) {
        if (col = 0xFFFFFFFF)
            return 0
        r := col & 0xFF
        g := (col >> 8) & 0xFF
        b := (col >> 16) & 0xFF
        return (r << 16) | (g << 8) | b
    }

    static ToScreen(cx, cy, &sx, &sy) {
        hwnd := WinExist("A")
        pt := Buffer(8)
        NumPut("int", Integer(cx), "int", Integer(cy), pt)
        DllCall("ClientToScreen", "ptr", hwnd, "ptr", pt)
        sx := NumGet(pt, 0, "int")
        sy := NumGet(pt, 4, "int")
    }

    static Screen(cx, cy) {
        this.ToScreen(cx, cy, &sx, &sy)
        hdc := DllCall("GetDC", "ptr", 0, "ptr")
        col := DllCall("GetPixel", "ptr", hdc, "int", sx, "int", sy, "uint")
        DllCall("ReleaseDC", "ptr", 0, "ptr", hdc)
        return this.FromColorRef(col)
    }

    static AtCursor() {
        pt := Buffer(8)
        DllCall("GetCursorPos", "ptr", pt)
        sx := NumGet(pt, 0, "int")
        sy := NumGet(pt, 4, "int")
        hdc := DllCall("GetDC", "ptr", 0, "ptr")
        col := DllCall("GetPixel", "ptr", hdc, "int", sx, "int", sy, "uint")
        DllCall("ReleaseDC", "ptr", 0, "ptr", hdc)
        return this.FromColorRef(col)
    }

    static AhkScreen(cx, cy, mode := "") {
        this.ToScreen(cx, cy, &sx, &sy)
        CoordMode("Pixel", "Screen")
        c := (mode = "") ? PixelGetColor(sx, sy) : PixelGetColor(sx, sy, mode)
        CoordMode("Pixel", "Client")
        return c
    }

    static AhkClient(cx, cy, mode := "Slow") {
        CoordMode("Pixel", "Client")
        return PixelGetColor(Integer(cx), Integer(cy), mode)
    }

    static PrintGet(cx, cy) {
        hwnd := WinExist("A")
        if this.printTick != A_TickCount || hwnd != this.printHwnd
            this.PrintGrab(hwnd)
        if !this.printHdc
            return 0
        col := DllCall("GetPixel", "ptr", this.printHdc, "int", Integer(cx), "int", Integer(cy), "uint")
        return this.FromColorRef(col)
    }

    static PrintGrab(hwnd) {
        this.PrintFree()
        this.printTick := A_TickCount
        this.printHwnd := hwnd
        WinGetClientPos(, , &w, &h, "ahk_id " hwnd)
        if w < 2 || h < 2
            return
        hdcScr := DllCall("GetDC", "ptr", 0, "ptr")
        this.printHdc := DllCall("CreateCompatibleDC", "ptr", hdcScr, "ptr")
        this.printBmp := DllCall("CreateCompatibleBitmap", "ptr", hdcScr, "int", w, "int", h, "ptr")
        this.printOld := DllCall("SelectObject", "ptr", this.printHdc, "ptr", this.printBmp, "ptr")
        DllCall("ReleaseDC", "ptr", 0, "ptr", hdcScr)
        ; 2 = PW_RENDERFULLCONTENT — иногда достаёт GPU-кадр
        DllCall("PrintWindow", "ptr", hwnd, "ptr", this.printHdc, "uint", 2)
    }

    static PrintFree() {
        if this.printHdc {
            if this.printOld
                DllCall("SelectObject", "ptr", this.printHdc, "ptr", this.printOld)
            if this.printBmp
                DllCall("DeleteObject", "ptr", this.printBmp)
            DllCall("DeleteDC", "ptr", this.printHdc)
        }
        this.printHdc := 0
        this.printBmp := 0
        this.printOld := 0
        this.printHwnd := 0
    }

    static DumpAtCursor() {
        hwnd := WinExist("A")
        pt := Buffer(8)
        DllCall("GetCursorPos", "ptr", pt)
        sx := NumGet(pt, 0, "int")
        sy := NumGet(pt, 4, "int")
        NumPut("int", sx, "int", sy, pt)
        DllCall("ScreenToClient", "ptr", hwnd, "ptr", pt)
        cx := NumGet(pt, 0, "int")
        cy := NumGet(pt, 4, "int")
        screen := this.Screen(cx, cy)
        alt := this.AhkScreen(cx, cy, "Alt")
        window := this.AhkClient(cx, cy, "Slow")
        print := this.PrintGet(cx, cy)
        dxgi := DxgiGrab.Color(sx, sy)
        return Map(
            "sx", sx, "sy", sy, "cx", cx, "cy", cy,
            "screen", screen, "alt", alt, "window", window, "print", print, "dxgi", dxgi
        )
    }
}

; -----------------------------------------------------------------------------
;  DXGI Desktop Duplication — единственный способ увидеть кадр DirectX-игры,
;  когда GDI отдаёт одну заливку 0x3F3949 (это не античит).
; -----------------------------------------------------------------------------

class DxgiGrab {
    static ready := false
    static err := ""
    static factory := 0, adapter := 0, output := 0, output1 := 0
    static device := 0, ctx := 0, dup := 0, staging := 0
    static outputLeft := 0, outputTop := 0, width := 0, height := 0
    static pitch := 0, bits := 0, mapped := false, inSysMem := false
    static frameRes := 0, lastGrab := -1

    static Init() {
        this.Free()
        try {
            this.InitRaw()
            this.ready := true
            this.err := ""
            Loop 20 {
                if this.Grab(100)
                    break
            }
            return true
        } catch as e {
            this.err := e.Message
            this.Free()
            return false
        }
    }

    static InitRaw() {
        if !DllCall("GetModuleHandle", "str", "DXGI")
            DllCall("LoadLibrary", "str", "DXGI")
        if !DllCall("GetModuleHandle", "str", "D3D11")
            DllCall("LoadLibrary", "str", "D3D11")
        DllCall("ole32\CLSIDFromString", "wstr", "{7b7166ec-21c7-44ae-b21a-c9ae321ae369}", "ptr", riid := Buffer(16), "HRESULT")
        try DllCall("DXGI\CreateDXGIFactory1", "ptr", riid, "ptr*", &factory := 0, "HRESULT")
        catch {
            DllCall("DXGI\CreateDXGIFactory", "ptr", riid, "ptr*", &factory := 0, "HRESULT")
        }
        this.factory := factory
        adapter := 0
        output := 0
        try ComCall(7, factory, "uint", 0, "ptr*", &adapter)
        catch as e
            throw Error("DXGI EnumAdapters: " e.Message)
        this.adapter := adapter
        try ComCall(7, adapter, "uint", 0, "ptr*", &output)
        catch as e
            throw Error("DXGI EnumOutputs: " e.Message)
        this.output := output
        this.ApplyMonitorOrigin()
        try DllCall("D3D11\D3D11CreateDevice"
            , "ptr", adapter
            , "int", 0
            , "ptr", 0
            , "uint", 0
            , "ptr", 0
            , "uint", 0
            , "uint", 7
            , "ptr*", &device := 0
            , "ptr*", 0
            , "ptr*", &ctx := 0
            , "HRESULT")
        catch {
            DllCall("D3D11\D3D11CreateDevice"
                , "ptr", 0
                , "int", 1
                , "ptr", 0
                , "uint", 0
                , "ptr", 0
                , "uint", 0
                , "uint", 7
                , "ptr*", &device := 0
                , "ptr*", 0
                , "ptr*", &ctx := 0
                , "HRESULT")
        }
        this.device := device
        this.ctx := ctx
        this.output1 := ComObjQuery(output, "{00cddea8-939b-4b83-a340-a685226666cc}")
        try ComCall(22, this.output1, "ptr", device, "ptr*", &dup := 0)
        catch as e
            throw Error("DuplicateOutput: " e.Message " — закрой OBS/Xbox Game Bar и перезапусти")
        this.dup := dup
        dupDesc := Buffer(36, 0)
        ComCall(7, dup, "ptr", dupDesc)
        this.inSysMem := NumGet(dupDesc, 32, "uint")
        dw := NumGet(dupDesc, 0, "uint")
        dh := NumGet(dupDesc, 4, "uint")
        if dw > 64 && dh > 64 {
            this.width := dw
            this.height := dh
        }
        if this.width < 64 || this.height < 64 {
            this.width := DllCall("GetSystemMetrics", "int", 0, "int")
            this.height := DllCall("GetSystemMetrics", "int", 1, "int")
        }
        if this.width < 64
            throw Error("DXGI: нулевая ширина кадра")
        texDesc := Buffer(44, 0)
        NumPut("uint", this.width, texDesc, 0)
        NumPut("uint", this.height, texDesc, 4)
        NumPut("uint", 1, texDesc, 8)
        NumPut("uint", 1, texDesc, 12)
        NumPut("uint", 87, texDesc, 16)
        NumPut("uint", 1, texDesc, 20)
        NumPut("uint", 0, texDesc, 24)
        NumPut("uint", 3, texDesc, 28)
        NumPut("uint", 0, texDesc, 32)
        NumPut("uint", 0x20000, texDesc, 36)
        NumPut("uint", 0, texDesc, 40)
        ComCall(5, device, "ptr", texDesc, "ptr", 0, "ptr*", &staging := 0)
        this.staging := staging
        Sleep 40
    }

    static ApplyMonitorOrigin() {
        hwnd := WinExist("A")
        hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")
        mi := Buffer(40, 0)
        NumPut("uint", 40, mi)
        if hMon && DllCall("GetMonitorInfoW", "ptr", hMon, "ptr", mi) {
            this.outputLeft := NumGet(mi, 4, "int")
            this.outputTop := NumGet(mi, 8, "int")
            this.width := NumGet(mi, 12, "int") - this.outputLeft
            this.height := NumGet(mi, 16, "int") - this.outputTop
            return
        }
        this.outputLeft := DllCall("GetSystemMetrics", "int", 76, "int")
        this.outputTop := DllCall("GetSystemMetrics", "int", 77, "int")
        this.width := DllCall("GetSystemMetrics", "int", 78, "int")
        this.height := DllCall("GetSystemMetrics", "int", 79, "int")
    }

    static Grab(timeout := 0) {
        if !this.dup
            return false
        info := Buffer(48, 0)
        res := 0
        try ComCall(8, this.dup, "uint", timeout, "ptr", info, "ptr*", &res)
        catch OSError as e {
            hr := e.number & 0xFFFFFFFF
            if hr = 0x887A0027
                return this.bits != 0
            if hr = 0x887A0026 {
                this.ready := false
                return this.Init()
            }
            return false
        }
        if NumGet(info, 0, "int64") = 0 {
            if res
                ObjRelease(res)
            try ComCall(14, this.dup)
            return this.bits != 0
        }
        this.Unmap()
        this.frameRes := res
        if this.inSysMem {
            mapped := Buffer(A_PtrSize * 2, 0)
            ComCall(12, this.dup, "ptr", mapped)
            this.pitch := NumGet(mapped, 0, "int")
            this.bits := NumGet(mapped, A_PtrSize, "ptr")
        } else {
            tex := ComObjQuery(res, "{6f15aaf2-d208-4e89-9ab4-489535d34f9c}")
            ComCall(47, this.ctx, "ptr", this.staging, "ptr", tex)
            mapped := Buffer(16, 0)
            ComCall(14, this.ctx, "ptr", this.staging, "uint", 0, "uint", 1, "uint", 0, "ptr", mapped)
            this.bits := NumGet(mapped, 0, "ptr")
            this.pitch := NumGet(mapped, A_PtrSize, "uint")
        }
        this.mapped := true
        return this.bits != 0
    }

    static Unmap() {
        if !this.mapped {
            if this.frameRes {
                ObjRelease(this.frameRes)
                this.frameRes := 0
                try ComCall(14, this.dup)
            }
            return
        }
        try {
            if this.inSysMem
                ComCall(13, this.dup)
            else
                ComCall(15, this.ctx, "ptr", this.staging, "uint", 0)
        }
        if this.frameRes {
            ObjRelease(this.frameRes)
            this.frameRes := 0
        }
        try ComCall(14, this.dup)
        this.mapped := false
    }

    static Color(sx, sy) {
        if !this.ready && !this.Init()
            return 0
        if this.lastGrab != A_TickCount {
            this.lastGrab := A_TickCount
            this.Grab(0)
        }
        if !this.bits || !this.pitch
            return 0
        x := sx - this.outputLeft
        y := sy - this.outputTop
        if x < 0 || y < 0 || x >= this.width || y >= this.height
            return 0
        bgra := NumGet(this.bits + (y * this.pitch) + (x * 4), "uint")
        r := (bgra >> 16) & 0xFF
        g := (bgra >> 8) & 0xFF
        b := bgra & 0xFF
        return (r << 16) | (g << 8) | b
    }

    static Free() {
        try this.Unmap()
        this.output1 := ""
        if this.staging {
            try ObjRelease(this.staging)
            this.staging := 0
        }
        if this.dup {
            try ObjRelease(this.dup)
            this.dup := 0
        }
        if this.ctx {
            try ObjRelease(this.ctx)
            this.ctx := 0
        }
        if this.device {
            try ObjRelease(this.device)
            this.device := 0
        }
        if this.output {
            try ObjRelease(this.output)
            this.output := 0
        }
        if this.adapter {
            try ObjRelease(this.adapter)
            this.adapter := 0
        }
        if this.factory {
            try ObjRelease(this.factory)
            this.factory := 0
        }
        this.bits := 0
        this.ready := false
        this.mapped := false
        this.frameRes := 0
    }
}

; -----------------------------------------------------------------------------
;  Чтение полоски
; -----------------------------------------------------------------------------

class Bar {
    static samples := 18

    static Read(which) {
        Game.ClientSize(&w, &h)
        if which = "hp" {
            x1 := Cfg.hpX1 * w, y1 := Cfg.hpY1 * h
            x2 := Cfg.hpX2 * w, y2 := Cfg.hpY2 * h
            fill := Cfg.hpFill
        } else {
            x1 := Cfg.mpX1 * w, y1 := Cfg.mpY1 * h
            x2 := Cfg.mpX2 * w, y2 := Cfg.mpY2 * h
            fill := Cfg.mpFill
        }
        filled := 0
        Loop this.samples {
            t := (A_Index - 1) / (this.samples - 1)
            x := Round(x1 + (x2 - x1) * t)
            y := Round(y1 + (y2 - y1) * t)
            c := Pix.Get(x, y)
            if this.IsFilled(c, fill, which)
                filled++
            else
                break
        }
        return Round(filled / this.samples * 100, 1)
    }

    static IsFilled(c, fill, which) {
        if Col.Dist(c, fill) <= Cfg.colorTol
            return true
        return (which = "hp") ? Col.IsRed(c) : Col.IsBlue(c)
    }

    static SampleFill(which) {
        Game.ClientSize(&w, &h)
        if which = "hp" {
            x := Round((Cfg.hpX1 * 0.82 + Cfg.hpX2 * 0.18) * w)
            y := Round((Cfg.hpY1 * 0.82 + Cfg.hpY2 * 0.18) * h)
        } else {
            x := Round((Cfg.mpX1 * 0.82 + Cfg.mpX2 * 0.18) * w)
            y := Round((Cfg.mpY1 * 0.82 + Cfg.mpY2 * 0.18) * h)
        }
        return Pix.Get(x, y)
    }
}

; -----------------------------------------------------------------------------
;  Автопоты
; -----------------------------------------------------------------------------

class AutoPots {
    static enabled := false
    static lastHpDrink := 0
    static lastMpDrink := 0
    static hpIdx := 1
    static mpIdx := 1
    static hpMiss := 0
    static mpMiss := 0
    static hpPct := -1
    static mpPct := -1

    static Toggle() {
        if !this.enabled && !Cfg.calibratedHp {
            Overlay.ShowHint("Сначала откалибруй HP-бар клавишей F6 (на полном здоровье)")
            SoundBeep(320, 180)
            return
        }
        this.enabled := !this.enabled
        if this.enabled {
            this.hpIdx := 1
            this.mpIdx := 1
            this.hpMiss := 0
            this.mpMiss := 0
            SoundBeep(880, 90)
            Overlay.ShowHint("Автопоты ВКЛ")
        } else {
            SoundBeep(420, 90)
            Overlay.ShowHint("Автопоты ВЫКЛ")
        }
    }

    static Tick() {
        if Calib.mode = "" && Game.IsActive() {
            now := A_TickCount
            if Cfg.calibratedHp {
                this.hpPct := Bar.Read("hp")
                if this.enabled {
                    ; 0% на всей полоске = труп или скрытый HUD — не спамим банки
                    if this.hpPct > 1.5 && this.hpPct < Cfg.hpPct && (now - this.lastHpDrink) >= Cfg.cdMs {
                        this.Drink("hp")
                        this.lastHpDrink := now
                    } else if this.hpPct >= Cfg.hpPct {
                        this.hpMiss := 0
                        this.hpIdx := 1
                    }
                }
            }
            if Cfg.calibratedMp {
                this.mpPct := Bar.Read("mp")
                if this.enabled {
                    if this.mpPct > 1.5 && this.mpPct < Cfg.mpPct && (now - this.lastMpDrink) >= Cfg.cdMs {
                        this.Drink("mp")
                        this.lastMpDrink := now
                    } else if this.mpPct >= Cfg.mpPct {
                        this.mpMiss := 0
                        this.mpIdx := 1
                    }
                }
            }
        }
        Calib.FollowCursor()
        Overlay.Refresh()
    }

    static Drink(which) {
        keys := ParseKeys(which = "hp" ? Cfg.hpKeys : Cfg.mpKeys)
        if keys.Length = 0
            return
        if which = "hp" {
            this.hpMiss++
            if this.hpMiss > 2 {
                this.hpIdx := this.hpIdx + 1
                if this.hpIdx > keys.Length
                    this.hpIdx := 1
                this.hpMiss := 0
            }
            idx := this.hpIdx
        } else {
            this.mpMiss++
            if this.mpMiss > 2 {
                this.mpIdx := this.mpIdx + 1
                if this.mpIdx > keys.Length
                    this.mpIdx := 1
                this.mpMiss := 0
            }
            idx := this.mpIdx
        }
        SendKey(keys[idx])
    }
}

; -----------------------------------------------------------------------------
;  Калибровка
; -----------------------------------------------------------------------------

class Calib {
    static mode := ""
    static tipOn := false

    static OnHp() {
        this.Step("hp")
    }

    static OnMp() {
        this.Step("mp")
    }

    static Step(which) {
        label := (which = "hp") ? "HP" : "MP"
        start := (which = "hp") ? "hp1" : "mp1"
        mid := (which = "hp") ? "hp2" : "mp2"
        keyName := (which = "hp") ? "F6" : "F7"

        if this.mode = "" || (this.mode != start && this.mode != mid) {
            if !Game.IsActive() {
                Overlay.ShowHint("Кликни по окну Hero Siege, потом " keyName)
                return
            }
            this.mode := start
            Overlay.Hide()
            SoundBeep(620, 70)
            return
        }
        if !Game.IsActive() {
            Overlay.ShowHint("Окно Hero Siege должно быть активным")
            return
        }
        MouseGetPos(&x, &y)
        Game.ClientSize(&w, &h)
        relX := x / w
        relY := y / h
        if this.mode = start {
            if which = "hp" {
                Cfg.hpX1 := relX, Cfg.hpY1 := relY
            } else {
                Cfg.mpX1 := relX, Cfg.mpY1 := relY
            }
            this.mode := mid
            SoundBeep(720, 70)
            return
        }
        if which = "hp" {
            Cfg.hpX2 := relX, Cfg.hpY2 := relY
            Cfg.hpFill := Bar.SampleFill("hp")
            if Col.IsDeadGdi(Cfg.hpFill) {
                Cfg.calibratedHp := false
                Cfg.Save()
                this.mode := ""
                ToolTip()
                Overlay.Place()
                Overlay.ShowHint("Всё ещё 3F3949 — кадр не читается. Поставь Windowed/Borderless и скачай новый скрипт")
                SoundBeep(320, 180)
                return
            }
            Cfg.calibratedHp := true
        } else {
            Cfg.mpX2 := relX, Cfg.mpY2 := relY
            Cfg.mpFill := Bar.SampleFill("mp")
            if Col.IsDeadGdi(Cfg.mpFill) {
                Cfg.calibratedMp := false
                Cfg.Save()
                this.mode := ""
                ToolTip()
                Overlay.Place()
                Overlay.ShowHint("MP тоже 3F3949. Нужен оконный/безрамочный режим, не exclusive fullscreen")
                SoundBeep(320, 180)
                return
            }
            Cfg.calibratedMp := true
        }
        Cfg.Save()
        this.mode := ""
        ToolTip()
        this.tipOn := false
        fill := (which = "hp") ? Cfg.hpFill : Cfg.mpFill
        Overlay.Place()
        Overlay.ShowHint(label " сохранён (" Col.Hex(fill) "). Дальше F8 — вкл автопоты")
        SoundBeep(940, 110)
    }

    ; Подсказка едет за курсором, оверлей в это время спрятан — HP в углу видно.
    static FollowCursor() {
        if this.mode = "" {
            if this.tipOn {
                ToolTip()
                this.tipOn := false
            }
            return
        }
        this.tipOn := true
        CoordMode("Mouse", "Screen")
        MouseGetPos(&sx, &sy)
        CoordMode("Mouse", "Client")
        MouseGetPos(&cx, &cy)
        c := 0
        try c := Pix.AtCursor()
        wantHp := InStr(this.mode, "hp")
        onBar := wantHp ? Col.IsRed(c) : Col.IsBlue(c)
        barName := wantHp ? "КРАСНОЙ HP" : "СИНЕЙ MP"
        keyName := wantHp ? "F6" : "F7"
        leftStep := (this.mode = "hp1" || this.mode = "mp1")
        edge := leftStep ? "ЛЕВЫЙ" : "ПРАВЫЙ"
        if Col.IsDeadGdi(c)
            ok := "GDI слепой. Жди красный от DXGI; если нет — закрой OBS и перезапусти скрипт"
        else
            ok := onBar ? ("✓ ты на полоске — жми " keyName) : ("не тот цвет, наведи НА " barName " полоску")
        msg := "НЕ КЛИКАЙ — только курсор и " keyName "`n"
            . "Полоска в ВЕРХНЕМ ЛЕВОМ углу, под именем персонажа.`n"
            . "Это не банка 1 внизу экрана.`n`n"
            . edge " край " barName "`n"
            . ok "`n" Col.Hex(c)
        ToolTip(msg, sx + 28, sy + 28)
    }
}

; -----------------------------------------------------------------------------
;  Отладка пикселя
; -----------------------------------------------------------------------------

class Probe {
    static Show() {
        d := Pix.DumpAtCursor()
        cur := Pix.Get(d["cx"], d["cy"])
        msg := Format(
            "метод {} → {}`ndxgi {}`nscreen {}`nalt {}`nwindow {}`nprint {}`nxy {},{}",
            Cfg.pixelMethod, Col.Hex(cur),
            Col.Hex(d["dxgi"]), Col.Hex(d["screen"]), Col.Hex(d["alt"]),
            Col.Hex(d["window"]), Col.Hex(d["print"]),
            d["sx"], d["sy"]
        )
        if !DxgiGrab.ready
            msg .= "`nDXGI: " DxgiGrab.err
        else if Col.IsRed(d["dxgi"])
            msg .= "`nDXGI видит красный — калибруй F6"
        else if Col.IsDeadGdi(d["dxgi"])
            msg .= "`nзакрой OBS/Xbox overlay и перезапусти скрипт"
        MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
        ToolTip(msg, l + 24, b - 220)
        Overlay.ShowHint(msg)
        SetTimer(() => ToolTip(), -6000)
    }
}

; -----------------------------------------------------------------------------
;  Оверлей
; -----------------------------------------------------------------------------

class Overlay {
    static g := 0
    static txt := 0
    static hintMsg := ""
    static hintUntil := 0
    static hidden := false

    static Init() {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.BackColor := "0C0C14"
        g.MarginX := 10
        g.MarginY := 8
        g.SetFont("s10 c00E676", "Segoe UI")
        this.txt := g.Add("Text", "w300 h70", "Hero Siege AutoPots`nвыкл  |  F11 двигает панель")
        this.g := g
        this.Place()
        WinSetTransparent(190, g.Hwnd)
    }

    static Place() {
        if !this.g
            return
        MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
        w := 320, h := 96, pad := 18
        switch Cfg.overlayCorner {
            case "tl": x := l + pad, y := t + pad
            case "tr": x := r - w - pad, y := t + pad
            case "bl": x := l + pad, y := b - h - pad
            default:   x := r - w - pad, y := b - h - pad
        }
        this.g.Show("x" x " y" y " NoActivate")
        this.hidden := false
    }

    static Hide() {
        if this.g {
            this.g.Hide()
            this.hidden := true
        }
    }

    static CycleCorner() {
        order := ["br", "bl", "tr", "tl"]
        i := 1
        for idx, c in order {
            if c = Cfg.overlayCorner
                i := idx
        }
        Cfg.overlayCorner := order[i = order.Length ? 1 : i + 1]
        Cfg.Save()
        this.Place()
        names := Map("br", "низ-право", "bl", "низ-лево", "tr", "верх-право", "tl", "верх-лево")
        this.ShowHint("Панель: " names[Cfg.overlayCorner] "  (F11 — ещё раз)")
    }

    ; Имя ShowHint, не Hint: в AHK v2 регистр не различается,
    ; поэтому свойство hint и метод Hint() конфликтовали (Property is read-only).
    static ShowHint(msg) {
        this.hintMsg := msg
        this.hintUntil := A_TickCount + 4000
        this.Refresh()
    }

    static Refresh() {
        if !this.txt
            return
        if Calib.mode != "" {
            this.Hide()
            return
        }
        if this.hidden
            this.Place()
        if this.hintMsg != "" && A_TickCount < this.hintUntil {
            this.txt.Value := this.hintMsg
            return
        }
        this.hintMsg := ""
        state := AutoPots.enabled ? "ВКЛ" : "ВЫКЛ"
        if !Game.Exists() {
            this.txt.Value := "Hero Siege AutoPots  " state "`nигра не найдена"
            return
        }
        if !Game.IsActive() {
            this.txt.Value := "Hero Siege AutoPots  " state "`nокно не в фокусе — поты не жмутся"
            return
        }
        hpLine := Cfg.calibratedHp
            ? Format("HP ~ {}%  (порог {}%)", AutoPots.hpPct < 0 ? "?" : AutoPots.hpPct, Cfg.hpPct)
            : "HP: нет калибровки (F6)"
        mpLine := Cfg.calibratedMp
            ? Format("MP ~ {}%  (порог {}%)", AutoPots.mpPct < 0 ? "?" : AutoPots.mpPct, Cfg.mpPct)
            : "MP: нет калибровки (F7, необязательно)"
        this.txt.Value := "Автопоты  " state "`n" hpLine "`n" mpLine
    }
}

; -----------------------------------------------------------------------------
;  Настройки
; -----------------------------------------------------------------------------

class SettingsUi {
    static g := 0

    static Show() {
        if this.g {
            try this.g.Show()
            return
        }
        g := Gui("+AlwaysOnTop", "Автопоты Hero Siege")
        g.SetFont("s10", "Segoe UI")
        g.Add("Text", "xm w360", "Клавиши банок через запятую. Примеры:  1    или    1,2,3    или    q")
        g.Add("Text", "xm y+12", "HP банки:")
        edHpKeys := g.Add("Edit", "x+8 yp w140", Cfg.hpKeys)
        g.Add("Text", "xm y+10", "MP банки:")
        edMpKeys := g.Add("Edit", "x+8 yp w140", Cfg.mpKeys)
        g.Add("Text", "xm y+10", "Пить HP если меньше %:")
        edHpPct := g.Add("Edit", "x+8 yp w60", Cfg.hpPct)
        g.Add("Text", "xm y+10", "Пить MP если меньше %:")
        edMpPct := g.Add("Edit", "x+8 yp w60", Cfg.mpPct)
        g.Add("Text", "xm y+10", "Кулдаун банки, мс:")
        edCd := g.Add("Edit", "x+8 yp w80", Cfg.cdMs)
        g.Add("Text", "xm y+10", "Интервал скана, мс:")
        edTick := g.Add("Edit", "x+8 yp w80", Cfg.tickMs)
        g.Add("Text", "xm y+10", "Допуск цвета (30–150):")
        edTol := g.Add("Edit", "x+8 yp w80", Cfg.colorTol)
        g.Add("Text", "xm y+10", "Чтение пикселя:")
        edMethod := g.Add("DropDownList", "x+8 yp w140", ["dxgi", "screen", "alt", "slow", "window", "print"])
        edMethod.Text := Cfg.pixelMethod
        g.Add("Text", "xm y+12 c666666 w360", "3F3949 на screen/window — нормально для DirectX. Нужен метод dxgi (захват кадра как OBS). Если dxgi тоже врёт — закрой OBS/Xbox Game Bar и перезапусти скрипт. F9 показывает строку dxgi внизу экрана, не на HP.")
        btn := g.Add("Button", "xm y+16 w140 Default", "Сохранить")
        btn.OnEvent("Click", (*) => SettingsUi.Save(g, edHpKeys, edMpKeys, edHpPct, edMpPct, edCd, edTick, edTol, edMethod))
        g.OnEvent("Close", (*) => SettingsUi.Closed())
        g.OnEvent("Escape", (*) => SettingsUi.Closed())
        this.g := g
        g.Show()
    }

    static Save(g, edHpKeys, edMpKeys, edHpPct, edMpPct, edCd, edTick, edTol, edMethod) {
        Cfg.hpKeys := Trim(edHpKeys.Value)
        Cfg.mpKeys := Trim(edMpKeys.Value)
        Cfg.hpPct := Clamp(SafeInt(edHpPct.Value, Cfg.hpPct), 5, 95)
        Cfg.mpPct := Clamp(SafeInt(edMpPct.Value, Cfg.mpPct), 5, 95)
        Cfg.cdMs := Clamp(SafeInt(edCd.Value, Cfg.cdMs), 200, 5000)
        Cfg.tickMs := Clamp(SafeInt(edTick.Value, Cfg.tickMs), 30, 500)
        Cfg.colorTol := Clamp(SafeInt(edTol.Value, Cfg.colorTol), 30, 180)
        if edMethod.Text != ""
            Cfg.pixelMethod := edMethod.Text
        Cfg.Save()
        SetTimer(() => AutoPots.Tick(), Cfg.tickMs)
        Overlay.ShowHint("Настройки сохранены")
        this.Closed()
    }

    static Closed() {
        if this.g {
            try this.g.Destroy()
        }
        this.g := 0
    }
}

; -----------------------------------------------------------------------------
;  Трей
; -----------------------------------------------------------------------------

class TrayMenu {
    static Init() {
        A_IconTip := "Hero Siege AutoPots"
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Автопоты вкл/выкл (F8)", (*) => AutoPots.Toggle())
        A_TrayMenu.Add("Калибровка HP (F6)", (*) => Calib.OnHp())
        A_TrayMenu.Add("Калибровка MP (F7)", (*) => Calib.OnMp())
        A_TrayMenu.Add("Настройки (F10)", (*) => SettingsUi.Show())
        A_TrayMenu.Add("Оверлей в другой угол (F11)", (*) => Overlay.CycleCorner())
        A_TrayMenu.Add()
        A_TrayMenu.Add("Выход (Shift+Esc)", (*) => ExitApp())
        A_TrayMenu.Default := "Автопоты вкл/выкл (F8)"
    }
}

; -----------------------------------------------------------------------------
;  Утилиты
; -----------------------------------------------------------------------------

ParseKeys(raw) {
    keys := []
    for part in StrSplit(raw, ",", " `t") {
        part := Trim(part)
        if part != ""
            keys.Push(part)
    }
    return keys
}

SendKey(key) {
    k := Trim(key)
    if k = ""
        return
    if StrLen(k) = 1
        SendEvent(k)
    else
        SendEvent("{" k "}")
}

SafeInt(v, def) {
    try {
        return Integer(Trim(v))
    } catch {
        return def
    }
}

SafeFloat(v, def) {
    try {
        return Float(Trim(v))
    } catch {
        return def
    }
}

Clamp(v, lo, hi) {
    if v < lo
        return lo
    if v > hi
        return hi
    return v
}
