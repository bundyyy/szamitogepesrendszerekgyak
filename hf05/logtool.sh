#!/usr/bin/env bash
# logtool.sh - webszerver access log riport, parancssori eszközként
#
# Használat: ./logtool.sh -f FÁJL [-t N] [-s KÓD] [-o FÁJL] [-q]   (részletek: --help)
# Kilépési kódok: a EX_* konstansok és a súgó listázza őket.

set -u

readonly EX_OK=0 EX_USAGE=2 EX_NOFILE=3 EX_NODATA=4 EX_NOOUT=5

FILE=""
TOP=10
STATUS=""
OUTPUT=""
QUIET=0

usage() {
	local prog="${0##*/}"
	cat <<EOF
Használat: $prog -f FÁJL [kapcsolók]

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
	$prog -f access.log -t 3
	$prog -f access.log -s 404 -o riport.txt
EOF
}

hiba() {
	echo "Hiba: $1" >&2
}

hiba_usage() {
	hiba "$1"
	usage >&2
	exit "$EX_USAGE"
}

ertek_kell() {
	[ "$#" -ge 2 ] || hiba_usage "a(z) $1 kapcsolónak értéket kell megadni"
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-h | --help) usage; exit "$EX_OK" ;;
			-f | --file) ertek_kell "$@"; FILE="$2"; shift 2 ;;
			-t | --top) ertek_kell "$@"; TOP="$2"; shift 2 ;;
			-s | --status) ertek_kell "$@"; STATUS="$2"; shift 2 ;;
			-o | --output) ertek_kell "$@"; OUTPUT="$2"; shift 2 ;;
			-q | --quiet) QUIET=1; shift ;;
			*) hiba_usage "ismeretlen kapcsoló: $1" ;;
		esac
	done
}

sorok() {
	awk -v kod="$STATUS" 'kod == "" || $9 == kod' "$FILE"
}

ellenoriz_bemenet() {
	[ -n "$FILE" ] || hiba_usage "hiányzik a -f/--file kapcsoló"
	[[ $TOP =~ ^[1-9][0-9]*$ ]] || hiba_usage "a -t/--top értéke pozitív egész kell legyen: $TOP"
	[[ -z $STATUS || $STATUS =~ ^[0-9]{3}$ ]] || hiba_usage "a -s/--status értéke háromjegyű kód kell legyen: $STATUS"
	if [ ! -f "$FILE" ] || [ ! -r "$FILE" ]; then
		hiba "nem létező vagy nem olvasható fájl: $FILE"
		exit "$EX_NOFILE"
	fi
	if [ -z "$(sorok | head -n 1)" ]; then
		hiba "nincs feldolgozható sor (üres a log, vagy a -s szűrőre nincs találat)"
		exit "$EX_NODATA"
	fi
	if [ -n "$OUTPUT" ]; then
		[ "$OUTPUT" -ef "$FILE" ] && hiba_usage "a -o célfájl nem lehet maga a logfájl"
		: 2>/dev/null >> "$OUTPUT" || { hiba "nem írható a kimeneti fájl: $OUTPUT"; exit "$EX_NOOUT"; }
	fi
}

cim() {
	printf '\n%s\n' "$1"
}

alapszamok() {
	sorok | awk '
		{ ip[$1]++ }
		END {
			for (k in ip) egyedi++
			printf "Kérések összesen:  %6d\n", NR
			printf "Egyedi IP-címek:   %6d\n", egyedi
		}'
}

top_ip() {
	local n="$1"
	cim "A $n legaktívabb IP (IP, kérések)"
	sorok | awk '{ ip[$1]++ } END { for (k in ip) printf "%-16s %6d\n", k, ip[k] }' |
		sort -k2,2nr -k1,1 | head -n "$n"
}

statusz_megoszlas() {
	cim "Státuszkódok (kód, db, %)"
	sorok | awk '{ st[$9]++ } END { for (k in st) printf "%-6s %6d %6.1f%%\n", k, st[k], 100 * st[k] / NR }' |
		sort -n
}

hibas_url() {
	local n="$1"
	cim "A $n leggyakoribb hibás (4xx, 5xx) URL (URL, db)"
	sorok | awk '$9 >= 400 { h[$7]++ } END { for (k in h) printf "%-24s %6d\n", k, h[k] }' |
		sort -k2,2nr -k1,1 | head -n "$n"
}

orankent() {
	cim "Kérések óránként (óra, db)"
	sorok | awk '
		{
			split($4, d, ":")
			o = substr(d[1], 2) " " d[2] ":00"
			if (!(o in db)) sor[++n] = o
			db[o]++
		}
		END {
			for (o in db) if (db[o] > max) max = db[o]
			for (i = 1; i <= n; i++)
				printf "%-17s %6d%s\n", sor[i], db[sor[i]], (db[sor[i]] == max ? "  <- csúcs" : "")
		}'
}

atlag_valaszido() {
	cim "Átlagos válaszidő (mp)"
	sorok | awk '
		function atl(nev, s, n) {
			if (n) printf "%s  %7.3f\n", nev, s / n
			else printf "%s  %7s\n", nev, "-"
		}
		{
			s += $NF
			if ($9 == 200) { s200 += $NF; n200++ }
			if ($9 == 500) { s500 += $NF; n500++ }
		}
		END {
			atl("összes:", s, NR)
			atl("200-as:", s200, n200)
			atl("500-as:", s500, n500)
		}'
}

osszefoglalo() {
	sorok | awk '
		{ ip[$1]++ }
		END {
			for (k in ip)
				if (ip[k] > max || (ip[k] == max && k < top)) { max = ip[k]; top = k }
			printf "A legaktívabb IP a %s, ami az összes kérés %.1f%%-át adta.\n", top, 100 * max / NR
		}'
}

riport() {
	if [ "$QUIET" -eq 1 ]; then
		osszefoglalo
		return
	fi
	[ -z "$STATUS" ] || printf 'Szűrő: csak a %s státuszkódú kérések\n' "$STATUS"
	alapszamok
	top_ip "$TOP"
	statusz_megoszlas
	hibas_url "$TOP"
	orankent
	atlag_valaszido
	echo
	osszefoglalo
}

main() {
	parse_args "$@"
	ellenoriz_bemenet
	if [ -n "$OUTPUT" ]; then
		riport > "$OUTPUT"
		[ "$QUIET" -eq 1 ] || echo "Riport kiírva ide: $OUTPUT" >&2
	else
		riport
	fi
	exit "$EX_OK"
}

main "$@"