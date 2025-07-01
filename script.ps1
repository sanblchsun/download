# Получаем информацию о текущем пользователе
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = [Security.Principal.WindowsPrincipal]::new($currentUser).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    # Задаем имя и пароль для нового пользователя
    $username = "admin1"
    $password = "S3cur3#Passw0rd!" | ConvertTo-SecureString -AsPlainText -Force
    
    # Проверяем, существует ли пользователь с таким именем
    if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
        # Создаем нового пользователя
        New-LocalUser -Name $username -Password $password -FullName "Administrator User" -Description "New admin account"
        
        # Добавляем нового пользователя в группу администраторов
        Add-LocalGroupMember -Group "Администраторы" -Member $username
        Write-Host "Пользователь $username создан и добавлен в группу администраторов."
    } else {
        Write-Host "Пользователь с именем $username уже существует."
    }
} else {
    Write-Host "Текущему пользователю $($currentUser.Name) не хватает прав администратора."
}

Pause
