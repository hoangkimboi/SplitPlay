# ============================================================
# SplitPlay - Auto Setup Script (Chay bang quyen Admin)
# ============================================================
$ErrorActionPreference = "Continue"
$ProjectPath = "C:\Users\Admin\Downloads\SplitPlay"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-WARN($msg) { Write-Host "    [!!] $msg" -ForegroundColor Yellow }

Write-Host "╔══════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   SplitPlay - Auto Build Setup   ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════╝" -ForegroundColor Magenta

# BUOC 1: Bat WSL2 features
Write-Step "BUOC 1: Bat WSL2 + VirtualMachinePlatform..."
try {
    $r1 = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart 2>$null
    $r2 = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart 2>$null
    if ($r1.RestartNeeded -or $r2.RestartNeeded) {
        Write-WARN "Can restart! Dang tao scheduled task de tiep tuc sau restart..."
        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$ProjectPath\setup_auto.ps1`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        Register-ScheduledTask -TaskName "SplitPlaySetup" -Action $action -Trigger $trigger `
            -RunLevel Highest -Force | Out-Null
        Write-OK "Task da tao. May tinh se restart va tu dong tiep tuc."
        Start-Sleep 3; Restart-Computer -Force; exit
    }
    Write-OK "WSL2 features OK (khong can restart)"
} catch { Write-WARN "Co the da bat roi: $_" }

# BUOC 2: WSL default version 2
Write-Step "BUOC 2: Set WSL default version = 2..."
wsl --set-default-version 2 2>&1 | Out-Null
Write-OK "WSL2 da set"

# BUOC 3: Cai Ubuntu
Write-Step "BUOC 3: Cai Ubuntu 22.04..."
$list = wsl --list --quiet 2>&1
if ("$list" -match "Ubuntu") {
    Write-OK "Ubuntu da co san!"
} else {
    Write-WARN "Dang cai Ubuntu 22.04 (mat 5-10 phut)..."
    wsl --install -d Ubuntu-22.04 --no-launch 2>&1
    Write-OK "Ubuntu da cai"
}

# BUOC 4: Tao WSL bash script
Write-Step "BUOC 4: Tao Theos build script..."
$wslScript = @'
#!/bin/bash
set -e
LOG="/tmp/splitplay_build.log"
exec > >(tee -a "$LOG") 2>&1
step() { echo -e "\n\033[36m==> $1\033[0m"; }
ok()   { echo -e "    \033[32m[OK] $1\033[0m"; }

step "1. Cap nhat apt va cai dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl git build-essential fakeroot \
    libxml2 libxml2-dev dpkg-dev perl python3 rsync unzip xz-utils

step "2. Cai Theos..."
export THEOS=~/theos
if [ ! -d "$THEOS" ]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)" || \
    git clone --recursive https://github.com/theos/theos.git $THEOS
fi
grep -q "THEOS" ~/.bashrc || echo 'export THEOS=~/theos
export PATH=$THEOS/bin:$PATH' >> ~/.bashrc
export PATH=$THEOS/bin:$PATH
ok "Theos OK"

step "3. Cai iOS 16.5 SDK..."
SDK_DIR="$THEOS/sdks"
mkdir -p "$SDK_DIR"
if [ ! -d "$SDK_DIR/iPhoneOS16.5.sdk" ]; then
    curl -L --progress-bar \
        "https://github.com/theos/sdks/releases/download/1700/iPhoneOS16.5.sdk.tar.xz" \
        -o /tmp/sdk.tar.xz
    tar -xf /tmp/sdk.tar.xz -C "$SDK_DIR"
    rm /tmp/sdk.tar.xz
fi
ok "SDK OK"

step "4. Copy va build project..."
PROJ_WIN="/mnt/c/Users/Admin/Downloads/SplitPlay/tweak"
PROJ_WSL="$HOME/SplitPlay"
[ -d "$PROJ_WSL" ] && rm -rf "$PROJ_WSL"
cp -r "$PROJ_WIN" "$PROJ_WSL"
cd "$PROJ_WSL"
make clean 2>/dev/null || true
make package FINALPACKAGE=1

step "5. Copy .deb ve Windows..."
DEB=$(ls packages/*.deb 2>/dev/null | head -1)
if [ -n "$DEB" ]; then
    mkdir -p "/mnt/c/Users/Admin/Downloads/SplitPlay/output"
    cp "$DEB" "/mnt/c/Users/Admin/Downloads/SplitPlay/output/"
    ok "BUILD THANH CONG!"
    ls -lh "/mnt/c/Users/Admin/Downloads/SplitPlay/output/"
else
    echo "BUILD THAT BAI! Xem log: $LOG"; exit 1
fi
'@
$wslScript | Set-Content -Path "$ProjectPath\setup_wsl.sh" -Encoding UTF8 -NoNewline
Write-OK "WSL script da tao"

# BUOC 5: Chay trong WSL
Write-Step "BUOC 5: Chay Theos setup + Build trong WSL (10-20 phut)..."
Write-Host "    Dang chay, vui long doi..." -ForegroundColor Yellow
$wslPath = "/mnt/c/Users/Admin/Downloads/SplitPlay/setup_wsl.sh"
wsl -d Ubuntu-22.04 -- bash -c "chmod +x '$wslPath' && bash '$wslPath'"

# Kiem tra ket qua
$deb = Get-ChildItem "$ProjectPath\output\*.deb" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($deb) {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║   BUILD HOAN TAT THANH CONG!  OK    ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "  File : $($deb.FullName)" -ForegroundColor White
    Write-Host "  Size : $([math]::Round($deb.Length/1KB,1)) KB" -ForegroundColor White
    Write-Host ""
    Write-Host "  BUOC TIEP THEO - Cai len iPhone:" -ForegroundColor Cyan
    Write-Host "  1. Mo Ubuntu (Start -> Ubuntu)" -ForegroundColor White
    Write-Host "  2. scp /mnt/c/Users/Admin/Downloads/SplitPlay/output/*.deb root@<IP>:/var/tmp/" -ForegroundColor Yellow
    Write-Host "  3. ssh root@<IP> (password: alpine)" -ForegroundColor Yellow
    Write-Host "  4. dpkg -i /var/tmp/*.deb && ldrestart" -ForegroundColor Yellow
} else {
    Write-Host "  [!!] Khong tim thay .deb. Xem log:" -ForegroundColor Red
    wsl -d Ubuntu-22.04 -- bash -c "tail -30 /tmp/splitplay_build.log 2>/dev/null"
}
Write-Host ""
Read-Host "Nhan Enter de dong..."
