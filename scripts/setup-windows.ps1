# One-shot Windows setup for the PIC18F452 simulator project.
#   1. MPLAB extensions for VS Code
#   2. MPLAB XC8 compiler (free mode)       -> C:\Program Files\Microchip\xc8\<ver>
#   3. PIC18Fxxxx device family pack (DFP)  -> %USERPROFILE%\.mchp_packs\Microchip\PIC18Fxxxx_DFP\<ver>
#
# Usage (from an *Administrator* PowerShell, in the repo folder):
#   powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # makes Invoke-WebRequest much faster

$Xc8Ver = 'v4.00'
$DfpVer = '1.8.178'
$Xc8Url = "https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc8-$Xc8Ver-full-install-windows-x64-installer.exe"
$DfpUrl = "https://packs.download.microchip.com/Microchip.PIC18Fxxxx_DFP.$DfpVer.atpack"
$Xc8Dir = "$env:ProgramFiles\Microchip\xc8\$Xc8Ver"
$DfpDir = "$env:USERPROFILE\.mchp_packs\Microchip\PIC18Fxxxx_DFP\$DfpVer"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Run this script from an Administrator PowerShell (needed to install XC8).' }

$Tmp = Join-Path $env:TEMP "pic_sim_setup"
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

# ---- 1. VS Code + MPLAB extensions -------------------------------------
$code = (Get-Command code -ErrorAction SilentlyContinue).Source
if (-not $code) {
    foreach ($p in @("$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
                     "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd")) {
        if (Test-Path $p) { $code = $p; break }
    }
}
if (-not $code) {
    throw 'VS Code not found. Install it from https://code.visualstudio.com (or: winget install Microsoft.VisualStudioCode)'
}
Write-Host '==> Installing MPLAB extensions for VS Code'
& $code --install-extension Microchip.mplab-extension-pack --force

# ---- 2. XC8 compiler ---------------------------------------------------
if (Test-Path "$Xc8Dir\bin\xc8-cc.exe") {
    Write-Host "==> XC8 $Xc8Ver already installed"
} else {
    Write-Host "==> Downloading XC8 $Xc8Ver"
    $exe = Join-Path $Tmp 'xc8-installer.exe'
    Invoke-WebRequest -Uri $Xc8Url -OutFile $exe -UserAgent 'Mozilla/5.0'
    Write-Host '==> Installing XC8 (unattended)'
    $p = Start-Process -FilePath $exe -Wait -PassThru -ArgumentList @(
        '--mode', 'unattended', '--unattendedmodeui', 'none', '--prefix', "`"$Xc8Dir`"")
    if ($p.ExitCode -ne 0) { throw "XC8 installer exited with code $($p.ExitCode)" }
}
& "$Xc8Dir\bin\xc8-cc.exe" --version | Select-Object -First 1

# ---- 3. Device family pack ---------------------------------------------
if (Test-Path "$DfpDir\edc\PIC18F452.PIC") {
    Write-Host "==> PIC18Fxxxx_DFP $DfpVer already installed"
} else {
    Write-Host "==> Downloading PIC18Fxxxx_DFP $DfpVer"
    $zip = Join-Path $Tmp 'dfp.zip'          # .atpack is a zip; Expand-Archive wants .zip
    Invoke-WebRequest -Uri $DfpUrl -OutFile $zip
    New-Item -ItemType Directory -Force -Path $DfpDir | Out-Null
    Expand-Archive -Path $zip -DestinationPath $DfpDir -Force
}

Remove-Item -Recurse -Force $Tmp
Write-Host ''
Write-Host 'Setup complete. Next: open this folder in VS Code, Ctrl+Shift+B to build, F5 to simulate.'
