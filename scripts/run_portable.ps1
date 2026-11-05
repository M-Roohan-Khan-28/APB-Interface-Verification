param([string]$OutputDir = 'portable-results')

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$out = if ([IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $repo $OutputDir }
New-Item -ItemType Directory -Path $out -Force | Out-Null
Push-Location $out
try {
    if (!(Test-Path work)) {
        & vlib work 2>&1 | Tee-Object -FilePath library.log
        if ($LASTEXITCODE -ne 0) { throw 'Portable library creation failed' }
    }
    & vlog -sv (Join-Path $repo 'rtl/design.sv') (Join-Path $repo 'tb/tb_portable.sv') 2>&1 | Tee-Object -FilePath compile.log
    if ($LASTEXITCODE -ne 0) { throw 'Portable compilation failed' }
    & vsim -c -onfinish exit tb_apb_portable -do 'onerror {quit -code 1}; run -all; quit -code 0' 2>&1 | Tee-Object -FilePath simulation.log
    $simExit = $LASTEXITCODE
    $log = Get-Content -Raw simulation.log
    if ($simExit -ne 0 -or
        $log -match '(?im)^\s*#?\s*\*\*\s+(Error|Fatal):' -or
        $log -notmatch 'PORTABLE_TEST_PASS APB checks=' -or
        $log -notmatch '\$finish') {
        throw "Portable APB simulation failed (vsim exit $simExit); inspect $out\simulation.log"
    }
} finally {
    Pop-Location
}
