

`crontab -l` kimenete:
```
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ crontab -l
#asd
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
0 3 * * * /home/bundy/elte2026/szamrend/szamitogepesrendszerekgyak/hf07/mentes.sh /home/bundy/elte2026/szamrend/szamitogepesrendszerekgyak /home/bundy/mentesek >> /home/bundy/mentesek/cron.log 2>&1
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ 

```


Tesztek:
```
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ ls /home/bundy/mentesek_teszt | grep -c tar.gz 
7
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ grep retenció /home/bundy/mentesek_teszt/mentes.log
2026-11-08 20:56:16 retenció: 1 mentés van (megtartandó: 7), nincs törlés
2026-11-08 20:56:16 retenció: 2 mentés van (megtartandó: 7), nincs törlés
2026-11-08 20:56:16 retenció: 3 mentés van (megtartandó: 7), nincs törlés
2026-11-08 20:56:16 retenció: 4 mentés van (megtartandó: 7), nincs törlés
2026-11-08 20:56:16 retenció: 5 mentés van (megtartandó: 7), nincs törlés
2026-11-08 20:56:16 retenció: 6 mentés van (megtartandó: 7), nincs törlés
2026-11-08 20:56:16 retenció: 7 mentés van (megtartandó: 7), nincs törlés
2026-11-08 20:56:16 retenció: törölve: mentes-2026-11-01-0300.tar.gz
2026-11-08 20:56:17 retenció: törölve: mentes-2026-11-02-0300.tar.gz
2026-11-08 20:56:17 retenció: törölve: mentes-2026-11-03-0300.tar.gz
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ 

bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ printf 'X' | dd of=/home/bundy/mentesek_teszt/mentes-2026-11-09-0300.tar.gz bs=1 seek=100 count=1 conv=notrunc
./visszatoltes.sh -m /home/bundy/mentesek_teszt mentes-2026-11-09-0300 -c /tmp/vissza; echo $?
1+0 records in
1+0 records out
1 byte copied, 0.000170364 s, 1.0 kB/s
Hiba: az ellenőrzőösszeg NEM egyezik: mentes-2026-11-09-0300.tar.gz sérült vagy módosított, nem töltöm vissza
4
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ ./visszatoltes.sh -m /home/bundy/mentesek_teszt --legutobbi -c /tmp/vissza --proba
Mentés: mentes-2026-11-10-0300.tar.gz
Sha256: egyezik
Cél:    /tmp/vissza
Fájlok: 79
--proba: nem történt visszatöltés.
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ 

bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ ls /tmp/vissza
ls: cannot access '/tmp/vissza': No such file or directory
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ mkdir -p /tmp/nagy && head -c 150000000 /dev/urandom > /tmp/nagy/random.bin
./mentes.sh /tmp/nagy /home/bundy/mentesek_teszt2 &
sleep 1
./mentes.sh /tmp/nagy /home/bundy/mentesek_teszt2; echo "második példány kilépési kódja: $?"
wait
ls /home/bundy/mentesek_teszt2 | grep -c tar.gz     # 1
cat /home/bundy/mentesek_teszt2/mentes.log
rm -rf /tmp/nagy
[1] 75021
Már fut egy mentés ide: /home/bundy/mentesek_teszt2; ez a példány kilép.
második példány kilépési kódja: 5
OK: mentes-2026-11-08-2102.tar.gz
[1]+  Done                       ./mentes.sh /tmp/nagy /home/bundy/mentesek_teszt2
1
2026-11-08 21:02:47 indul: pid=75021 felhasználó=bundy cwd=/home/bundy/elte2026/szamrend/szamitogepesrendszerekgyak/hf07 bejövő_PATH=/home/bundy/.vscode-server/extensions/vadimcn.vscode-lldb-1.12.3/bin:/home/bundy/.vscode-server/bin/a717861c07586a53d83b80d742cd3f59b20a6273/bin/remote-cli:/home/bundy/.cabal/bin:/home/bundy/.ghcup/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/usr/lib/linux-tools/6.18.54.1-microsoft-standard-WSL2/bin:/mnt/c/WINDOWS/system32:/mnt/c/WINDOWS:/mnt/c/WINDOWS/System32/Wbem:/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/:/mnt/c/WINDOWS/System32/OpenSSH/:/mnt/c/Program Files/NVIDIA Corporation/NVIDIA App/NvDLISR:/mnt/c/Program Files (x86)/NVIDIA Corporation/PhysX/Common:/mnt/c/Program Files/Git/cmd:/mnt/c/Program Files/Microsoft SQL Server/150/Tools/Binn/:/mnt/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/170/Tools/Binn/:/mnt/c/Program Files/nodejs/:/mnt/c/Program Files/dotnet/:/mnt/c/Program Files/wooting-analog-sdk/:/mnt/c/Program Files/Microsoft SQL Server/170/Tools/Binn/:/mnt/c/Program Files/WSL/:/mnt/c/Users/david/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/david/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Users/david/AppData/Roaming/npm:/mnt/c/Users/david/.dotnet/tools:/mnt/c/Users/david/AppData/Local/Programs/Microsoft VS Code/bin/copilot-shim:/snap/bin PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin forrás=/tmp/nagy cél=/home/bundy/mentesek_teszt2 megtart=7
2026-11-08 21:02:48 már fut egy mentés (/home/bundy/mentesek_teszt2), ez a példány kilép
2026-11-08 21:02:50 kész: mentes-2026-11-08-2102.tar.gz (150024338 bájt, 1 fájl, sha256: ed34253fd82807c0c89f00f07abe2d6eefd1478fc9632225325e3955bc9fdc28)
2026-11-08 21:02:51 ellenőrzés: a kész mentés sha256-ja egyezik
2026-11-08 21:02:51 retenció: 1 mentés van (megtartandó: 7), nincs törlés
2026-11-08 21:02:51 vége: siker
2026-11-08 21:02:51 takarítás kész, kilépési kód: 0
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ 

bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ shellcheck mentes.sh visszatoltes.sh
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf07$ x

```