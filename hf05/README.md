```
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf05$ ./logtool.sh --help
Használat: logtool.sh -f FÁJL [kapcsolók]

Riport egy webszerver access logjáról.

Kapcsolók:
        -h, --help         a súgó kiírása, kilépés 0-val
        -f, --file FÁJL    a feldolgozandó log (kötelező)
        -t, --top N        hány elemet mutasson a toplistákban (alapértelmezés: 10)
        -s, --status KÓD   csak az adott státuszkódú sorokat nézze (pl. 404)
        -o, --output FÁJL  a riportot fájlba írja a képernyő helyett
        -q, --quiet        csak a végső összefoglaló sort írja ki

Kilépési kódok:
        0  siker
        2  hibás használat (hiányzó vagy ismeretlen kapcsoló, hibás érték)
        3  a logfájl nem létezik vagy nem olvasható
        4  nincs feldolgozható sor (üres log, vagy a -s szűrőre nincs találat)
        5  a kimeneti fájl nem írható

Példák:
        logtool.sh -f access.log -t 3
        logtool.sh -f access.log -s 404 -o riport.txt
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf05$ ./logtool.sh -f access.log -t 3 
Kérések összesen:    4000
Egyedi IP-címek:     3284

A 3 legaktívabb IP (IP, kérések)
193.224.41.77       717
10.100.174.15         1
10.102.80.38          1

Státuszkódok (kód, db, %)
200      2026   50.6%
301       395    9.9%
403       371    9.3%
404       381    9.5%
500       416   10.4%
502       411   10.3%

A 3 leggyakoribb hibás (4xx, 5xx) URL (URL, db)
/index.html                 217
/kepek/logo.png             212
/admin                      199

Kérések óránként (óra, db)
21/Sep/2026 14:00    165
21/Sep/2026 15:00    212
21/Sep/2026 16:00    211
21/Sep/2026 17:00    212
21/Sep/2026 18:00    212
21/Sep/2026 19:00    212
21/Sep/2026 20:00    211
21/Sep/2026 21:00    212
21/Sep/2026 22:00    212
21/Sep/2026 23:00    212
22/Sep/2026 00:00    211
22/Sep/2026 01:00    212
22/Sep/2026 02:00    212
22/Sep/2026 03:00    212
22/Sep/2026 04:00    211
22/Sep/2026 05:00    213  <- csúcs
22/Sep/2026 06:00    211
22/Sep/2026 07:00    212
22/Sep/2026 08:00    212
22/Sep/2026 09:00     23

Átlagos válaszidő (mp)
összes:    1.246
200-as:    1.239
500-as:    1.239

A legaktívabb IP a 193.224.41.77, ami az összes kérés 17.9%-át adta.
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf05$ ./logtool.sh -f access.log -s 404
Szűrő: csak a 404 státuszkódú kérések
Kérések összesen:     381
Egyedi IP-címek:      310

A 10 legaktívabb IP (IP, kérések)
193.224.41.77        72
10.218.137.244        1
10.228.114.56         1
10.230.96.244         1
10.246.248.92         1
10.32.155.17          1
10.72.175.64          1
11.148.141.30         1
11.165.150.26         1
11.244.255.198        1

Státuszkódok (kód, db, %)
404       381  100.0%

A 10 leggyakoribb hibás (4xx, 5xx) URL (URL, db)
/index.html                  61
/kepek/logo.png              50
/login                       50
/                            47
/api/v1/orders               47
/api/v1/users                45
/admin                       43
/static/app.js               38

Kérések óránként (óra, db)
21/Sep/2026 14:00     14
21/Sep/2026 15:00     25
21/Sep/2026 16:00     20
21/Sep/2026 17:00     13
21/Sep/2026 18:00     18
21/Sep/2026 19:00     15
21/Sep/2026 20:00     24
21/Sep/2026 21:00     20
21/Sep/2026 22:00     22
21/Sep/2026 23:00     23
22/Sep/2026 00:00     19
22/Sep/2026 01:00     24
22/Sep/2026 02:00     24
22/Sep/2026 03:00     28  <- csúcs
22/Sep/2026 04:00     20
22/Sep/2026 05:00     20
22/Sep/2026 06:00     14
22/Sep/2026 07:00     15
22/Sep/2026 08:00     22
22/Sep/2026 09:00      1

Átlagos válaszidő (mp)
összes:    1.248
200-as:        -
500-as:        -

A legaktívabb IP a 193.224.41.77, ami az összes kérés 18.9%-át adta.
```