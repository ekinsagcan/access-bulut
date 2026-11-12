@echo off
rem Runs once, at the end of the automatic Windows install (dockur copies this folder to C:\OEM).
rem Shrinks Windows to save disk space, then installs Word + Excel + Access (Microsoft 365).

title Office kuruluyor - bu pencereyi kapatma
echo.
echo  Word, Excel ve Access kuruluyor. Bu 10-20 dakika surebilir.
echo  Bu pencereyi KAPATMA, bitince kendisi kapanacak.
echo.

powercfg /h off

set ODT=C:\OEM\setup.exe
set TRIES=0
:download
set /a TRIES+=1
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing -Uri 'https://officecdn.microsoft.com/pr/wsus/setup.exe' -OutFile '%ODT%'; exit 0 } catch { exit 1 }"
if exist "%ODT%" goto install
if %TRIES% GEQ 20 goto failed
timeout /t 15 /nobreak >nul
goto download

:install
"%ODT%" /configure C:\OEM\office.xml

set ACCESS=C:\Program Files\Microsoft Office\root\Office16\MSACCESS.EXE
if not exist "%ACCESS%" goto failed
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\Access.lnk'); $s.TargetPath='%ACCESS%'; $s.Save()"
echo Disk alani icin Windows sikistiriliyor (Access simdiden kullanilabilir)...
compact /compactos:always
exit /b 0

:failed
echo Office kurulamadi. > "C:\Users\Public\Desktop\OFFICE KURULAMADI - OKU.txt"
echo Internete baglanip C:\OEM\install.bat dosyasina cift tikla. >> "C:\Users\Public\Desktop\OFFICE KURULAMADI - OKU.txt"
exit /b 1
