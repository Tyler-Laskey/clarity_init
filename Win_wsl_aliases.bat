@echo off
@REM reg add "HKCU\SOFTWARE\Microsoft\Command Processor" /v "AutoRun" /t REG_EXPAND_SZ /d "doskey /macrofile=\"c:\wsl\aliases.doskey\""

echo Testing for existing registry key "HKCU\Software\Microsoft\Command Processor"
reg query "HKCU\Software\Microsoft\Command Processor" >nul 2>NUL
if %ERRORLEVEL% EQU 0 goto exists1
echo The registry key does not exist

@REM Given that we are here, the key in question does not exist.
:DoWork
call :fCreateAliases
call :fRegAdd
goto EOF

:exists1
  echo !!! ATTENTION !!!
  echo The aliases reg key has already been created, if you have run this script before this is to be expected
  echo !!! ATTENTION !!!
  set /p Input=Do you want to re-create the aliases it? (y/n) 
  if /I "%Input%"=="y" goto DoWork
  echo Invalid input.
  goto exists1

:fCreateAliases 
@REM deploy our aliases
  echo Creating alias file "c:\wsl\aliases.doskey"
  (
    echo minikube=wsl -- minikube $*
    echo kubectl=wsl -- kubectl $*
    echo jq=wsl -- jq $*
    echo kcat=wsl -- kafkacat $*
    echo jless=wsl -- jless $*
    echo helm=wsl -- helm $*
  ) > "c:\wsl\aliases.doskey"
EXIT /B 0

:fRegAdd
  @REM add aliases to AutoRun for cmd prompt
  echo Creating registry key "HKCU\SOFTWARE\Microsoft\Command Processor\AutoRun"...
  reg add "HKCU\SOFTWARE\Microsoft\Command Processor" /v "AutoRun" /t REG_EXPAND_SZ /d "doskey /macrofile=\"c:\wsl\aliases.doskey\""
EXIT /B 0

:fRegDelete
  echo Unless you have specifically customized the following registry key it is safe to say YES
  reg delete "HKCU\SOFTWARE\Microsoft\Command Processor" /va
EXIT /B 0

:EOF