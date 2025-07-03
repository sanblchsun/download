chcp 65001
net user /add admin D9SUC1@#$7gghj
net localgroup Администраторы admin /add
net localgroup Пользователи admin /del
wmic useraccount where "name='admin'" set passwordexpires=false
SET save="C:\Users\sun\Desktop\1.txt"
ECHO USERs: >> %save%
wmic useraccount get name,status >> %save%
net localgroup Администраторы >> %save%
ipconfig >> %save%
ECHO "====================================================" >> %save%
pause