:: ********************************************************
:: commands
::
:: 1.3.2020 by Tuomas Lahtinen for whatever
::: Reusable commands file
::: usage call commands funclabel ...
:::
::: Thanks to Mika Rajala for the base of the scripts
::: and spark to modularize batch scripting
::
:: ********************************************************

@echo off

:: proof of concept
:: thanks to dbenham@dostips.com
:: https://www.dostips.com/forum/viewtopic.php?t=1626

:: filename = commands.cmd
call :%*
exit /b

:f1
echo:
echo called f1
echo arg1=%1
echo arg2=%2
exit /b

:: end proof of concept

:: setup tools, addresses and passwords
:: Parameters:
::: %1 user_config.bat override file tries (%userprofile%\documents\configs\%APP%_user_config.bat)
:set_env
	set arg1="%1"

	if not exist %userprofile%\documents\logs mkdir %userprofile%\documents\logs
	for /f "tokens=1" %%a in ('powershell -c "get-date -format yyyyMMdd"') do @set LOGDATE=%%a
	set WINSCP_LOG=%userprofile%\Documents\logs\winscp%LOGDATE%.log
	:: somehow best i could muster all empty checking if variants seem to fail
	:: so comment out file creation or nul setting
	
	::: either log
	::if not exist %WINSCP_LOG% echo %WINSCP_LOG% > %WINSCP_LOG%
	::set WINSCP_REDIRECT=">> %WINSCP_LOG%"
	::: or dont
	set WINSCP_REDIRECT=">nul"
	::: both are silent
	
	set WINSCP="C:\Program Files (x86)\WinSCP\WinSCP.com"
	set putty="C:\Program Files\PuTTy\plink.exe"
	
	set ZIPTOOL="C:\Program Files\7-Zip\7z.exe"
	set TARGZTOOL="C:\Program Files\7-Zip\7z.exe"
	
	set TORTOISEREV="C:\Program Files\TortoiseSVN\bin\SubWCRev.exe"

	set PLINK_TARGET_FLAGS=-ssh -batch
	set PLINK_SERVER_FLAGS=-ssh -no-antispoof
	
	:: the following variables needs to set 
	:: here or in arg1/%APP%_user_config.bat
	set SERVER_PW=
	set DEVICE_PW=
	set SERVER_HOSTKEY=*
	set DEVICE_HOSTKEY=*
	set SERVER_LOGIN=%USERNAME%
	set DEVICE_LOGIN=
	set SERVER_ADDR=
	set DEVICE_ADDR=
	echo read configuration
	:: user_config overrides for tools
	::: e.g. for tools relocation and hiding passwords
	if not exist %arg1% (
		echo defaults %userprofile%\documents\configs\%APP%_user_config.bat
		if exist %userprofile%\documents\configs\%APP%_user_config.bat call %userprofile%\documents\configs\%APP%_user_config.bat
	) else (
		echo given argument %arg1%
		if exist %arg1% call %arg1%
	)

	if not "%DEVICE_PW%"=="" (
		echo set device pw
		set DEVICE_OPT_PW=-pw %DEVICE_PW%
		set DEVICE_SCP_PW=:%DEVICE_PW%
	)
	if not "%SERVER_PW%"=="" (
		echo set server pw
		set SERVER_OPT_PW=-pw %SERVER_PW%
		set SERVER_SCP_PW=:%SERVER_PW%
	)
	
	set SERVER_PROFILE_PLINK=%SERVER_ADDR% -l %SERVER_LOGIN% %SERVER_OPT_PW%
	set SERVER_PROFILE_SCP=scp://%USERNAME%%SERVER_SCP_PW%@%SERVER_ADDR% -hostkey=%SERVER_HOSTKEY%

	set DEVICE_PROFILE_PLINK=%DEVICE_ADDR% -l %DEVICE_LOGIN% %DEVICE_OPT_PW%
	set DEVICE_PROFILE_SCP=scp://%DEVICE_LOGIN%%DEVICE_SCP_PW%@%DEVICE_ADDR% -hostkey=%DEVICE_HOSTKEY%
	exit /b %ERRORLEVEL%

:print_env
echo "*** SERVER_PLINK %SERVER_PROFILE_PLINK%"
echo "*** SERVER_SCP   %SERVER_PROFILE_SCP%"
echo "*** DEVICE_PLINK %DEVICE_PROFILE_PLINK%"
echo "*** DEVICE_SCP   %DEVICE_PROFILE_SCP%"
exit /b %ERRORLEVEL%

:: Parameters
::: %1 remote plink profile
::: %2 command line to be executed
:plink_exec_cmd_remote
	::echo %putty% %~1 %~2
	%putty% %~1 %~2
	exit /b %ERRORLEVEL%

:: Execute commands at SERVER_PROFILE_PLINK
:: Parameters
::: %1 command line to be executed
:exec_cmd_server
	set arg1=%1
	call plink_exec_cmd_remote "%SERVER_PROFILE_PLINK% %PLINK_SERVER_FLAGS%" %arg1%
	exit /b %ERRORLEVEL%

:: Execute commands at DEVICE_PROFILE_PLINK
:: Parameters
::: %1 command line to be executed	
:exec_cmd_target
	set arg1=%1
	call :plink_exec_cmd_remote "%DEVICE_PROFILE_PLINK% %PLINK_DEVICE_FLAGS%" %arg1%
	exit /b %ERRORLEVEL%
	
:: Parameters
::: %1 = the remote scp profile e.g. "scp://%DEVICE_LOGIN%:%DEVICE_PW%@%DEVICE_ADDR% -hostkey=*"
::: %2 = the file to be transferred
::: %3 = the remote target folder
:scp_put_files
	if not exist %2 goto src_transfer_error
		echo *** uploading files %~1 ...
		::echo "(%WINSCP% /command "open %~1" "put %~f2 %3" "exit") %WINSCP_REDIRECT:"=%"
		(%WINSCP% /command "open %~1" "put %~f2 %3" "exit") %WINSCP_REDIRECT:"=%
		exit /b %ERRORLEVEL%
	:src_transfer_error
	echo *** error: Source package %2 not found
	exit /b 1

:: Parameters
::: %1 = the remote scp profile e.g. "scp://%DEVICE_LOGIN%:%DEVICE_PW%@%DEVICE_ADDR% -hostkey=*"
::: %2 = the file(s) to be transferred
::: %3 = the local target folder
:scp_get_files
	echo *** downloading files %~1 ...
	::echo *** %WINSCP% /command "open %~1" "get %~2 %~f3" "exit"
	(%WINSCP% /command "open %~1" "get %~2 %~f3" "exit") %WINSCP_REDIRECT:"=%
	exit /b %ERRORLEVEL%

:: Parameter %1 = the folder to be created
:mkdir_local
	if not exist %1 mkdir %1
	exit /b %ERRORLEVEL%
	
:: Parameter %1 = server profile for putty eg. "%DEVICE_ADDR% -l %DEVICE_LOGIN% -pw %DEVICE_PW%"
:: Parameter %2 = remote folder to be created
:mkdir_remote
	call plink_cmd_remote %1 "mkdir -p %2"
	exit /b %ERRORLEVEL%

:: No parameters
:cleanup_local
	if exist %LOCAL_BINPATH% rmdir /s /q %LOCAL_BINPATH%
	exit /b %ERRORLEVEL%
	