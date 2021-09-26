:: override defaults if needed
:: configure SERVER and DEVICE
echo config %~f0

set WINSCP="C:\Program Files (x86)\WinSCP\WinSCP.com"
set putty="C:\Program Files\PuTTy\plink.exe"
set ZIPTOOL="C:\Program Files\7-Zip\7z.exe"
set TARGZTOOL="C:\Program Files\7-Zip\7z.exe"
set TORTOISEPATH="C:\Program Files\TortoiseSVN\bin"

:: SERVER
set SERVER_ADDR=
set SERVER_LOGIN=%userprofile%
set SERVER_PW=
::set SCP_SERVER_FLAGS=
::set PLINK_SERVER_FLAGS=-ssh
::set SERVER_HOSTKEY=*

:: Usually overridden by %APP%_%APP_PROFILE%_config.bat
:: DEVICE
::set DEVICE_ADDR=
::set DEVICE_LOGIN=
::set DEVICE_PW=
:: echo y for plink:
:: undefined/empty - disabled
:: "yes"/anything  - enabled
::DEVICE_ECHO_Y=yes
::set SCP_DEVICE_FLAGS=
::set PLINK_DEVICE_FLAGS=-ssh
::set DEVICE_HOSTKEY=*
