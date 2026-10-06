# PIC18F452 Simulator Playground (VS Code + MPLAB)

Write C for a Microchip **PIC18F452** and run it in the **MPLAB Simulator** inside **VS Code**, with no hardware needed. Works on **macOS** and **Windows**.

The example program:

| Feature | Where to look |
|---|---|
| Timer0 interrupt counts up; the count shows on **PORTB** | `isr()`, `tick_count`, `LATB` |
| **RD0** toggles every time the counter wraps | `wraps`, `LATD` |
| **`glennFunction()`** sets pin **RC2** high or low, then reads the pin back into a C variable | `glennFunction()`, `glenn_value`, `PORTC` |

---

## Contents
1. [What gets installed](#1-what-gets-installed)
2. [Setup on macOS](#2-setup-on-macos)
3. [Setup on Windows](#3-setup-on-windows)
4. [Building](#4-building)
5. [Running and debugging in the simulator](#5-running-and-debugging-in-the-simulator)
6. [glennFunction: set a pin and read it back](#6-glennfunction-set-a-pin-and-read-it-back)
7. [Project layout](#7-project-layout)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. What gets installed

| Component | Purpose | macOS location | Windows location |
|---|---|---|---|
| [VS Code](https://code.visualstudio.com) | Editor and debugger UI | `/Applications/Visual Studio Code.app` | `%LOCALAPPDATA%\Programs\Microsoft VS Code` |
| **MPLAB Extensions for VS Code** (`Microchip.mplab-extension-pack`) | MPLAB debugger, simulator backend, project tools | VS Code extensions | VS Code extensions |
| **MPLAB XC8 v4.00** (free mode) | C compiler for 8-bit PICs | `/Applications/microchip/xc8/v4.00` | `C:\Program Files\Microchip\xc8\v4.00` |
| **PIC18Fxxxx_DFP 1.8.178** | Device pack: PIC18F452 headers, config bits, simulator model | `~/.mchp_packs/Microchip/PIC18Fxxxx_DFP/1.8.178` | `%USERPROFILE%\.mchp_packs\Microchip\PIC18Fxxxx_DFP\1.8.178` |

> **Note:** Microchip's integration is for **Visual Studio Code**, not full Visual Studio. The free-mode XC8 license has no time limit; it only limits optimization levels.

> **Why a separate device pack?** Since XC8 v3, device definitions are no longer bundled with the compiler. Without the pack you get `error: (2103) no device-support files specified; use the -mdfp option`. The build scripts pass `-mdfp` for you.

---

## 2. Setup on macOS

Requirements: macOS 12+ (Intel or Apple Silicon), VS Code installed, and the Xcode Command Line Tools (for `make` and `git`: `xcode-select --install`).

```bash
git clone https://github.com/geekychris/pic_sim.git
cd pic_sim
bash scripts/setup-mac.sh
```

Run the script as yourself, **not** with `sudo`. It asks for your password once, to install XC8. The script:

1. Installs the MPLAB extension pack into VS Code.
2. On Apple Silicon, installs Rosetta 2 if needed (XC8 is x86-64).
3. Downloads the XC8 v4.00 `.dmg` and installs it unattended into `/Applications/microchip/xc8/v4.00`.
4. Downloads the PIC18Fxxxx device pack and unpacks it into `~/.mchp_packs`.

You can re-run it safely: it skips anything already installed.

<details>
<summary>Manual install (if the script fails)</summary>

1. VS Code → Extensions (`Cmd+Shift+X`) → search **MPLAB** → install **MPLAB** (Microchip extension pack).
2. Download XC8 for macOS from <https://www.microchip.com/xc8>, open the `.dmg` and run the installer (accept the defaults and free mode).
3. Download `Microchip.PIC18Fxxxx_DFP.1.8.178.atpack` from <https://packs.download.microchip.com> and unzip it (it is a zip file) into
   `~/.mchp_packs/Microchip/PIC18Fxxxx_DFP/1.8.178/`.
</details>

---

## 3. Setup on Windows

Requirements: Windows 10/11 x64, VS Code installed (`winget install Microsoft.VisualStudioCode`), and Git (`winget install Git.Git`).

Open **PowerShell as Administrator** (Start → type *PowerShell* → *Run as administrator*):

```powershell
git clone https://github.com/geekychris/pic_sim.git
cd pic_sim
powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1
```

The script:

1. Installs the MPLAB extension pack into VS Code.
2. Downloads the XC8 v4.00 Windows installer and installs it unattended into `C:\Program Files\Microchip\xc8\v4.00`.
3. Downloads the PIC18Fxxxx device pack and unpacks it into `%USERPROFILE%\.mchp_packs`.

You can re-run it safely: it skips anything already installed.

<details>
<summary>Manual install (if the script fails)</summary>

1. VS Code → Extensions (`Ctrl+Shift+X`) → search **MPLAB** → install **MPLAB** (Microchip extension pack).
2. Download XC8 for Windows from <https://www.microchip.com/xc8> and run the installer (accept the defaults and free mode).
3. Download `Microchip.PIC18Fxxxx_DFP.1.8.178.atpack` from <https://packs.download.microchip.com>, rename it to `.zip`, and extract it into
   `%USERPROFILE%\.mchp_packs\Microchip\PIC18Fxxxx_DFP\1.8.178\`.
</details>

> Windows has no `make`, so builds use `scripts\build.ps1`. The VS Code build task picks the right one automatically.

---

## 4. Building

### From VS Code (both platforms)
Open the `pic_sim` folder (*File → Open Folder…*) and press **`Cmd+Shift+B`** (macOS) or **`Ctrl+Shift+B`** (Windows). Compiler errors show up in the *Problems* panel.

### From a terminal

| | macOS | Windows (PowerShell) |
|---|---|---|
| Build | `make` | `powershell -ExecutionPolicy Bypass -File scripts\build.ps1` |
| Clean | `make clean` | `powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -Clean` |
| Show toolchain paths | `make info` | n/a |

A successful build prints a memory summary and produces `build/pic_sim.elf` (for the debugger) and `build/pic_sim.hex` (for programming a real chip):

```
18F452 Memory Summary:
    Program space        used   10Ch (   268) of  8000h bytes   (  0.8%)
    Data space           used     9h (     9) of   600h bytes   (  0.6%)
```

To use a different compiler or pack version: `make XC8_DIR=/Applications/microchip/xc8/v3.10` on macOS, or set `$env:XC8_DIR` / `$env:DFP_DIR` before running `build.ps1` on Windows.

---

## 5. Running and debugging in the simulator

The launch configuration is in `.vscode/launch.json`:

```json
{
  "name": "PIC18F452 – MPLAB Simulator",
  "type": "mplab-core-da",
  "request": "launch",
  "program": "${workspaceFolder}/build/pic_sim.elf",
  "device": "PIC18F452",
  "tool": "Simulator",
  "stopOnEntry": true,
  "preLaunchTask": "build (xc8)"
}
```

### Start a session
1. Open the **Run and Debug** view (`Cmd+Shift+D` / `Ctrl+Shift+D`).
2. Choose **PIC18F452 – MPLAB Simulator** from the dropdown.
3. Press **F5**. The project builds, the simulator starts, and execution stops at entry.

> The **first** debug session is slow: the MPLAB extension downloads its debugger and simulator backend. If it asks to install a device pack or pick a tool, accept it and choose **Simulator**.

### Debug controls

| Action | Key |
|---|---|
| Continue / run | `F5` |
| Pause | `F6` |
| Step over | `F10` |
| Step into | `F11` |
| Step out | `Shift+F11` |
| Toggle breakpoint | `F9` (or click in the gutter) |
| Restart | `Cmd+Shift+F5` / `Ctrl+Shift+F5` |
| Stop | `Shift+F5` |

### Suggested first session
1. In `src/main.c`, set a breakpoint on `glenn_value = glennFunction(1);`.
2. Press **F5**, then **F5** again to run to the breakpoint.
3. Press **F11** to step *into* `glennFunction`, then **F10** line by line. Watch `level` and then `pin_value` in the **Variables** pane.
4. Step out (**Shift+F11**). `glenn_value` is now `1`.
5. Set a breakpoint on `if (tick_count != last)` and keep pressing **F5**: `tick_count` and `LATB` count up.
6. In the **Watch** pane, add `glenn_value`, `wraps`, `LATB`, `LATC`, `PORTC` and `TRISC` to watch them change. SFRs (special function registers) can be added by name.

### Memory and registers
The extension pack includes the *Memory Inspector*. While paused, you can open it from the Command Palette (`Cmd/Ctrl+Shift+P` → *Memory Inspector*) to view RAM. SFRs live at `0xF80–0xFFF` on the PIC18F452 (for example PORTC = `0xF82`, LATC = `0xF8B`, TRISC = `0xF94`).

### Simulator limitations
The VS Code simulator supports breakpoints, stepping, variables, watches and memory. **Stimulus** (scripting input pin changes over time) is not available in VS Code yet. If you need it, the same project builds in the full **MPLAB X IDE**, which has a Stimulus window.

---

## 6. glennFunction: set a pin and read it back

```c
uint8_t glennFunction(uint8_t level)
{
    uint8_t pin_value;

    TRISCbits.TRISC2 = 0;               /* RC2 = output */
    LATCbits.LATC2   = level ? 1 : 0;   /* set the pin */
    NOP();                              /* let the pin settle before sampling */
    pin_value = PORTCbits.RC2;          /* read the pin into a C variable */

    return pin_value;
}
```

- **Pin:** RC2 (pin 17 on the 40-pin DIP). PORTC has no analog functions on the PIC18F452, so the pin works as plain digital I/O with no ADC setup.
- **TRIS / LAT / PORT:** these are the three registers behind every PIC18 pin.
  - `TRISx` sets the direction (`0` = output, `1` = input).
  - `LATx` is the output latch: write here to drive the pin.
  - `PORTx` samples the physical pin: read here to see the actual level.

  Writing `LAT` and reading `PORT` reports what the pin *really* is, which on real hardware can differ from what you wrote (for example if the pin is shorted or heavily loaded).
- **Usage in `main()`:** it is called once at start-up with `1`, and then each time PORTB wraps with the opposite value, so RC2 and `glenn_value` toggle together.

To read an **input** pin instead, set `TRISCbits.TRISC2 = 1` and skip the `LAT` write. In MPLAB X you can then drive the pin with a stimulus.

---

## 7. Project layout

```
pic_sim/
├── src/main.c               # The program (ISR, counter, glennFunction)
├── Makefile                 # macOS/Linux build (xc8-cc + -mdfp)
├── scripts/
│   ├── setup-mac.sh         # macOS: extensions + XC8 + device pack
│   ├── setup-windows.ps1    # Windows: extensions + XC8 + device pack
│   └── build.ps1            # Windows build / clean
└── .vscode/
    ├── tasks.json           # Build task (make on macOS, build.ps1 on Windows)
    ├── launch.json          # MPLAB Simulator debug configuration
    └── extensions.json      # Recommends the MPLAB extension pack
```

---

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| `(2103) no device-support files specified` | The device pack is missing. Re-run the setup script, or check the `DFP_DIR` path from `make info`. |
| `(2044) unrecognized option "-g"` | XC8 v4 dropped `-g`; use `-gdwarf-3` (already done in the Makefile and `build.ps1`). |
| Red squiggles on `<xc.h>` / `__interrupt` in the editor | The editor's code checker doesn't know XC8's compiler extensions. The build is unaffected. |
| macOS: installer errors with `Unknown option: --LicenseType` | You're using an old script. XC8 v4 has no license options; use `scripts/setup-mac.sh`. |
| Windows: *running scripts is disabled on this system* | Run it with `powershell -ExecutionPolicy Bypass -File …` as shown above. |
| F5 fails with a tool or device error | Make sure `build/pic_sim.elf` exists (build first), and that the launch config says `"tool": "Simulator"` and `"device": "PIC18F452"`. Check the **Debug Console** and **Output → MPLAB** panels for details. |
| Watchdog keeps resetting the program | `WDT = OFF` is set in the config bits. If you enable it, call `CLRWDT()` in the main loop. |
