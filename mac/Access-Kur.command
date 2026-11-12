#!/bin/bash
# Access Kur: installs UTM, Windows 11 (Arm64) and Microsoft Word/Excel/Access
# on an Apple Silicon Mac, fully unattended. Double-click to run.
#
# What it does:
#   1. Installs UTM (free, open source: github.com/utmapp/UTM) if missing.
#   2. Finds a Windows 11 Arm64 ISO in Downloads (or opens Microsoft's download page and waits).
#   3. Builds a small "setup" disc: unattended Windows answer file + UTM drivers + Office installer.
#   4. Creates the virtual machine in UTM and starts it. Windows and Office then install by themselves.

set -u

VM_NAME="Windows (Access)"
WORK="${ACCESS_WORK:-$HOME/Access-Windows}"
MS_PAGE="https://www.microsoft.com/tr-tr/software-download/windows11arm64"
UTM_DMG_URL="https://github.com/utmapp/UTM/releases/latest/download/UTM.dmg"
GUEST_TOOLS_URL="https://getutm.app/downloads/utm-guest-tools-latest.iso"
WIN_USER="Ogrenci"
WIN_PASS="access"

mkdir -p "$WORK"
LOG="$WORK/kurulum.log"
exec > >(tee -a "$LOG") 2>&1

step() { printf '\n==> %s\n' "$*"; }

dialog() {
  osascript - "$1" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  display dialog (item 1 of argv) buttons {"Tamam"} default button 1 with title "Access Kurulumu" with icon note
end run
APPLESCRIPT
}

die() {
  echo "HATA: $*"
  osascript - "$*" "$LOG" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  display dialog ("Kurulum durdu:" & return & return & (item 1 of argv) & return & return & "Ayrıntılar: " & (item 2 of argv)) buttons {"Tamam"} default button 1 with title "Access Kurulumu" with icon stop
end run
APPLESCRIPT
  exit 1
}

utm_has_vm() {
  osascript - "$VM_NAME" <<'APPLESCRIPT' 2>/dev/null
on run argv
  tell application "UTM"
    repeat with v in virtual machines
      if name of v is (item 1 of argv) then return "yes"
    end repeat
  end tell
  return "no"
end run
APPLESCRIPT
}

make_desktop_launcher() {
  local app="$HOME/Desktop/Windows (Access).app"
  rm -rf "$app"
  osacompile -o "$app" -e "tell application \"UTM\"
  activate
  try
    start virtual machine \"$VM_NAME\"
  end try
end tell" >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------- 0. checks
step "Mac kontrol ediliyor"
[ "$(uname -m)" = "arm64" ] || die "Bu Mac Intel işlemcili. Bu kurulum sadece M1/M2/M3/M4 (Apple Silicon) Mac'lerde çalışır."

find_iso() {
  local d
  for d in "$HOME/Downloads" "$HOME/Desktop" "$(cd "$(dirname "$0")" 2>/dev/null && pwd)" "$WORK"; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 -type f -iname '*arm64*.iso' -size +3G 2>/dev/null
  done | head -1
}

ISO="${ACCESS_ISO:-$(find_iso)}"
need_gb=30
[ -z "$ISO" ] && need_gb=37
free_gb=$(df -g "$HOME" | awk 'NR==2 {print $4}')
echo "Boş alan: ${free_gb} GB (gereken: ${need_gb} GB)"
[ -n "${DRY_RUN:-}" ] || [ "$free_gb" -ge "$need_gb" ] || die "Mac'te yeterli boş alan yok: ${free_gb} GB boş, en az ${need_gb} GB gerekiyor. Biraz yer açıp tekrar çift tıkla."

# ---------------------------------------------------------------- 1. UTM
if [ -z "${DRY_RUN:-}" ]; then
step "UTM kontrol ediliyor"
if [ -d /Applications/UTM.app ] || [ -d "$HOME/Applications/UTM.app" ]; then
  echo "UTM zaten kurulu."
else
  echo "UTM indiriliyor (~300 MB)..."
  curl -fL --retry 3 -o "$WORK/UTM.dmg" "$UTM_DMG_URL" || die "UTM indirilemedi. İnternet bağlantını kontrol et."
  mnt="$WORK/utm-mnt"; mkdir -p "$mnt"
  hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$WORK/UTM.dmg" >/dev/null || die "UTM dosyası açılamadı."
  dest=/Applications; [ -w /Applications ] || { dest="$HOME/Applications"; mkdir -p "$dest"; }
  ditto "$mnt/UTM.app" "$dest/UTM.app" || { hdiutil detach "$mnt" -quiet; die "UTM kurulamadı."; }
  hdiutil detach "$mnt" -quiet
  rm -f "$WORK/UTM.dmg"
  echo "UTM kuruldu: $dest/UTM.app"
fi

dialog "Birazdan Mac \"Terminal, UTM'i denetlemek istiyor\" diye sorabilir.

Lütfen \"İzin Ver\" / \"Tamam\" de. Bu izin olmadan kurulum Windows'u oluşturamaz."
open -a UTM
sleep 5

if [ "$(utm_has_vm)" = "yes" ]; then
  make_desktop_launcher
  osascript -e "tell application \"UTM\" to start virtual machine \"$VM_NAME\"" >/dev/null 2>&1
  dialog "Windows (Access) zaten kurulu, açıyorum.

Bundan sonra masaüstündeki \"Windows (Access)\" simgesiyle açabilirsin."
  exit 0
fi
fi # DRY_RUN

# ---------------------------------------------------------------- 2. Windows ISO
step "Windows 11 (Arm64) dosyası aranıyor"
if [ -z "$ISO" ]; then
  open "$MS_PAGE"
  dialog "Windows dosyasını Microsoft'tan indirmen gerekiyor (~6 GB). Açılan sayfada:

1. \"Windows 11 (Arm64 için çok sürümlü ISO)\" seç → İndir
2. Dil: Türkçe → Onayla
3. \"İndir\" butonuna bas

İndirme bitince kurulum KENDİLİĞİNDEN devam edecek. Bu Terminal penceresini kapatma."
  echo "İndirmenin bitmesi bekleniyor (İndirilenler klasörü izleniyor)..."
  last=-1
  while :; do
    ISO="$(find_iso)"
    if [ -n "$ISO" ]; then
      size=$(stat -f %z "$ISO")
      [ "$size" = "$last" ] && break
      last=$size
    fi
    sleep 15
  done
fi
echo "Windows dosyası: $ISO"

wmnt="$WORK/win-mnt"; mkdir -p "$wmnt"
hdiutil attach -nobrowse -readonly -mountpoint "$wmnt" "$ISO" >/dev/null || die "Windows dosyası açılamadı, bozuk inmiş olabilir. Silip tekrar indir."
[ -f "$wmnt/efi/boot/bootaa64.efi" ] || { hdiutil detach "$wmnt" -quiet; die "Bu Windows dosyası Arm64 sürümü değil. Microsoft'un Arm64 sayfasından indirmelisin: $MS_PAGE"; }
LANG_TAG=$(awk '/Available UI Languages/{f=1; next} /^\[/{f=0} f && /=/{gsub(/[ \r]/,""); split($0,a,"="); print a[1]; exit}' "$wmnt/sources/lang.ini" 2>/dev/null)
hdiutil detach "$wmnt" -quiet
[ -n "$LANG_TAG" ] || LANG_TAG="en-us"
echo "Windows dili: $LANG_TAG"

# ---------------------------------------------------------------- 3. setup disc
step "Otomatik kurulum diski hazırlanıyor"
SETUP="$WORK/setup"
rm -rf "$SETUP"; mkdir -p "$SETUP/Drivers"

curl -fL --retry 3 -o "$WORK/guest-tools.iso" "$GUEST_TOOLS_URL" || die "UTM sürücüleri indirilemedi. İnternet bağlantını kontrol et."
gmnt="$WORK/gt-mnt"; mkdir -p "$gmnt"
hdiutil attach -nobrowse -readonly -mountpoint "$gmnt" "$WORK/guest-tools.iso" >/dev/null || die "UTM sürücü dosyası açılamadı."
cp "$gmnt"/utm-guest-tools-*.exe "$SETUP/utm-guest-tools.exe" || { hdiutil detach "$gmnt" -quiet; die "UTM sürücü kurulumu bulunamadı."; }
for d in NetKVM viostor vioscsi vioserial Balloon; do
  [ -d "$gmnt/Drivers/$d/w11/ARM64" ] && { mkdir -p "$SETUP/Drivers/$d"; cp -R "$gmnt/Drivers/$d/w11/ARM64" "$SETUP/Drivers/$d/"; }
done
hdiutil detach "$gmnt" -quiet
rm -f "$WORK/guest-tools.iso"

driver_paths=""
k=1
for letter in D E F G H; do
  for d in NetKVM viostor vioscsi vioserial Balloon; do
    driver_paths+="                <PathAndCredentials wcm:action=\"add\" wcm:keyValue=\"$k\"><Path>${letter}:\\Drivers\\${d}\\ARM64</Path></PathAndCredentials>
"
    k=$((k+1))
  done
done

cat > "$SETUP/autounattend.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage><UILanguage>${LANG_TAG}</UILanguage></SetupUILanguage>
            <InputLocale>041f:0000041f;0409:00000409</InputLocale>
            <SystemLocale>tr-TR</SystemLocale>
            <UILanguage>${LANG_TAG}</UILanguage>
            <UserLocale>tr-TR</UserLocale>
        </component>
        <component name="Microsoft-Windows-PnpCustomizationsWinPE" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <DriverPaths>
${driver_paths}            </DriverPaths>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <Diagnostics><OptIn>false</OptIn></Diagnostics>
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add"><Order>1</Order><Path>reg add HKLM\System\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add"><Order>2</Order><Path>reg add HKLM\System\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add"><Order>3</Order><Path>reg add HKLM\System\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add"><Order>4</Order><Path>reg add HKLM\System\Setup\LabConfig /v BypassCPUCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
            </RunSynchronous>
            <DiskConfiguration>
                <WillShowUI>OnError</WillShowUI>
                <Disk wcm:action="add">
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                    <CreatePartitions>
                        <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>300</Size></CreatePartition>
                        <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
                        <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
                        <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label><Letter>C</Letter></ModifyPartition>
                    </ModifyPartitions>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
                    <WillShowUI>OnError</WillShowUI>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
                <ProductKey><Key>VK7JG-NPHTM-C97JM-9MPGT-3V66T</Key><WillShowUI>OnError</WillShowUI></ProductKey>
            </UserData>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>ACCESS-PC</ComputerName>
            <TimeZone>Turkey Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-Deployment" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add"><Order>1</Order><Path>reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>041f:0000041f;0409:00000409</InputLocale>
            <SystemLocale>tr-TR</SystemLocale>
            <UILanguage>${LANG_TAG}</UILanguage>
            <UserLocale>tr-TR</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="arm64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>${WIN_USER}</Name>
                        <Group>Administrators</Group>
                        <Password><Value>${WIN_PASS}</Value><PlainText>true</PlainText></Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Enabled>true</Enabled>
                <Username>${WIN_USER}</Username>
                <Password><Value>${WIN_PASS}</Value><PlainText>true</PlainText></Password>
                <LogonCount>9999</LogonCount>
            </AutoLogon>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>Kurulum (surucu + Office)</Description>
                    <CommandLine>cmd /c for %i in (D E F G H I J) do @if exist %i:\kurulum.cmd call %i:\kurulum.cmd</CommandLine>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
XML

cat > "$SETUP/office.xml" <<'XML'
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="tr-tr" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="Outlook" />
      <ExcludeApp ID="PowerPoint" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
      <ExcludeApp ID="Bing" />
    </Product>
  </Add>
  <Updates Enabled="TRUE" />
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
XML

cat > "$SETUP/kurulum.cmd" <<CMD
@echo off
title Office kuruluyor - bu pencereyi kapatma
echo.
echo  Suruculer, Word, Excel ve Access kuruluyor. Bu 15-30 dakika surebilir.
echo  Bu pencereyi KAPATMA, bitince kendisi kapanacak.
echo.
set SRC=%~dp0
if not exist C:\OEM mkdir C:\OEM
copy /y "%SRC%office.xml" C:\OEM\ >nul

rem UTM drivers + SPICE agent (clipboard, screen size, network)
"%SRC%utm-guest-tools.exe" /S

powercfg /h off
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d ${WIN_USER} /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d ${WIN_PASS} /f >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoLogonCount /f >nul 2>&1

set ODT=C:\OEM\setup.exe
set TRIES=0
:download
set /a TRIES+=1
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing -Uri 'https://officecdn.microsoft.com/pr/wsus/setup.exe' -OutFile 'C:\OEM\setup.exe'; exit 0 } catch { exit 1 }"
if exist "%ODT%" goto install
if %TRIES% GEQ 40 goto failed
timeout /t 15 /nobreak >nul
goto download

:install
"%ODT%" /configure C:\OEM\office.xml

set ACCESS=C:\Program Files\Microsoft Office\root\Office16\MSACCESS.EXE
if not exist "%ACCESS%" goto failed
powershell -NoProfile -ExecutionPolicy Bypass -Command "\$s=(New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\Access.lnk'); \$s.TargetPath='%ACCESS%'; \$s.Save()"
exit /b 0

:failed
echo Office kurulamadi. > "C:\Users\Public\Desktop\OFFICE KURULAMADI - OKU.txt"
echo Internete baglan ve C:\OEM klasorundeki kurulum.cmd dosyasina cift tikla. >> "C:\Users\Public\Desktop\OFFICE KURULAMADI - OKU.txt"
copy /y "%~f0" C:\OEM\kurulum.cmd >nul
exit /b 1
CMD
perl -pi -e 's/\n/\r\n/' "$SETUP/kurulum.cmd" "$SETUP/office.xml" "$SETUP/autounattend.xml"

rm -f "$WORK/kurulum.iso"
hdiutil makehybrid -iso -joliet -default-volume-name KURULUM -o "$WORK/kurulum.iso" "$SETUP" >/dev/null || die "Kurulum diski oluşturulamadı."
echo "Kurulum diski hazır: $WORK/kurulum.iso"

# ---------------------------------------------------------------- 4. VM
if [ -n "${DRY_RUN:-}" ]; then echo "DRY_RUN: sanal makine olusturulmadi"; exit 0; fi
step "Sanal makine oluşturuluyor"
mem_mb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 2 ))
[ "$mem_mb" -gt 8192 ] && mem_mb=8192
[ "$mem_mb" -lt 4096 ] && mem_mb=4096
cores=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo 4)
echo "Bellek: ${mem_mb} MB, işlemci: ${cores} çekirdek, disk: 64 GB (sadece kullanılan kadar yer kaplar)"

osascript - "$ISO" "$WORK/kurulum.iso" "$VM_NAME" "$mem_mb" "$cores" <<'APPLESCRIPT' || die "UTM sanal makineyi oluşturamadı. Terminal'in UTM'i denetleme iznini kontrol et (Sistem Ayarları → Gizlilik ve Güvenlik → Otomasyon)."
on run argv
  set winIso to POSIX file (item 1 of argv)
  set setupIso to POSIX file (item 2 of argv)
  set vmName to item 3 of argv
  set memMB to (item 4 of argv) as integer
  set nCores to (item 5 of argv) as integer
  tell application "UTM"
    set vm to make new virtual machine with properties {backend:qemu, configuration:{name:vmName, architecture:"aarch64", memory:memMB, cpu cores:nCores, hypervisor:true, uefi:true, drives:{{removable:true, interface:USB, source:winIso}, {removable:true, interface:USB, source:setupIso}, {interface:NVMe, guest size:65536}}, network interfaces:{{hardware:"virtio-net-pci", mode:shared}}, displays:{{hardware:"virtio-ramfb"}}}}
    start vm
    -- Windows asks "Press any key to boot from CD" once; keep tapping space for a while.
    repeat 30 times
      delay 1
      try
        input keystroke vm text " "
      end try
    end repeat
  end tell
end run
APPLESCRIPT

make_desktop_launcher

dialog "Windows kuruluyor! 🎉

UTM penceresinde Windows kendi kendine kuruluyor, sonra Word, Excel ve Access yükleniyor. Toplam 45-60 dakika sürer. Hiçbir şeye basma, Mac'i kapatma (şarja tak).

Bitince Windows masaüstünde \"Access\" simgesi olacak. Açıp okul hesabınla gir: öğrencino@emu.edu.tr

Bundan sonra Windows'u Mac masaüstündeki \"Windows (Access)\" simgesiyle açabilirsin."
echo "Bitti. Kayıt: $LOG"
