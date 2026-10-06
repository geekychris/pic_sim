# Windows build (equivalent of `make` / `make clean` on macOS).
# Usage: powershell -ExecutionPolicy Bypass -File scripts\build.ps1 [-Clean]
param([switch]$Clean)
$ErrorActionPreference = 'Stop'

$Root   = Split-Path -Parent $PSScriptRoot
$Build  = Join-Path $Root 'build'
$Target = Join-Path $Build 'pic_sim.elf'

if ($Clean) {
    if (Test-Path $Build) { Remove-Item -Recurse -Force $Build }
    return
}

# Newest installed XC8 and PIC18Fxxxx DFP (override with $env:XC8_DIR / $env:DFP_DIR)
function Get-Newest($pattern) {
    Get-ChildItem -Directory $pattern -ErrorAction SilentlyContinue |
        Sort-Object { [version]($_.Name -replace '^v', '') } | Select-Object -Last 1
}
$Xc8Dir = if ($env:XC8_DIR) { $env:XC8_DIR } else { (Get-Newest "$env:ProgramFiles\Microchip\xc8\v*").FullName }
$DfpDir = if ($env:DFP_DIR) { $env:DFP_DIR } else { (Get-Newest "$env:USERPROFILE\.mchp_packs\Microchip\PIC18Fxxxx_DFP\*").FullName + '\xc8' }
if (-not $Xc8Dir) { throw 'XC8 not found - run scripts\setup-windows.ps1' }
if (-not (Test-Path $DfpDir)) { throw 'PIC18Fxxxx_DFP not found - run scripts\setup-windows.ps1' }

New-Item -ItemType Directory -Force -Path $Build | Out-Null
Push-Location $Root
try {
    $srcs = Get-ChildItem src\*.c | ForEach-Object { "src/$($_.Name)" }
    & "$Xc8Dir\bin\xc8-cc.exe" -mcpu=18F452 "-mdfp=$DfpDir" -O0 -gdwarf-3 -std=c99 -Wall `
        -mwarn=-3 '-msummary=-psect,-class,+mem,-hex,-file' -o $Target @srcs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
