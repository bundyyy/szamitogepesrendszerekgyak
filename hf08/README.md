# Magyarázatok:
A docker rétegenként gyorsítótáraz; ha egy réteg változik,
az összes utána következő újraépül. A ritkán változó dolgokat (csomagok)
előre, a gyakran változót (script) hátra kell tenni.

## Miért :ro a volume végén?
Csak olvasható csatolás: a konténer nem tudja módosítani vagy törölni a
host logfájljait. A logtool csak olvas, tehát nincs szüksége írásra; egy
script hiba (pl. rossz átirányítás, `rm`) vagy egy feltört konténer sem
tud kárt tenni az eredeti adatokban. Ez a legkisebb jogosultság elve.
# Rétegek sorrendje 
```
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ time docker build --no-cache -t logtool:1.0 .
[+] Building 12.0s (10/10) FINISHED                                                            docker:default
 => [internal] load build definition from dockerfile                                                     0.0s
 => => transferring dockerfile: 359B                                                                     0.0s
 => [internal] load metadata for docker.io/library/debian:bookworm-slim                                  1.2s
 => [internal] load .dockerignore                                                                        0.0s
 => => transferring context: 104B                                                                        0.0s
 => [1/5] FROM docker.io/library/debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2  3.1s
 => => resolve docker.io/library/debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2  0.0s
 => => sha256:dd051e1b8c92ff101fa3071ab97ea4924885942f15644e01c3dc095764e863e3 28.25MB / 28.25MB         2.0s
 => => extracting sha256:dd051e1b8c92ff101fa3071ab97ea4924885942f15644e01c3dc095764e863e3                0.9s
 => [internal] load build context                                                                        0.1s
 => => transferring context: 5.03kB                                                                      0.0s
 => [2/5] RUN apt-get update  && apt-get install -y --no-install-recommends bash curl jq ca-certificate  5.4s
 => [3/5] RUN useradd --create-home --uid 1000 --shell /bin/bash logtool                                 0.3s 
 => [4/5] WORKDIR /app                                                                                   0.0s 
 => [5/5] COPY --chmod=755 logtool.sh /app/logtool.sh                                                    0.1s 
 => exporting to image                                                                                   1.8s 
 => => exporting layers                                                                                  0.5s 
 => => exporting manifest sha256:f12170be39d0bf7b9645f3e34b2e2e80cb72f32bdb556e8cea2c03d3a94df52e        0.0s 
 => => exporting config sha256:4118b6e610ae58fbfafe34eba0eb35785f1932902709346c26a260d7a0522510          0.0s
 => => exporting attestation manifest sha256:9a9cb9fd40d726e7a395c7fa14dcce13b1535c3e51a6ab3fe0564b6192  0.0s
 => => exporting manifest list sha256:f9f8ef1bde8c88e6ea328d27e60f706c789ebdbb8088ec30531c5ccc91b7afb2   0.0s
 => => naming to docker.io/library/logtool:1.0                                                           0.0s
 => => unpacking to docker.io/library/logtool:1.0                                                        1.2s

real    0m12.411s
user    0m0.119s
sys     0m0.187s
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ 

bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ time docker build -t logtool:1.0 .
[+] Building 0.9s (10/10) FINISHED                                                             docker:default
 => [internal] load build definition from dockerfile                                                     0.0s
 => => transferring dockerfile: 359B                                                                     0.0s
 => [internal] load metadata for docker.io/library/debian:bookworm-slim                                  0.5s
 => [internal] load .dockerignore                                                                        0.0s
 => => transferring context: 104B                                                                        0.0s
 => [1/5] FROM docker.io/library/debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2  0.0s
 => => resolve docker.io/library/debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2  0.0s
 => [internal] load build context                                                                        0.0s
 => => transferring context: 5.04kB                                                                      0.0s
 => CACHED [2/5] RUN apt-get update  && apt-get install -y --no-install-recommends bash curl jq ca-cert  0.0s
 => CACHED [3/5] RUN useradd --create-home --uid 1000 --shell /bin/bash logtool                          0.0s
 => CACHED [4/5] WORKDIR /app                                                                            0.0s
 => [5/5] COPY --chmod=755 logtool.sh /app/logtool.sh                                                    0.0s
 => exporting to image                                                                                   0.2s
 => => exporting layers                                                                                  0.1s
 => => exporting manifest sha256:8911370a9fb791df11de89fae61bf4c504494628d2618f48d30a9c95afad4469        0.0s
 => => exporting config sha256:107e066e27a7d8ee43360f7e8a39d9d87edff845fc1da588d155d68de987b328          0.0s
 => => exporting attestation manifest sha256:b399f4e6bd283caff8bf1917ed239080dcda9bb211334a94aab9d57c3e  0.0s
 => => exporting manifest list sha256:0073e081cf62763d253f8fbb149b7111483b87ed806914198fbe517ae391e6cc   0.0s
 => => naming to docker.io/library/logtool:1.0                                                           0.0s
 => => unpacking to docker.io/library/logtool:1.0                                                        0.0s

real    0m1.174s
user    0m0.053s
sys     0m0.099s
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ 


bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ docker build --no-cache -f Dockerfile.bad -t logtool:bad .
[+] Building 7.3s (10/10) FINISHED                                                             docker:default
 => [internal] load build definition from Dockerfile.bad                                                 0.0s
 => => transferring dockerfile: 328B                                                                     0.0s
 => [internal] load metadata for docker.io/library/debian:bookworm-slim                                  0.5s
 => [internal] load .dockerignore                                                                        0.0s
 => => transferring context: 104B                                                                        0.0s
 => CACHED [1/5] FROM docker.io/library/debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca6  0.0s
 => => resolve docker.io/library/debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2  0.0s
 => [internal] load build context                                                                        0.0s
 => => transferring context: 358B                                                                        0.0s
 => [2/5] WORKDIR /app                                                                                   0.0s
 => [3/5] COPY . .                                                                                       0.0s
 => [4/5] RUN apt-get update  && apt-get install -y --no-install-recommends bash curl jq ca-certificate  5.4s
 => [5/5] RUN useradd --create-home --uid 1000 --shell /bin/bash logtool                                 0.3s
 => exporting to image                                                                                   0.8s 
 => => exporting layers                                                                                  0.5s 
 => => exporting manifest sha256:f5536ab30c1622886213af4e4db922c7f4bf33a132505653b86c77ce0ee65576        0.0s 
 => => exporting config sha256:7c8cf995a8741a9a17f17b3b31827ce7d7e50b8f349c2deeb5b9025caf606635          0.0s 
 => => exporting attestation manifest sha256:e088347e97d3a6d2b5f4329060617cb31fb955ee5eb8a43b6a32016740  0.0s 
 => => exporting manifest list sha256:4dcdb59dc6ce14feac34481e5c6bf2227caf3889da0c6b8ca31398498997b6ad   0.0s
 => => naming to docker.io/library/logtool:bad                                                           0.0s
 => => unpacking to docker.io/library/logtool:bad                                                        0.3s
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ echo "# modositas2" >> logtool.sh
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ time docker build -f Dockerfile.bad -t logtool:bad .
[+] Building 6.9s (10/10) FINISHED                                                             docker:default
 => [internal] load build definition from Dockerfile.bad                                                 0.0s
 => => transferring dockerfile: 328B                                                                     0.0s
 => [internal] load metadata for docker.io/library/debian:bookworm-slim                                  0.3s
 => [internal] load .dockerignore                                                                        0.0s
 => => transferring context: 104B                                                                        0.0s
 => [1/5] FROM docker.io/library/debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2  0.0s
 => => resolve docker.io/library/debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2  0.0s
 => [internal] load build context                                                                        0.0s
 => => transferring context: 5.09kB                                                                      0.0s
 => CACHED [2/5] WORKDIR /app                                                                            0.0s
 => [3/5] COPY . .                                                                                       0.1s
 => [4/5] RUN apt-get update  && apt-get install -y --no-install-recommends bash curl jq ca-certificate  5.3s
 => [5/5] RUN useradd --create-home --uid 1000 --shell /bin/bash logtool                                 0.3s
 => exporting to image                                                                                   0.8s 
 => => exporting layers                                                                                  0.4s 
 => => exporting manifest sha256:866d675cbfe6570ef4a166792573cd3b3e7a3ec51730f30e4f4f05098ee3a7fc        0.0s 
 => => exporting config sha256:1eb93b7d0be345d76a623cde6a492b647511b4431e90eff5cbbe293ccaa1c055          0.0s 
 => => exporting attestation manifest sha256:9f38e24523ae8973687d4c7baa81507afa9d014cd14f10a9797e4908e3  0.0s 
 => => exporting manifest list sha256:41000a4c64f20bcf241969094c7c6ffe2e509d99d0402143ea2e115cecfae0dd   0.0s
 => => naming to docker.io/library/logtool:bad                                                           0.0s
 => => unpacking to docker.io/library/logtool:bad                                                        0.2s

real    0m7.137s
user    0m0.093s
sys     0m0.120s
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ 
```

# Futtatás
```
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ docker run --rm logtool:1.0 --help
Hiba: ismeretlen kapcsoló: --help#
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
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ docker run --rm -v "$PWD/adatok:/adatok:ro" logtool:1.0 -f /adatok/access.log -t 5
Hiba: ismeretlen kapcsoló: modositas
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
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ docker images logtool
                                                                                          i Info →   U  In Use
IMAGE         ID             DISK USAGE   CONTENT SIZE   EXTRA
logtool:1.0   54666df468af        136MB         34.2MB        
logtool:bad   41000a4c64f2        136MB         34.2MB        
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ docker run --rm --entrypoint whoami logtool:1.0
logtool
bundy@WIN-MDLU3IMS43G:~/elte2026/szamrend/szamitogepesrendszerekgyak/hf08$ 
```