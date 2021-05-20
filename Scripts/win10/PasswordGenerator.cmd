REM runas /noprofile /user:mymachine\administrator cmd
cd /d %~dp0
PowerShell Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
PowerShell .\PasswordGenerator.ps1