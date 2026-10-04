#!/usr/bin/env bash
#
#a rendszerinfo.sh egy összefoglalót ír ki a gépről
#Használat: ./rendszerinfo.sh [celjfaljnev]
#   cél fájl(opcionális): ha megadod, a kimenet ide kerül a terminál helyett
#
# Visszatérési érték: sikeres futás esetén 0
#                     nullától különböző, ha a megadott cél fájlba nem lehet írni (hibaüzenet stderr-re)

set -u
cel_fajl="${1:-}"

osszefoglalo=$(
    printf '%-20s %s\n' "Hosztnév:" "$(hostname)"
    printf '%-20s %s\n' "Kernelverzió:" "$(uname -r)"
    printf '%-20s %s\n' "Uptime:" "$(uptime)"
    printf '%-20s %s\n' "Bejelentkezett felhasználó:" "$(whoami)"
    printf '%-20s %s\n' "Home könyvtár mérete:" "$(du -sh "$HOME" 2>/dev/null | cut -f1)"
    printf '%-20s %s\n' "Szabad hely (/):" "$(df -h / | awk 'NR==2 {print $4}')"
    printf '%-20s %s\n' "Futó folyamatok:" "$(ps -e | wc -l)"
)

if [ -n "$cel_fajl" ]; then
    if printf '%s\n' "$osszefoglalo" 2>/dev/null > "$cel_fajl"; then
        printf 'Kiírva ide: %s\n' "$cel_fajl"
    else
        printf 'Hiba: nem sikerült írni a "%s" fájlba.\n' "$cel_fajl" >&2
        exit 1
    fi
else
    printf '%s\n' "$osszefoglalo"
fi

exit 0