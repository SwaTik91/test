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
;  F6        калибровка HP (3 нажатия: старт → левый край → правый край)
;  F7        калибровка MP (так же)
;  F8        вкл / выкл автопотов
;  F9        цвет и координаты под курсором
;  F10       настройки
;  Shift+Esc выход
;
;  Калибруй на ПОЛНОМ HP (и MP). Банки в игре повесь на те же клавиши, что в
;  настройках скрипта (по умолчанию 1 = HP, 2 = MP).
; =============================================================================

Cfg.Load()
Overlay.Init()
TrayMenu.Init()
SetTimer(() => AutoPots.Tick(), Cfg.tickMs)
TrayTip("Hero Siege AutoPots", "F8 — вкл/выкл   F6 — калибровка HP   F10 — настройки", "Iconi")

F6:: Calib.OnHp()
F7:: Calib.OnMp()
F8:: AutoPots.Toggle()
F9:: Probe.Show()
F10:: SettingsUi.Show()
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
    static calibratedHp := false
    static calibratedMp := false
    static hpX1 := 0.36, hpY1 := 0.93, hpX2 := 0.49, hpY2 := 0.93, hpFill := 0xC42B2B
    static mpX1 := 0.51, mpY1 := 0.93, mpX2 := 0.64, mpY2 := 0.93, mpFill := 0x2B6EC4

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
            c := PixelGetColor(x, y, Cfg.pixelMode)
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
        return PixelGetColor(x, y, Cfg.pixelMode)
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
            Overlay.Hint("Сначала откалибруй HP-бар клавишей F6 (на полном здоровье)")
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
            Overlay.Hint("Автопоты ВКЛ")
        } else {
            SoundBeep(420, 90)
            Overlay.Hint("Автопоты ВЫКЛ")
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

        if this.mode = "" || (this.mode != start && this.mode != mid) {
            if !Game.IsActive() {
                Overlay.Hint("Сначала кликни по окну Hero Siege, потом жми " (which = "hp" ? "F6" : "F7"))
                return
            }
            this.mode := start
            Overlay.Hint(label ": наведи на ЛЕВЫЙ край полоски и нажми ту же клавишу")
            SoundBeep(620, 70)
            return
        }
        if !Game.IsActive() {
            Overlay.Hint("Окно Hero Siege должно быть активным")
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
            Overlay.Hint(label ": наведи на ПРАВЫЙ край полоски и нажми ту же клавишу")
            SoundBeep(720, 70)
            return
        }
        if which = "hp" {
            Cfg.hpX2 := relX, Cfg.hpY2 := relY
            Cfg.hpFill := Bar.SampleFill("hp")
            Cfg.calibratedHp := true
        } else {
            Cfg.mpX2 := relX, Cfg.mpY2 := relY
            Cfg.mpFill := Bar.SampleFill("mp")
            Cfg.calibratedMp := true
        }
        Cfg.Save()
        this.mode := ""
        fill := (which = "hp") ? Cfg.hpFill : Cfg.mpFill
        Overlay.Hint(label " сохранён, цвет " Col.Hex(fill) "  (калибруй на полном " label ")")
        SoundBeep(940, 110)
    }
}

; -----------------------------------------------------------------------------
;  Отладка пикселя
; -----------------------------------------------------------------------------

class Probe {
    static Show() {
        MouseGetPos(&x, &y)
        c := PixelGetColor(x, y, Cfg.pixelMode)
        extra := ""
        if Game.IsActive() {
            Game.ClientSize(&w, &h)
            extra := Format("  rel={:.3f},{:.3f}", x / w, y / h)
        }
        msg := Format("xy={},{}{}  {}  R={} G={} B={}", x, y, extra, Col.Hex(c), Col.R(c), Col.G(c), Col.B(c))
        ToolTip(msg)
        Overlay.Hint(msg)
        SetTimer(() => ToolTip(), -2500)
    }
}

; -----------------------------------------------------------------------------
;  Оверлей
; -----------------------------------------------------------------------------

class Overlay {
    static g := 0
    static txt := 0
    static hint := ""
    static hintUntil := 0

    static Init() {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        g.BackColor := "0C0C14"
        g.MarginX := 10
        g.MarginY := 8
        g.SetFont("s10 c00E676", "Segoe UI")
        this.txt := g.Add("Text", "w300 h70", "Hero Siege AutoPots`nвыкл")
        g.Show("x16 y16 NoActivate")
        WinSetTransparent(200, g.Hwnd)
        this.g := g
    }

    static Hint(msg) {
        this.hint := msg
        this.hintUntil := A_TickCount + 3500
        this.Refresh()
    }

    static Refresh() {
        if !this.txt
            return
        if this.hint != "" && A_TickCount < this.hintUntil {
            this.txt.Value := this.hint
            return
        }
        this.hint := ""
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
        g.Add("Text", "xm y+14 c666666 w360", "Если банки не жмутся в полноэкранной игре — запусти скрипт от администратора. PixelMode=Slow в ini, если цвет всегда 0x000000.")
        btn := g.Add("Button", "xm y+16 w140 Default", "Сохранить")
        btn.OnEvent("Click", (*) => SettingsUi.Save(g, edHpKeys, edMpKeys, edHpPct, edMpPct, edCd, edTick, edTol))
        g.OnEvent("Close", (*) => SettingsUi.Closed())
        g.OnEvent("Escape", (*) => SettingsUi.Closed())
        this.g := g
        g.Show()
    }

    static Save(g, edHpKeys, edMpKeys, edHpPct, edMpPct, edCd, edTick, edTol) {
        Cfg.hpKeys := Trim(edHpKeys.Value)
        Cfg.mpKeys := Trim(edMpKeys.Value)
        Cfg.hpPct := Clamp(SafeInt(edHpPct.Value, Cfg.hpPct), 5, 95)
        Cfg.mpPct := Clamp(SafeInt(edMpPct.Value, Cfg.mpPct), 5, 95)
        Cfg.cdMs := Clamp(SafeInt(edCd.Value, Cfg.cdMs), 200, 5000)
        Cfg.tickMs := Clamp(SafeInt(edTick.Value, Cfg.tickMs), 30, 500)
        Cfg.colorTol := Clamp(SafeInt(edTol.Value, Cfg.colorTol), 30, 180)
        Cfg.Save()
        SetTimer(() => AutoPots.Tick(), Cfg.tickMs)
        Overlay.Hint("Настройки сохранены")
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
