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
;  F3        калибровка миникарты (два угла)
;  F4        ходьба по миникарте вкл / выкл
;  F6        автокалибровка HP (ищет красную полоску сама)
;  F7        автокалибровка MP
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
OnExit((*) => (Farm.ReleaseKeys(), DxgiGrab.Free(), MagGrab.Free(), Pix.PrintFree()))
if DxgiGrab.Init()
    Overlay.ShowHint("DXGI ок " DxgiGrab.width "x" DxgiGrab.height)
else if MagGrab.Init()
    Overlay.ShowHint("DXGI нет (" DxgiGrab.err "), читаю через Magnifier")
else
    Overlay.ShowHint("Нет захвата кадра: " DxgiGrab.err)
SetTimer(() => AutoPots.Tick(), Cfg.tickMs)
TrayTip("Hero Siege AutoPots", "F8 поты  F4 ходьба  F3 миникарта  F6 HP", "Iconi")

F3:: Calib.OnMap()
F4:: Farm.Toggle()
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
    static calibratedMap := false
    static mapX1 := 0.78, mapY1 := 0.04, mapX2 := 0.98, mapY2 := 0.28
    static mapFogLuma := 38
    static mapClickDist := 160
    static mapIso := 0.58
    static mapCharY := 0.06
    static mapMoveMs := 180
    static mapStopHp := 18
    static mapMove := "wasd"
    static mapColors := false
    static mapFogFill := 0x101010
    static mapFloorFill := 0x7A6A58
    static mapYaw := 0

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
        this.calibratedMap := IniRead(f, "map", "calibrated", "0") = "1"
        this.mapX1 := SafeFloat(IniRead(f, "map", "x1", this.mapX1), this.mapX1)
        this.mapY1 := SafeFloat(IniRead(f, "map", "y1", this.mapY1), this.mapY1)
        this.mapX2 := SafeFloat(IniRead(f, "map", "x2", this.mapX2), this.mapX2)
        this.mapY2 := SafeFloat(IniRead(f, "map", "y2", this.mapY2), this.mapY2)
        this.mapFogLuma := SafeInt(IniRead(f, "map", "fogLuma", this.mapFogLuma), this.mapFogLuma)
        this.mapClickDist := SafeInt(IniRead(f, "map", "clickDist", this.mapClickDist), this.mapClickDist)
        this.mapIso := SafeFloat(IniRead(f, "map", "iso", this.mapIso), this.mapIso)
        this.mapCharY := SafeFloat(IniRead(f, "map", "charY", this.mapCharY), this.mapCharY)
        this.mapMoveMs := SafeInt(IniRead(f, "map", "moveMs", this.mapMoveMs), this.mapMoveMs)
        this.mapStopHp := SafeInt(IniRead(f, "map", "stopHp", this.mapStopHp), this.mapStopHp)
        this.mapMove := IniRead(f, "map", "move", this.mapMove)
        if this.mapMove != "click"
            this.mapMove := "wasd"
        this.mapColors := IniRead(f, "map", "colors", "0") = "1"
        this.mapFogFill := SafeInt(IniRead(f, "map", "fogFill", this.mapFogFill), this.mapFogFill)
        this.mapFloorFill := SafeInt(IniRead(f, "map", "floorFill", this.mapFloorFill), this.mapFloorFill)
        this.mapYaw := SafeInt(IniRead(f, "map", "yaw", this.mapYaw), this.mapYaw)
        this.mapYaw := Clamp(this.mapYaw, -90, 90)
        this.mapFogLuma := Clamp(this.mapFogLuma, 16, 72)
        this.mapClickDist := Clamp(this.mapClickDist, 80, 520)
        this.mapIso := Clamp(this.mapIso, 0.35, 1.0)
        this.mapStopHp := Clamp(this.mapStopHp, 5, 80)
        if this.mapClickDist >= 230 && this.mapClickDist <= 250
            this.mapClickDist := 160
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
        IniWrite(this.calibratedMap ? "1" : "0", f, "map", "calibrated")
        IniWrite(Format("{:.5f}", this.mapX1), f, "map", "x1")
        IniWrite(Format("{:.5f}", this.mapY1), f, "map", "y1")
        IniWrite(Format("{:.5f}", this.mapX2), f, "map", "x2")
        IniWrite(Format("{:.5f}", this.mapY2), f, "map", "y2")
        IniWrite(this.mapFogLuma, f, "map", "fogLuma")
        IniWrite(this.mapClickDist, f, "map", "clickDist")
        IniWrite(Format("{:.3f}", this.mapIso), f, "map", "iso")
        IniWrite(Format("{:.3f}", this.mapCharY), f, "map", "charY")
        IniWrite(this.mapMoveMs, f, "map", "moveMs")
        IniWrite(this.mapStopHp, f, "map", "stopHp")
        IniWrite(this.mapMove, f, "map", "move")
        IniWrite(this.mapColors ? "1" : "0", f, "map", "colors")
        IniWrite(Format("0x{:06X}", this.mapFogFill), f, "map", "fogFill")
        IniWrite(Format("0x{:06X}", this.mapFloorFill), f, "map", "floorFill")
        IniWrite(this.mapYaw, f, "map", "yaw")
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
    static Luma(c) => (this.R(c) * 2 + this.G(c) * 3 + this.B(c)) // 6

    static Dist(a, b) {
        dr := this.R(a) - this.R(b)
        dg := this.G(a) - this.G(b)
        db := this.B(a) - this.B(b)
        return Sqrt(dr * dr + dg * dg + db * db)
    }

    static IsRed(c) {
        r := this.R(c), g := this.G(c), b := this.B(c)
        return r >= 110 && r > g + 28 && r > b + 28
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
                if DxgiGrab.ready {
                    c := DxgiGrab.Color(sx, sy)
                    if c && !Col.IsDeadGdi(c)
                        return c
                }
                if MagGrab.ready {
                    c := MagGrab.Color(sx, sy)
                    if c && !Col.IsDeadGdi(c)
                        return c
                }
                return this.Screen(cx, cy)
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
        if DxgiGrab.ready || Cfg.pixelMethod = "dxgi" {
            c := DxgiGrab.Color(sx, sy)
            if c
                return c
            if DxgiGrab.ready && !Col.IsDeadGdi(c)
                return c
        }
        if MagGrab.ready {
            c := MagGrab.Color(sx, sy)
            if c && !Col.IsDeadGdi(c)
                return c
        }
        hwnd := WinExist("A")
        NumPut("int", sx, "int", sy, pt)
        DllCall("ScreenToClient", "ptr", hwnd, "ptr", pt)
        return this.Get(NumGet(pt, 0, "int"), NumGet(pt, 4, "int"))
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
        mag := MagGrab.ready ? MagGrab.Color(sx, sy) : 0
        return Map(
            "sx", sx, "sy", sy, "cx", cx, "cy", cy,
            "screen", screen, "alt", alt, "window", window, "print", print, "dxgi", dxgi, "mag", mag
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
    static cpu := 0, cpuPitch := 0

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
        DllCall("GetModuleHandle", "str", "DXGI") || DllCall("LoadLibrary", "str", "DXGI")
        DllCall("GetModuleHandle", "str", "D3D11") || DllCall("LoadLibrary", "str", "D3D11")
        ; IDXGIFactory1 — не путать с IDXGIFactory, иначе EnumAdapters часто ломается
        DllCall("ole32\IIDFromString", "wstr", "{770AAE78-F26F-4DBA-A829-253C83D1B387}", "ptr", iid := Buffer(16), "hresult")
        DllCall("dxgi\CreateDXGIFactory1", "ptr", iid, "ptr*", &factory := 0, "hresult")
        this.factory := factory
        adapter := 0, output := 0, found := false
        a := 0
        while 0x887A0002 != ComCall(7, factory, "uint", a, "ptr*", &adapter, "uint") {
            o := 0
            while 0x887A0002 != ComCall(7, adapter, "uint", o, "ptr*", &output, "uint") {
                desc := Buffer(88 + A_PtrSize, 0)
                ComCall(7, output, "ptr", desc)
                name := StrGet(desc, 32, "UTF-16")
                this.adapter := adapter
                this.output := output
                this.BindMonitor(name)
                found := true
                break 2
            }
            ObjRelease(adapter)
            a += 1
        }
        if !found
            throw Error("DXGI: нет DISPLAY-выхода")
        DllCall("D3D11\D3D11CreateDevice"
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
            , "hresult")
        this.device := device
        this.ctx := ctx
        this.output1 := ComObjQuery(output, "{00CDDEA8-939B-4B83-A340-A685226666CC}")
        try ComCall(22, this.output1, "ptr", device, "ptr*", &dup := 0)
        catch as e
            throw Error("DuplicateOutput: " e.Message " — закрой OBS/Xbox Game Bar")
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
        if this.width < 64 || this.height < 64
            this.ApplyMonitorOrigin()
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
        Sleep 50
    }

    static BindMonitor(name) {
        Loop MonitorGetCount() {
            try {
                if MonitorGetName(A_Index) = name {
                    MonitorGet(A_Index, &l, &t, &r, &b)
                    this.outputLeft := l
                    this.outputTop := t
                    this.width := r - l
                    this.height := b - t
                    return
                }
            }
        }
        this.ApplyMonitorOrigin()
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

    static Grab(timeout := 50) {
        if !this.dup
            return false
        this.lastGrab := A_TickCount
        this.Unmap()
        info := Buffer(48, 0)
        res := 0
        try ComCall(8, this.dup, "uint", timeout, "ptr", info, "ptr*", &res)
        catch OSError as e {
            hr := e.number & 0xFFFFFFFF
            if hr = 0x887A0027
                return this.cpu != 0
            if hr = 0x887A0026 {
                this.ready := false
                return this.Init()
            }
            return this.cpu != 0
        }
        if NumGet(info, 0, "int64") = 0 {
            if res
                ObjRelease(res)
            try ComCall(14, this.dup)
            return this.cpu != 0
        }
        this.frameRes := res
        this.mapped := true
        try {
            if this.inSysMem {
                mapped := Buffer(A_PtrSize * 2, 0)
                ComCall(12, this.dup, "ptr", mapped)
                this.CopyBits(NumGet(mapped, A_PtrSize, "ptr"), NumGet(mapped, 0, "int"))
            } else {
                tex := ComObjQuery(res, "{6F15AAF2-D208-4E89-9AB4-489535D34F9C}")
                ComCall(47, this.ctx, "ptr", this.staging, "ptr", tex)
                mapped := Buffer(16, 0)
                ComCall(14, this.ctx, "ptr", this.staging, "uint", 0, "uint", 1, "uint", 0, "ptr", mapped)
                this.CopyBits(NumGet(mapped, 0, "ptr"), NumGet(mapped, A_PtrSize, "uint"))
            }
        } finally {
            this.Unmap()
        }
        return this.cpu != 0
    }

    static CopyBits(pBits, pitch) {
        if !pBits || pitch < 4 || this.height < 1
            return
        this.cpuPitch := pitch
        this.pitch := pitch
        this.cpu := Buffer(pitch * this.height)
        DllCall("RtlMoveMemory", "ptr", this.cpu, "ptr", pBits, "uptr", pitch * this.height)
        this.bits := this.cpu.Ptr
    }

    static Unmap() {
        if this.mapped {
            try {
                if this.inSysMem
                    ComCall(13, this.dup)
                else if this.staging
                    ComCall(15, this.ctx, "ptr", this.staging, "uint", 0)
            }
            this.mapped := false
        }
        if this.frameRes {
            try ObjRelease(this.frameRes)
            this.frameRes := 0
            try ComCall(14, this.dup)
        }
    }

    static Color(sx, sy) {
        if !this.ready && !this.Init()
            return 0
        ; timeout 0 почти всегда DXGI_ERROR_WAIT_TIMEOUT — тогда навсегда
        ; остаётся кадр калибровки (полное HP → вечные 100%).
        if this.lastGrab != A_TickCount
            this.Grab(40)
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
        this.cpu := 0
        this.ready := false
        this.mapped := false
        this.frameRes := 0
    }

    static BufColor(bx, by) {
        if !this.bits || !this.pitch || bx < 0 || by < 0 || bx >= this.width || by >= this.height
            return 0
        bgra := NumGet(this.bits + (by * this.pitch) + (bx * 4), "uint")
        r := (bgra >> 16) & 0xFF
        g := (bgra >> 8) & 0xFF
        b := bgra & 0xFF
        return (r << 16) | (g << 8) | b
    }

    ; Ищет самую длинную красную/синюю горизонталь в HUD (верхний левый угол).
    static ScanBar(kind, &sx1, &sy1, &sx2, &sy2) {
        ToolTip()
        Loop 10 {
            this.Grab(80)
            if this.bits
                break
        }
        if !this.bits || !this.pitch
            return false
        WinGetClientPos(&cl, &ct, &cw, &ch, "A")
        bx0 := Max(0, cl - this.outputLeft)
        by0 := Max(0, ct - this.outputTop)
        bx1 := Min(this.width - 1, cl + cw - this.outputLeft)
        by1 := Min(this.height - 1, ct + ch - this.outputTop)
        xMin := bx0
        xLim := bx0 + Integer((bx1 - bx0) * 0.52)
        if kind = "hp" {
            yMin := by0
            yLim := by0 + Integer((by1 - by0) * 0.30)
        } else if Cfg.calibratedHp {
            hpY := ct + Integer(Cfg.hpY1 * ch) - this.outputTop
            yMin := hpY + 4
            yLim := hpY + 40
        } else {
            yMin := by0 + Integer((by1 - by0) * 0.05)
            yLim := by0 + Integer((by1 - by0) * 0.32)
        }
        if xLim <= xMin || yLim <= yMin
            return false
        best := 0, bestX1 := 0, bestX2 := 0, bestY := 0
        y := yMin
        while y <= yLim {
            len := this.RowSpan(kind, y, xMin, xLim, &x1, &x2)
            if len > best {
                best := len, bestX1 := x1, bestX2 := x2, bestY := y
            }
            y += 1
        }
        if best < 28
            return false
        ; Берём середину полоски по вертикали, а не 1px рамки, которая не укорачивается.
        thresh := Max(28, Integer(best * 0.82))
        yTop := bestY, yBot := bestY
        y := bestY - 1
        while y >= yMin {
            if this.RowSpan(kind, y, xMin, xLim, &x1, &x2) < thresh
                break
            yTop := y
            y -= 1
        }
        y := bestY + 1
        while y <= yLim {
            if this.RowSpan(kind, y, xMin, xLim, &x1, &x2) < thresh
                break
            yBot := y
            y += 1
        }
        bestY := (yTop + yBot) // 2
        this.RowSpan(kind, bestY, xMin, xLim, &bestX1, &bestX2)
        if bestX2 - bestX1 > 14 {
            bestX1 += 4
            bestX2 -= 4
        }
        sx1 := this.outputLeft + bestX1
        sy1 := this.outputTop + bestY
        sx2 := this.outputLeft + bestX2
        sy2 := this.outputTop + bestY
        return true
    }

    static RowSpan(kind, y, xMin, xLim, &x1, &x2) {
        best := 0, rs := 0, run := 0
        x1 := 0, x2 := 0
        x := xMin
        while x <= xLim {
            hit := (kind = "hp") ? Col.IsRed(this.BufColor(x, y)) : Col.IsBlue(this.BufColor(x, y))
            if hit {
                if run = 0
                    rs := x
                run += 1
            } else {
                if run > best {
                    best := run, x1 := rs, x2 := x - 1
                }
                run := 0
            }
            x += 1
        }
        if run > best {
            best := run, x1 := rs, x2 := xLim
        }
        return best
    }
}

; Magnifier host: DWM кладёт в него уже составленный кадр, GDI это видит.
class MagGrab {
    static ready := false
    static host := 0
    static hMag := 0

    static Init() {
        this.Free()
        try {
            DllCall("LoadLibrary", "str", "Magnification")
            if !DllCall("magnification\MagInitialize")
                return false
            g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x80000")
            g.Show("x-64000 y-64000 w16 h16 NoActivate")
            this.host := g
            this.hMag := DllCall("CreateWindowEx"
                , "uint", 0
                , "str", "Magnifier"
                , "str", ""
                , "uint", 0x50000000
                , "int", 0, "int", 0, "int", 16, "int", 16
                , "ptr", g.Hwnd, "ptr", 0, "ptr", 0, "ptr", 0, "ptr")
            if !this.hMag
                return false
            xf := Buffer(36, 0)
            NumPut("float", 1, xf, 0)
            NumPut("float", 1, xf, 16)
            NumPut("float", 1, xf, 32)
            DllCall("magnification\MagSetWindowTransform", "ptr", this.hMag, "ptr", xf)
            this.ready := true
            return true
        } catch {
            this.Free()
            return false
        }
    }

    static Color(sx, sy) {
        if !this.ready
            return 0
        rc := Buffer(16, 0)
        NumPut("int", sx, "int", sy, "int", sx + 1, "int", sy + 1, rc)
        DllCall("magnification\MagSetWindowSource", "ptr", this.hMag, "ptr", rc)
        DllCall("user32\InvalidateRect", "ptr", this.hMag, "ptr", 0, "int", 1)
        DllCall("user32\UpdateWindow", "ptr", this.hMag)
        hdc := DllCall("GetDC", "ptr", this.hMag, "ptr")
        col := DllCall("GetPixel", "ptr", hdc, "int", 0, "int", 0, "uint")
        DllCall("ReleaseDC", "ptr", this.hMag, "ptr", hdc)
        return Pix.FromColorRef(col)
    }

    static Free() {
        this.ready := false
        if this.hMag {
            try DllCall("user32\DestroyWindow", "ptr", this.hMag)
            this.hMag := 0
        }
        if this.host {
            try this.host.Destroy()
            this.host := 0
        }
        try DllCall("magnification\MagUninitialize")
    }
}

; -----------------------------------------------------------------------------
;  Чтение полоски
; -----------------------------------------------------------------------------

class Bar {
    static samples := 24

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
        if !c || Col.IsDeadGdi(c)
            return false
        if Col.Dist(c, fill) > Cfg.colorTol
            return false
        ; Пустой трек часто тёмно-красный/синий. «Любой красный» → вечные 100%.
        if which = "hp"
            return Col.R(c) >= Col.R(fill) - 28
        return Col.B(c) >= Col.B(fill) - 28
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
;  Ходьба по миникарте: WASD по 8 направлениям к туману, без кликов по земле.
;  Чёрный пиксель = 0, Pix.Get его отбрасывает как «нет цвета» — читаем DXGI напрямую.
; -----------------------------------------------------------------------------

class Farm {
    static enabled := false
    static lastMove := 0
    static lastAngle := 0.0
    static lastDir := "?"
    static lastHash := -1
    static hashSince := 0
    static status := ""
    static lastStopT := 0.45
    static lastKind := ""
    static lastK := 0
    static lastScore := 0
    static hw := false, ha := false, hs := false, hd := false
    static havePath := false
    static compass := ""
    static blocked := 0

    static Toggle() {
        if this.enabled {
            this.enabled := false
            this.ReleaseKeys()
            SoundBeep(420, 90)
            Overlay.ShowHint("Ходьба по карте ВЫКЛ")
            return
        }
        if !Cfg.calibratedMap {
            Overlay.ShowHint("Сначала F3: два угла миникарты (в данже, карта M)")
            SoundBeep(320, 180)
            return
        }
        if !Game.IsActive() {
            Overlay.ShowHint("Кликни по окну Hero Siege, потом F4")
            return
        }
        this.enabled := true
        this.lastMove := 0
        this.hashSince := 0
        this.lastHash := -1
        this.lastScore := 0
        this.lastK := -1
        this.blocked := 0
        this.compass := ""
        SoundBeep(880, 90)
        Overlay.ShowHint("Ходьба WASD. Сверь стрелки на панели с миникартой. F4 — стоп")
    }

    static Tick() {
        if !this.enabled || !Cfg.calibratedMap {
            this.ReleaseKeys()
            return
        }
        if Cfg.calibratedHp && AutoPots.hpPct > 1.5 && AutoPots.hpPct < Cfg.mapStopHp {
            this.ReleaseKeys()
            this.status := "стою, мало HP"
            return
        }
        if A_TickCount - this.lastMove < Cfg.mapMoveMs
            return
        ang := this.Heading()
        if !this.havePath {
            this.ReleaseKeys()
            this.status := this.lastKind
            this.lastMove := A_TickCount
            return
        }
        if Cfg.mapMove = "click"
            this.ClickWorld(ang)
        else
            this.HoldFromK(this.AngleToK(ang))
        this.lastMove := A_TickCount
        this.status := this.lastDir " " this.lastKind " " this.compass
    }

    static ReleaseKeys() {
        this.SetKey("w", false)
        this.SetKey("a", false)
        this.SetKey("s", false)
        this.SetKey("d", false)
    }

    static KeysFor(k) {
        k := Mod(k + 8, 8)
        arr := ["d", "sd", "s", "as", "a", "aw", "w", "wd"]
        return arr[k + 1]
    }

    static HoldFromK(k) {
        spec := this.KeysFor(k)
        this.SetKey("w", InStr(spec, "w"))
        this.SetKey("a", InStr(spec, "a"))
        this.SetKey("s", InStr(spec, "s"))
        this.SetKey("d", InStr(spec, "d"))
    }

    static SetKey(ch, on) {
        held := (ch = "w") ? this.hw : (ch = "a") ? this.ha : (ch = "s") ? this.hs : this.hd
        on := on ? true : false
        if held = on
            return
        SendEvent("{" ch " " (on ? "down" : "up") "}")
        if ch = "w"
            this.hw := on
        else if ch = "a"
            this.ha := on
        else if ch = "s"
            this.hs := on
        else
            this.hd := on
    }

    static AngleToK(ang) {
        k := Integer(Round(ang / 6.283185307179586 * 8))
        return Mod(k + 32, 8)
    }

    static Rect(&x1, &y1, &x2, &y2) {
        Game.ClientSize(&w, &h)
        x1 := Cfg.mapX1 * w, y1 := Cfg.mapY1 * h
        x2 := Cfg.mapX2 * w, y2 := Cfg.mapY2 * h
        if x2 < x1 {
            t := x1, x1 := x2, x2 := t
        }
        if y2 < y1 {
            t := y1, y1 := y2, y2 := t
        }
    }

    static ColorAt(cx, cy) {
        if !DxgiGrab.ready || !DxgiGrab.bits
            return -1
        Pix.ToScreen(cx, cy, &sx, &sy)
        bx := sx - DxgiGrab.outputLeft
        by := sy - DxgiGrab.outputTop
        if bx < 0 || by < 0 || bx >= DxgiGrab.width || by >= DxgiGrab.height
            return -1
        return DxgiGrab.BufColor(bx, by)
    }

    static SampleLuma(cx, cy) {
        c := this.ColorAt(cx, cy)
        if c < 0
            return -1
        return Col.Luma(c)
    }

    static CellKind(c) {
        if c < 0
            return "wall"
        if this.IsWhiteWall(c)
            return "wall"
        if Cfg.mapColors {
            df := Col.Dist(c, Cfg.mapFogFill)
            dl := Col.Dist(c, Cfg.mapFloorFill)
            if df + 12 < dl && df <= 70
                return "fog"
            if dl + 8 < df && dl <= 80
                return "floor"
            if dl <= 42
                return "floor"
            if df <= 28
                return "fog"
            return "wall"
        }
        lu := Col.Luma(c)
        if lu <= 28
            return "fog"
        if lu >= 48
            return "floor"
        return "wall"
    }

    static IsWhiteWall(c) {
        r := Col.R(c), g := Col.G(c), b := Col.B(c)
        lu := Col.Luma(c)
        if lu < 165
            return false
        return Abs(r - g) <= 40 && Abs(g - b) <= 40 && Abs(r - b) <= 40
    }

    static Heading() {
        this.Rect(&x1, &y1, &x2, &y2)
        padX := (x2 - x1) * 0.16
        padY := (y2 - y1) * 0.16
        x1 += padX, x2 -= padX, y1 += padY, y2 -= padY
        cx := (x1 + x2) / 2
        cy := (y1 + y2) / 2
        halfW := (x2 - x1) / 2
        halfH := (y2 - y1) / 2
        this.havePath := false
        if halfW < 8 || halfH < 8 {
            this.lastKind := "нет карты"
            return this.lastAngle
        }
        tau := 6.283185307179586
        yaw := Cfg.mapYaw * tau / 360
        bestFog := -999999
        bestOpen := -999999
        fogK := 0
        openK := 0
        kinds := ["?", "?", "?", "?", "?", "?", "?", "?"]
        k := 0
        while k < 8 {
            if (this.blocked >> k) & 1 {
                kinds[k + 1] := "x"
                k += 1
                continue
            }
            ang := k * tau / 8 + yaw
            kind := "", floorSteps := 0, stopT := 0.3
            this.Trace(cx, cy, ang, halfW, halfH, &kind, &floorSteps, &stopT)
            kinds[k + 1] := (kind = "fog") ? "т" : (kind = "open") ? "п" : (kind = "wall") ? "с" : "?"
            stick := (this.lastK >= 0 && k = this.lastK) ? 10 : 0
            diag := Mod(k, 2) = 1 ? -14 : 0
            if kind = "fog" && floorSteps >= 2 {
                score := 100 + floorSteps * 8 + stick + diag
                if score > bestFog {
                    bestFog := score, fogK := k
                }
            } else if kind = "open" && floorSteps >= 3 {
                score := floorSteps * 6 + stick + diag
                if score > bestOpen {
                    bestOpen := score, openK := k
                }
            }
            k += 1
        }
        this.compass := Format("↑{} →{} ↓{} ←{}", kinds[7], kinds[1], kinds[3], kinds[5])
        if bestFog > -999999 {
            pickK := fogK, this.lastKind := "туман", pickScore := bestFog
        } else if bestOpen > -999999 {
            pickK := openK, this.lastKind := "пол", pickScore := bestOpen
        } else {
            this.blocked := 0
            this.lastKind := "нет пути " this.compass
            this.ReleaseKeys()
            return this.lastAngle
        }
        h := this.CenterHash(cx, cy)
        if h = this.lastHash {
            if this.hashSince = 0
                this.hashSince := A_TickCount
            if A_TickCount - this.hashSince > 700 {
                this.blocked := this.blocked | (1 << pickK)
                this.hashSince := A_TickCount
                this.lastHash := -1
                this.lastK := -1
                this.lastKind := "обход " this.compass
                this.havePath := false
                this.ReleaseKeys()
                return this.lastAngle
            }
        } else {
            this.lastHash := h
            this.hashSince := A_TickCount
        }
        this.havePath := true
        this.lastK := pickK
        this.lastScore := pickScore
        bestA := pickK * tau / 8
        this.lastAngle := bestA
        this.lastDir := this.Arrow(bestA)
        this.lastStopT := 0.4
        return bestA
    }

    static Trace(cx, cy, ang, halfW, halfH, &kind, &floorSteps, &stopT) {
        kind := "open"
        floorSteps := 0
        stopT := 0.28
        lastFloorT := 0.18
        sawFloor := false
        fogRun := 0
        samples := 20
        i := 0
        while i < samples {
            t := 0.08 + i * 0.042
            c := this.ColorAt(cx + Cos(ang) * t * halfW, cy + Sin(ang) * t * halfH)
            cell := this.CellKind(c)
            i += 1
            if i <= 1
                continue
            if cell = "wall" {
                kind := "wall"
                stopT := sawFloor ? lastFloorT : 0.16
                return
            }
            if cell = "fog" {
                if !sawFloor {
                    kind := "wall"
                    stopT := 0.16
                    return
                }
                fogRun += 1
                if fogRun >= 3 {
                    kind := "fog"
                    stopT := lastFloorT
                    return
                }
            } else {
                if fogRun > 0 {
                    kind := "wall"
                    stopT := lastFloorT
                    return
                }
                sawFloor := true
                floorSteps += 1
                lastFloorT := t
                stopT := t
            }
        }
        if fogRun >= 3 {
            kind := "fog"
            stopT := lastFloorT
        } else if fogRun > 0
            kind := "wall"
        else
            kind := "open"
    }

    static CenterHash(cx, cy) {
        s := 0
        s += this.SampleLuma(cx, cy)
        s += this.SampleLuma(cx + 6, cy) * 3
        s += this.SampleLuma(cx - 6, cy) * 5
        s += this.SampleLuma(cx, cy + 6) * 7
        s += this.SampleLuma(cx, cy - 6) * 11
        return s
    }

    static Arrow(ang) {
        k := Integer(Round(ang / 6.283185307179586 * 8))
        k := Mod(k + 32, 8)
        arr := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
        return arr[k + 1]
    }

    static ClickWorld(ang) {
        Game.ClientSize(&w, &h)
        dist := Integer(Cfg.mapClickDist * this.lastStopT)
        dist := Clamp(dist, 64, Cfg.mapClickDist)
        x := w * 0.5 + Cos(ang) * dist
        y := h * (0.5 + Cfg.mapCharY) + Sin(ang) * dist * Cfg.mapIso
        this.Rect(&mx1, &my1, &mx2, &my2)
        if x >= mx1 && x <= mx2 && y >= my1 && y <= my2 {
            x := w * 0.5
            y := h * (0.5 + Cfg.mapCharY)
        }
        x := Clamp(Round(x), 12, w - 12)
        y := Clamp(Round(y), 12, h - 12)
        Click(Integer(x) " " Integer(y))
    }

    static LearnFog() {
        this.Rect(&x1, &y1, &x2, &y2)
        padX := (x2 - x1) * 0.12
        padY := (y2 - y1) * 0.12
        x1 += padX, x2 -= padX, y1 += padY, y2 -= padY
        n := 0, sum := 0
        iy := 0
        while iy < 10 {
            ix := 0
            while ix < 10 {
                px := x1 + (x2 - x1) * (ix + 0.5) / 10
                py := y1 + (y2 - y1) * (iy + 0.5) / 10
                lu := this.SampleLuma(px, py)
                if lu >= 0 && lu < 72 {
                    n += 1
                    sum += lu
                }
                ix += 1
            }
            iy += 1
        }
        if n >= 6
            Cfg.mapFogLuma := Clamp(Integer(sum / n + 8), 16, 72)
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
            if DxgiGrab.ready
                DxgiGrab.Grab(30)
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
            Farm.Tick()
        }
        if Calib.mode != "" || !Game.IsActive()
            Farm.ReleaseKeys()
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
        if InStr(this.mode, "hp") {
            this.Step("hp")
            return
        }
        if this.mode != ""
            return
        if !Game.IsActive() {
            Overlay.ShowHint("Кликни по окну Hero Siege, потом F6")
            return
        }
        ToolTip()
        Overlay.Place()
        Overlay.ShowHint("Ищу красную полоску HP...")
        if this.AutoDetect("hp")
            return
        this.mode := "hp1"
        Overlay.ShowHint("Автопоиск не нашёл. Наведи на КРАСНУЮ ЗАЛИВКУ (не рамку и не цифры) слева, F6")
        SoundBeep(620, 70)
    }

    static OnMp() {
        if InStr(this.mode, "mp") && !InStr(this.mode, "map") {
            this.Step("mp")
            return
        }
        if this.mode != ""
            return
        if !Game.IsActive() {
            Overlay.ShowHint("Кликни по окну Hero Siege, потом F7")
            return
        }
        ToolTip()
        Overlay.Place()
        Overlay.ShowHint("Ищу синюю полоску MP...")
        if this.AutoDetect("mp")
            return
        this.mode := "mp1"
        Overlay.ShowHint("Автопоиск не нашёл. Наведи на СИНЮЮ заливку слева, F7")
        SoundBeep(620, 70)
    }

    static OnMap() {
        if this.mode = "map1" || this.mode = "map2" || this.mode = "map3" || this.mode = "map4" {
            this.StepMap()
            return
        }
        if this.mode != "" {
            Overlay.ShowHint("Сначала закончи текущую калибровку")
            return
        }
        if !Game.IsActive() {
            Overlay.ShowHint("Кликни по окну Hero Siege, потом F3")
            return
        }
        this.mode := "map1"
        Overlay.Place()
        Overlay.ShowHint("Миникарта: наведи на ЛЕВЫЙ ВЕРХНИЙ угол самой карты (внутри рамки), F3")
        SoundBeep(620, 70)
    }

    static StepMap() {
        if !Game.IsActive() {
            Overlay.ShowHint("Окно Hero Siege должно быть активным")
            return
        }
        MouseGetPos(&x, &y)
        Game.ClientSize(&w, &h)
        if this.mode = "map1" {
            Cfg.mapX1 := x / w
            Cfg.mapY1 := y / h
            this.mode := "map2"
            Overlay.ShowHint("Теперь ПРАВЫЙ НИЖНИЙ угол миникарты, F3")
            SoundBeep(720, 70)
            return
        }
        Cfg.mapX2 := x / w
        Cfg.mapY2 := y / h
        this.mode := ""
        this.tipOn := false
        ToolTip()
        Cfg.calibratedMap := true
        Cfg.Save()
        Overlay.Place()
        Overlay.ShowHint("Миникарта сохранена. Белые линии = стены. F4 — ходьба")
        SoundBeep(940, 110)
    }

    static AutoDetect(which) {
        if !DxgiGrab.ready
            return false
        if !DxgiGrab.ScanBar(which, &sx1, &sy1, &sx2, &sy2)
            return false
        this.ToFrac(sx1, sy1, &fx1, &fy1)
        this.ToFrac(sx2, sy2, &fx2, &fy2)
        if which = "hp" {
            Cfg.hpX1 := fx1, Cfg.hpY1 := fy1, Cfg.hpX2 := fx2, Cfg.hpY2 := fy2
            Cfg.hpFill := Bar.SampleFill("hp")
            if Col.IsDeadGdi(Cfg.hpFill)
                return false
            Cfg.calibratedHp := true
            fill := Cfg.hpFill
        } else {
            Cfg.mpX1 := fx1, Cfg.mpY1 := fy1, Cfg.mpX2 := fx2, Cfg.mpY2 := fy2
            Cfg.mpFill := Bar.SampleFill("mp")
            if Col.IsDeadGdi(Cfg.mpFill)
                return false
            Cfg.calibratedMp := true
            fill := Cfg.mpFill
        }
        Cfg.Save()
        this.mode := ""
        this.tipOn := false
        ToolTip()
        Overlay.Place()
        pct := Bar.Read(which)
        if which = "hp"
            AutoPots.hpPct := pct
        else
            AutoPots.mpPct := pct
        Overlay.ShowHint(Format(
            "{} найден, цвет {}`nсейчас ~{}% — получи урон, цифра должна упасть. Потом F8",
            which = "hp" ? "HP" : "MP", Col.Hex(fill), pct))
        SoundBeep(940, 110)
        return true
    }

    static ToFrac(sx, sy, &fx, &fy) {
        hwnd := WinExist("A")
        pt := Buffer(8)
        NumPut("int", sx, "int", sy, pt)
        DllCall("ScreenToClient", "ptr", hwnd, "ptr", pt)
        Game.ClientSize(&w, &h)
        fx := NumGet(pt, 0, "int") / Max(w, 1)
        fy := NumGet(pt, 4, "int") / Max(h, 1)
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
            Overlay.Place()
            Overlay.ShowHint(label ": наведи на ЗАЛИВКУ полоски (не рамку, не белые цифры), " keyName)
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
        if InStr(this.mode, "map") {
            this.tipOn := false
            return
        }
        this.tipOn := true
        c := 0
        try c := Pix.AtCursor()
        wantHp := InStr(this.mode, "hp")
        onBar := wantHp ? Col.IsRed(c) : Col.IsBlue(c)
        barName := wantHp ? "КРАСНОЙ HP" : "СИНЕЙ MP"
        keyName := wantHp ? "F6" : "F7"
        leftStep := (this.mode = "hp1" || this.mode = "mp1")
        edge := leftStep ? "левая" : "правая"
        if onBar
            ok := "✓ заливка видна — жми " keyName
        else
            ok := Col.Hex(c) " — целься в цветную ЗАЛИВКУ, не в рамку и не в цифры"
        Overlay.ShowHint("НЕ КЛИКАЙ. " edge " часть " barName "`n" ok)
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
            "метод {} → {}`ndxgi {}`nmag {}`nscreen {}`nxy {},{}",
            Cfg.pixelMethod, Col.Hex(cur),
            Col.Hex(d["dxgi"]), Col.Hex(d["mag"]), Col.Hex(d["screen"]),
            d["sx"], d["sy"]
        )
        if DxgiGrab.ready
            msg .= "`nDXGI " DxgiGrab.width "x" DxgiGrab.height
        else
            msg .= "`nDXGI: " DxgiGrab.err
        if MagGrab.ready
            msg .= "`nMagnifier ок"
        if Col.IsRed(cur)
            msg .= "`nвижу красный — калибруй F6"
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
        this.txt := g.Add("Text", "w300 h102", "Hero Siege AutoPots`nвыкл  |  F11 двигает панель")
        this.g := g
        this.Place()
        WinSetTransparent(190, g.Hwnd)
    }

    static Place() {
        if !this.g
            return
        MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
        w := 320, h := 136, pad := 18
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
        if this.hidden
            this.Place()
        state := AutoPots.enabled ? "ВКЛ" : "ВЫКЛ"
        hpLine := Cfg.calibratedHp
            ? Format("HP ~ {}%  (порог {}%)", AutoPots.hpPct < 0 ? "?" : AutoPots.hpPct, Cfg.hpPct)
            : "HP: нет калибровки (F6)"
        mpLine := Cfg.calibratedMp
            ? Format("MP ~ {}%  (порог {}%)", AutoPots.mpPct < 0 ? "?" : AutoPots.mpPct, Cfg.mpPct)
            : "MP: нет калибровки (F7, необязательно)"
        farmLine := !Cfg.calibratedMap
            ? "карта: нет калибровки (F3)"
            : (Farm.enabled ? "карта " Farm.status : "карта выкл (F4)")
        if this.hintMsg != "" && A_TickCount < this.hintUntil {
            this.txt.Value := this.hintMsg "`n" hpLine
            return
        }
        this.hintMsg := ""
        if !Game.Exists() {
            this.txt.Value := "Hero Siege AutoPots  " state "`nигра не найдена"
            return
        }
        if !Game.IsActive() {
            this.txt.Value := "Hero Siege AutoPots  " state "`nокно не в фокусе — поты не жмутся"
            return
        }
        this.txt.Value := "Автопоты  " state "`n" hpLine "`n" mpLine "`n" farmLine
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
        g.Add("Text", "xm y+10", "Ходьба:")
        edMove := g.Add("DropDownList", "x+8 yp w140", ["wasd", "click"])
        edMove.Text := Cfg.mapMove
        g.Add("Text", "xm y+10", "Клик ходьбы, пикс (если click):")
        edMapDist := g.Add("Edit", "x+8 yp w80", Cfg.mapClickDist)
        g.Add("Text", "xm y+10", "Туман миникарты (luma 16–72):")
        edFog := g.Add("Edit", "x+8 yp w80", Cfg.mapFogLuma)
        g.Add("Text", "xm y+10", "Стоп ходьбы если HP < %:")
        edMapStop := g.Add("Edit", "x+8 yp w60", Cfg.mapStopHp)
        g.Add("Text", "xm y+12 c666666 w360", "3F3949 на screen/window — нормально для DirectX. Нужен метод dxgi (захват кадра как OBS). Если dxgi тоже врёт — закрой OBS/Xbox Game Bar и перезапусти скрипт. F9 показывает строку dxgi внизу экрана, не на HP.")
        btn := g.Add("Button", "xm y+16 w140 Default", "Сохранить")
        btn.OnEvent("Click", (*) => SettingsUi.Save(g, edHpKeys, edMpKeys, edHpPct, edMpPct, edCd, edTick, edTol, edMethod, edMapDist, edFog, edMapStop, edMove))
        g.OnEvent("Close", (*) => SettingsUi.Closed())
        g.OnEvent("Escape", (*) => SettingsUi.Closed())
        this.g := g
        g.Show()
    }

    static Save(g, edHpKeys, edMpKeys, edHpPct, edMpPct, edCd, edTick, edTol, edMethod, edMapDist, edFog, edMapStop, edMove) {
        Cfg.hpKeys := Trim(edHpKeys.Value)
        Cfg.mpKeys := Trim(edMpKeys.Value)
        Cfg.hpPct := Clamp(SafeInt(edHpPct.Value, Cfg.hpPct), 5, 95)
        Cfg.mpPct := Clamp(SafeInt(edMpPct.Value, Cfg.mpPct), 5, 95)
        Cfg.cdMs := Clamp(SafeInt(edCd.Value, Cfg.cdMs), 200, 5000)
        Cfg.tickMs := Clamp(SafeInt(edTick.Value, Cfg.tickMs), 30, 500)
        Cfg.colorTol := Clamp(SafeInt(edTol.Value, Cfg.colorTol), 30, 180)
        if edMethod.Text != ""
            Cfg.pixelMethod := edMethod.Text
        Cfg.mapClickDist := Clamp(SafeInt(edMapDist.Value, Cfg.mapClickDist), 80, 520)
        Cfg.mapFogLuma := Clamp(SafeInt(edFog.Value, Cfg.mapFogLuma), 16, 72)
        Cfg.mapStopHp := Clamp(SafeInt(edMapStop.Value, Cfg.mapStopHp), 5, 80)
        if edMove.Text != ""
            Cfg.mapMove := edMove.Text
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
        A_TrayMenu.Add("Ходьба по миникарте (F4)", (*) => Farm.Toggle())
        A_TrayMenu.Add("Калибровка миникарты (F3)", (*) => Calib.OnMap())
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
