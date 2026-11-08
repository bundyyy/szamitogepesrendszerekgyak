#!/usr/bin/env bash
# visszatoltes.sh - a mentes.sh mentéseinek listázása és ellenőrzött visszatöltése
# Használat: visszatoltes.sh -m MENTÉSEK_KÖNYVTÁRA [--lista | --legutobbi | NÉV] [-c CÉL] [--proba]
# Kilépési kód: a EX_* konstansok és a súgó listázza őket.

set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
export LC_ALL=C

readonly EX_OK=0 EX_USAGE=2 EX_NOFILE=3 EX_BADSUM=4 EX_CONFLICT=5 EX_FAIL=6

MDIR="" CEL="" NEV="" BASE=""
LEGUTOBBI=0 PROBA=0 FELULIR=0

usage() {
	local prog="${0##*/}"
	cat <<EOF
Használat: $prog -m MENTÉSEK [--lista]
           $prog -m MENTÉSEK (--legutobbi | NÉV) -c CÉL [--proba] [--felulir]

Listázza a mentéseket (dátum, méret), vagy egy mentést ellenőrzés után visszatölt a CÉL könyvtárba.
Az ellenőrzőösszeget minden visszatöltés előtt ellenőrzi; eltérésnél nem tölt vissza semmit.
Meglévő fájlt nem ír felül kérdezés nélkül.

Kapcsolók:
	-h, --help           ez a súgó, kilépés 0-val
	-m, --mentesek DIR   a mentések könyvtára (kötelező)
	--lista              a mentések listája (alapértelmezés, ha nincs mentésnév)
	--legutobbi          a legújabb mentést tölti vissza
	NÉV                  a visszatöltendő mentés neve (.tar.gz nélkül is jó)
	-c, --cel DIR        ide tölt vissza (kötelező visszatöltésnél, szükség esetén létrehozza)
	--proba              csak megmutatja, mi történne; semmit nem ír, nem hoz létre
	--felulir            a meglévő fájlok felülírásába előre beleegyezik (nem kérdez)

Kilépési kód: 0 siker; 2 hibás használat; 3 nincs ilyen mentés vagy könyvtár; 4 hiányzó vagy
              hibás ellenőrzőösszeg; 5 felülírás-ütközés (és nincs beleegyezés); 6 a visszatöltés sikertelen.

Példák:
	$prog -m /home/diak/mentesek
	$prog -m /home/diak/mentesek --legutobbi -c /tmp/vissza --proba
	$prog -m /home/diak/mentesek mentes-2026-11-08-0300 -c /tmp/vissza
EOF
}

kilep() { 
	echo "Hiba: $2" >&2
	exit "$1"
}

kilep_usage() {
	echo "Hiba: $1" >&2
	usage >&2
	exit "$EX_USAGE"
}

ertek_kell() {
	[ "$#" -ge 2 ] || kilep_usage "a(z) $1 kapcsolónak értéket kell megadni"
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-h | --help) usage; exit "$EX_OK" ;;
			-m | --mentesek) ertek_kell "$@"; MDIR=$2; shift 2 ;;
			-c | --cel) ertek_kell "$@"; CEL=$2; shift 2 ;;
			--lista) shift ;;
			--legutobbi) LEGUTOBBI=1; shift ;;
			--proba) PROBA=1; shift ;;
			--felulir) FELULIR=1; shift ;;
			-?*) kilep_usage "ismeretlen kapcsoló: $1" ;;
			*) [ -z "$NEV" ] || kilep_usage "csak egy mentésnév adható meg"; NEV=$1; shift ;;
		esac
	done
	[ -n "$MDIR" ] || kilep_usage "hiányzik a -m/--mentesek kapcsoló"
	[ -d "$MDIR" ] || kilep "$EX_NOFILE" "nem létező könyvtár: $MDIR"
	MDIR=$(cd -- "$MDIR" && pwd -P)
	if [ -n "$NEV" ] && [ "$LEGUTOBBI" -eq 1 ]; then
		kilep_usage "a mentésnév és a --legutobbi egyszerre nem adható meg"
	fi
	if { [ -n "$NEV" ] || [ "$LEGUTOBBI" -eq 1 ]; } && [ -z "$CEL" ]; then
		kilep_usage "visszatöltéshez kell a -c/--cel könyvtár"
	fi
}

mentesek() {
	find "$MDIR" -maxdepth 1 -type f -name 'mentes-*.tar.gz' -printf '%f\n' |
		grep -E '^mentes-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}\.tar\.gz$' | sort || true
}

lista() {
	local nev d meret ossz
	echo "Mentés                         Dátum                 Méret  Ellenőrzőösszeg"
	while IFS= read -r nev; do
		d=${nev#mentes-}
		d=${d%.tar.gz}
		meret=$(numfmt --to=iec --suffix=B "$(stat -c %s "$MDIR/$nev")")
		ossz=van
		[ -f "$MDIR/${nev%.tar.gz}.sha256" ] || ossz=HIÁNYZIK
		printf '%-30s %-17s %9s  %s\n' "$nev" "${d:0:10} ${d:11:2}:${d:13:2}" "$meret" "$ossz"
	done < <(mentesek)
}

mentes_valaszt() {
	if [ "$LEGUTOBBI" -eq 1 ]; then
		NEV=$(mentesek | tail -n 1)
		[ -n "$NEV" ] || kilep "$EX_NOFILE" "nincs mentés a könyvtárban: $MDIR"
	fi
	NEV=${NEV%.tar.gz}
	[[ $NEV =~ ^mentes-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]] ||
		kilep_usage "érvénytelen mentésnév: $NEV (pl. mentes-2026-11-08-0300)"
	BASE=$NEV
	NEV="$BASE.tar.gz"
	[ -f "$MDIR/$NEV" ] || kilep "$EX_NOFILE" "nincs ilyen mentés: $NEV (a --lista megmutatja az elérhetőket)"
}

ellenoriz_osszeg() {
	local sor
	[ -f "$MDIR/$BASE.sha256" ] || kilep "$EX_BADSUM" "nincs ellenőrzőösszeg-fájl ($BASE.sha256): ellenőrizetlen mentést nem töltök vissza"
	sor=$(head -n 1 "$MDIR/$BASE.sha256")
	[ "${sor#*  }" = "$NEV" ] || kilep "$EX_BADSUM" "az ellenőrzőösszeg-fájl nem ehhez az archívumhoz tartozik"
	if ! (cd "$MDIR" && sha256sum -c --status -- "$BASE.sha256" 2> /dev/null); then
		kilep "$EX_BADSUM" "az ellenőrzőösszeg NEM egyezik: $NEV sérült vagy módosított, nem töltöm vissza"
	fi
}

utkozesek() {
	local m
	tar -tzf "$MDIR/$NEV" | while IFS= read -r m; do
		case "$m" in */) continue ;; esac
		if [ -e "$CEL/$m" ] || [ -L "$CEL/$m" ]; then
			printf '%s\n' "$m"
		fi
	done
}

felulir_engedely() {
	local valasz
	[ "$FELULIR" -eq 0 ] || return 0
	if [ ! -t 0 ]; then
		kilep "$EX_CONFLICT" "meglévő fájlok felülírása kérdezés nélkül nem lehetséges (használd a --felulir kapcsolót)"
	fi
	read -r -p "Felülírjam ezeket? [i/N] " valasz
	[[ $valasz =~ ^[iIyY]$ ]] || kilep "$EX_CONFLICT" "a felülírást nem engedélyezted, nem történt visszatöltés"
}

visszatolt() {
	local ut=() db
	mapfile -t ut < <(utkozesek)
	db=$(tar -tzf "$MDIR/$NEV" | grep -vc '/$' || true)
	printf 'Mentés:\t%s\nSha256:\tegyezik\nCél:\t%s\nFájlok:\t%s\n' "$NEV" "$CEL" "$db"
	if [ "${#ut[@]}" -gt 0 ]; then
		printf 'Már létező fájl a célban (%d), ezeket felülírná:\n' "${#ut[@]}"
		printf '\t%s\n' "${ut[@]:0:10}"
		[ "${#ut[@]}" -le 10 ] || printf '\t... és még %d\n' "$((${#ut[@]} - 10))"
	fi
	if [ "$PROBA" -eq 1 ]; then
		echo "--proba: nem történt visszatöltés."
		return 0
	fi
	if [ "${#ut[@]}" -gt 0 ]; then
		felulir_engedely
		mkdir -p -- "$CEL"
		tar -xzf "$MDIR/$NEV" -C "$CEL" || kilep "$EX_FAIL" "a kicsomagolás hibával leállt"
	else
		mkdir -p -- "$CEL"
		tar -xzkf "$MDIR/$NEV" -C "$CEL" || kilep "$EX_FAIL" "a kicsomagolás hibával leállt"
	fi
	echo "Visszatöltve: $db fájl ide: $CEL"
}

main() {
	parse_args "$@"
	if [ -z "$NEV" ] && [ "$LEGUTOBBI" -eq 0 ]; then
		lista
		return "$EX_OK"
	fi
	mentes_valaszt
	ellenoriz_osszeg
	visszatolt
	return "$EX_OK"
}

main "$@"