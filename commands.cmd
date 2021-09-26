:: ********************************************************
:: commands
::
:: 1.3.2020 by Tuomas Lahtinen for whatever
::: Reusable commands file
::: usage call commands funclabel ...
:::
::: requires configuration for SERVER and DEVICE
::: for template see:  
::: https://github.com/head5man/batchlib/blob/main/_user_config.bat.template
:::
::: Thanks to Mika Rajala for the base of the scripts
::: and spark to modularize batch scripting
::
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
::: %1 definition file default:(%userprofile%\documents\configs\%APP%_%APP_PROFILE%_config.bat)
:set_env
	set arg1="%1"

	if not exist %userprofile%\documents\logs mkdir %userprofile%\documents\logs
	for /f "tokens=1" %%a in ('start /wait /b powershell -c "get-date -format yyyyMMdd"') do @set LOGDATE=%%a
	set WINSCP_LOG=%userprofile%\Documents\logs\winscp%LOGDATE%.log
	:: somehow best i could muster ... all empty checking variants seem to fail
	:: so comment out file creation or nul setting
	
	::: redirect to log
	::if not exist %WINSCP_LOG% echo %WINSCP_LOG% > %WINSCP_LOG%
	::set WINSCP_REDIRECT=">> %WINSCP_LOG%"
	::: or nul
	::: both are silent
	set WINSCP_REDIRECT=">nul"
	::: if not you get bable
	::set WINSCP_REDIRECT=""

	set PLINK_DEVICE_FLAGS=-ssh -no-antispoof
	set PLINK_SERVER_FLAGS=-ssh -no-antispoof
	set SCP_DEVICE_FLAGS=
	set SCP_SERVER_FLAGS=
	
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
	if exist %userprofile%\documents\configs\%USERNAME%_config.bat call %userprofile%\documents\configs\%USERNAME%_config.bat
	
	echo ** check tool variables
	call :check_variable "%TORTOISEPATH%" "tortoisepath empty"
	call :check_variable "%WINSCP%" "winscp empty"
	call :check_variable "%putty%" "puttytool empty"
	call :check_variable "%ZIPTOOL%" "ziptool empty"
	call :check_variable "%TARGZTOOL%" "targztool empty"

	set TORTOISEREV="%TORTOISEPATH:"=%\SubWCRev.exe"
	set SVNVERSION="%TORTOISEPATH:"=%\svnversion.exe"
	set SVNEXE="%TORTOISEPATH:"=%\svn.exe"
	
	echo ** check app config
	if not exist %arg1% (
		echo check path %userprofile%\documents\configs\
		if exist %userprofile%\documents\configs\ (
		echo check file %APP%_%APP_PROFILE%_config.bat
		if exist %userprofile%\documents\configs\%APP%_%APP_PROFILE%_config.bat (
			echo read default %APP%_%APP_PROFILE%_config.bat *
			call %userprofile%\documents\configs\%APP%_%APP_PROFILE%_config.bat
		)
	) else (
		echo check file %arg1%
		if exist %arg1%	call %arg1%
	)
	echo ** set passwords
	if not "%DEVICE_PW%"=="" (
		echo device pw
		set DEVICE_OPT_PW=-pw %DEVICE_PW%
		set DEVICE_SCP_PW=:%DEVICE_PW%
	)
	if not "%SERVER_PW%"=="" (
		echo server pw
		set SERVER_OPT_PW=-pw %SERVER_PW%
		set SERVER_SCP_PW=:%SERVER_PW%
	)
	echo ** set profiles
	echo server
	set SERVER_PROFILE_PLINK=%SERVER_ADDR% -l %SERVER_LOGIN% %SERVER_OPT_PW%
	set SERVER_PROFILE_SCP=scp://%USERNAME%%SERVER_SCP_PW%@%SERVER_ADDR%/~ -hostkey=%SERVER_HOSTKEY% %SCP_SERVER_FLAGS%
	echo device
	set DEVICE_PROFILE_PLINK=%DEVICE_ADDR% -l %DEVICE_LOGIN% %DEVICE_OPT_PW%
	set DEVICE_PROFILE_SCP=scp://%DEVICE_LOGIN%%DEVICE_SCP_PW%@%DEVICE_ADDR%/tmp -hostkey=%DEVICE_HOSTKEY% %SCP_DEVICE_FLAGS%
	exit /b %ERRORLEVEL%

:print_env
echo "*** SERVER_PLINK %SERVER_PROFILE_PLINK%"
echo "*** SERVER_SCP   %SERVER_PROFILE_SCP%"
echo "*** DEVICE_PLINK %DEVICE_PROFILE_PLINK%"
echo "*** DEVICE_SCP   %DEVICE_PROFILE_SCP%"
exit /b %ERRORLEVEL%

:: parameters
::: %1 variable
::: %2 exit code
::: %3 message
:check_variable
	set arg1=%1
	set arg3=0
	if not "%2"=="" set arg3=%2
	set test=%arg1:"=%
	if [%test%]==[] (
		call :error_exit %2 %arg3%
	)
exit /b 0

:: parameters
::: %2 code
::: %1 message
:error_exit
	echo %1
exit /b %2
	

:: Parameters
::: %1 remote plink profile
::: %2 command line to be executed
:plink_exec_cmd_remote
	if "%~3"=="" (
	%putty% %~1 %~2
	) else (
	echo y|%putty% %~1 %~2
	)
	exit /b %ERRORLEVEL%

:: Execute commands at SERVER_PROFILE_PLINK
:: Parameters
::: %1 command line to be executed
:exec_cmd_server
	set arg1=%1
	echo %arg1%
	call :plink_exec_cmd_remote "%SERVER_PROFILE_PLINK% %PLINK_SERVER_FLAGS%" %arg1%
	exit /b %ERRORLEVEL%

:: Execute commands at DEVICE_PROFILE_PLINK
:: Parameters
::: %1 command line to be executed	
:exec_cmd_target
	set arg1=%1
	echo %arg1%
	call :plink_exec_cmd_remote "%DEVICE_PROFILE_PLINK% %PLINK_DEVICE_FLAGS%" %arg1% %DEVICE_ECHO_Y%
	exit /b %ERRORLEVEL%
	
:: Parameters
::: %1 = the remote scp profile e.g. "scp://%DEVICE_LOGIN%:%DEVICE_PW%@%DEVICE_ADDR% -hostkey=*"
::: %2 = the file to be transferred
::: %3 = the remote target folder
:scp_put_files
	if not exist %2 goto src_transfer_error
		echo *** uploading files %~1 ... %2
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

:scp_put_device
	if not exist %~1 goto src_transfer_error
		echo *** uploading files %~1 ... %2
		::echo "(%WINSCP% /command "open %~1" "put %~f2 %3" "exit") %WINSCP_REDIRECT:"=%"
		(%WINSCP% /command "open %DEVICE_PROFILE_SCP%" "put %~f1 %2" "exit") %WINSCP_REDIRECT:"=%
		exit /b %ERRORLEVEL%
	:src_transfer_error
	echo *** error: Source files %1 not found
	exit /b 1

:scp_put_server
	if not exist %1 goto src_transfer_error
		echo *** uploading files %~1 ...
		::echo "(%WINSCP% /command "open %~1" "put %~f2 %3" "exit") %WINSCP_REDIRECT:"=%"
		(%WINSCP% /command "open %SERVER_PROFILE_SCP%" "put %~f1 %2" "exit") %WINSCP_REDIRECT:"=%
		exit /b %ERRORLEVEL%
	:src_transfer_error
	echo *** error: Source files %1 not found
	exit /b 1

:: Parameters
::: %1 = the remote scp profile e.g. "scp://%DEVICE_LOGIN%:%DEVICE_PW%@%DEVICE_ADDR% -hostkey=*"
::: %2 = the file(s) to be transferred
::: %3 = the local target folder
:scp_get_device
	echo *** downloading files %~1 ...
	::echo *** %WINSCP% /command "open %~1" "get %~2 %~f3" "exit"
	(%WINSCP% /command "open %DEVICE_PROFILE_SCP%" "get %~1 %~f2" "exit") %WINSCP_REDIRECT:"=%
	exit /b %ERRORLEVEL%

:scp_get_server
	echo *** downloading files %~1 ...
	::echo *** %WINSCP% /command "open %~1" "get %~2 %~f3" "exit"
	(%WINSCP% /command "open %SERVER_PROFILE_SCP%" "get %~1 %~f2" "exit") %WINSCP_REDIRECT:"=%
	exit /b %ERRORLEVEL%

:: Parameter %1 = the folder to be created
:mkdir_local
	if not exist %1 mkdir %1
	exit /b %ERRORLEVEL%
	
:: Parameter %1 = server profile for putty eg. "%DEVICE_ADDR% -l %DEVICE_LOGIN% -pw %DEVICE_PW%"
:: Parameter %2 = remote folder to be created
:mkdir_remote
	call :plink_exec_cmd_remote %1 "mkdir -p %2"
	exit /b %ERRORLEVEL%

:: No parameters
:cleanup_local
	if exist %LOCAL_BINPATH% rmdir /s /q %LOCAL_BINPATH%
	exit /b %ERRORLEVEL%
	
