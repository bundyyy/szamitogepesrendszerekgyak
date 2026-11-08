#!/usr/bin/env bash
# mentes.sh - könyvtár mentése tömörített archívumba, ellenőrzőösszeggel és retencióval
# Használat: mentes.sh [-k DARAB] [-l LOGFÁJL] FORRÁS CÉL   (részletek: --help)
# Kilépési kód: a EX_* konstansok és a súgó listázza őket.

set -euo pipefail

readonly INDULO_PATH="${PATH:-}"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
export LC_ALL=C
umask 077

readonly EX_OK=0 EX_USAGE=2 EX_NOSRC=3 EX_ENV=4 EX_BUSY=5 EX_FAIL=6

KEEP=7
LOG=""
FORRAS="" CEL="" IDO="" NEV="" WORK=""

usage() {
	local prog="${0##*/}"
	cat <<EOF
Használat: $prog [-k DARAB] [-l LOGFÁJL] FORRÁS CÉL

A FORRÁS könyvtárról tömörített mentést készít a CÉL könyvtárba:
	mentes-ÉÉÉÉ-HH-NN-ÓÓMM.tar.gz   az archívum
	mentes-ÉÉÉÉ-HH-NN-ÓÓMM.sha256   ellenőrzőösszeg (sha256sum -c)
	mentes-ÉÉÉÉ-HH-NN-ÓÓMM.meta     mikor készült, mekkora, hány fájl van benne
A DARAB-nál régebbi mentéseket a fájlnévben lévő dátum alapján törli.

Kapcsolók:
	-h, --help           ez a súgó, kilépés 0-val
	-k, --megtart DARAB  ennyi legújabb mentést tart meg (alapértelmezés: 7)
	-l, --log FÁJL       naplófájl (alapértelmezés: CÉL/mentes.log)

Környezeti változó: MENTES_IDO=ÉÉÉÉ-HH-NN-ÓÓMM felülírja a fájlnévbe kerülő időbélyeget (teszteléshez).
Kilépési kód: 0 siker; 2 hibás használat; 3 a forrás nem olvasható; 4 a környezet nem megfelelő;
              5 már fut egy mentés; 6 a mentés elkészítése sikertelen.

Példák:
	$prog /home/diak/dokumentumok /home/diak/mentesek
	$prog -k 14 -l /var/tmp/mentes.log /srv/adat /mnt/ssd/mentesek
EOF
}

log() {
	[ -n "$LOG" ] || return 0
	printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}

kilep() {
	echo "Hiba: $2" >&2
	log "HIBA: $2"
	exit "$1"
}

kilep_usage() {
	echo "Hiba: $1" >&2
	usage >&2
	exit "$EX_USAGE"
}

tisztit() {
	local kod=$?
	if [ -n "$WORK" ]; then
		rm -rf -- "$WORK"
		log "takarítás kész, kilépési kód: $kod"
	fi
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-h | --help) usage; exit "$EX_OK" ;;
			-k | --megtart)
				[ "$#" -ge 2 ] || kilep_usage "a(z) $1 kapcsolónak értéket kell megadni"
				KEEP=$2; shift 2 ;;
			-l | --log)
				[ "$#" -ge 2 ] || kilep_usage "a(z) $1 kapcsolónak értéket kell megadni"
				LOG=$2; shift 2 ;;
			-?*) kilep_usage "ismeretlen kapcsoló: $1" ;;
			*) break ;;
		esac
	done
	[ "$#" -eq 2 ] || kilep_usage "két könyvtár kell: FORRÁS és CÉL"
	FORRAS=$1
	CEL=$2
}

ellenoriz_bemenet() {
	local eszkoz
	[[ $KEEP =~ ^[1-9][0-9]*$ ]] || kilep_usage "a megtartandó mentések száma pozitív egész kell legyen: $KEEP"
	IDO=${MENTES_IDO:-$(date +%Y-%m-%d-%H%M)}
	if ! [[ $IDO =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]] ||
		! date -d "${IDO:0:10} ${IDO:11:2}:${IDO:13:2}" > /dev/null 2>&1; then
		kilep_usage "érvénytelen időbélyeg (ÉÉÉÉ-HH-NN-ÓÓMM kell): $IDO"
	fi
	for eszkoz in flock tar sha256sum; do
		command -v "$eszkoz" > /dev/null || kilep "$EX_ENV" "hiányzik a(z) $eszkoz parancs"
	done
	if [ ! -d "$FORRAS" ] || [ ! -r "$FORRAS" ]; then
		kilep "$EX_NOSRC" "a forrás nem létező vagy nem olvasható könyvtár: $FORRAS"
	fi
	FORRAS=$(cd -- "$FORRAS" && pwd -P)
	case "$(realpath -m -- "$CEL")/" in
		"$FORRAS"/*) kilep "$EX_USAGE" "a célkönyvtár nem lehet a forráskönyvtáron belül: $CEL" ;;
	esac
	if ! mkdir -p -- "$CEL" 2> /dev/null || [ ! -w "$CEL" ]; then
		kilep "$EX_ENV" "a célkönyvtár nem hozható létre vagy nem írható: $CEL"
	fi
	CEL=$(cd -- "$CEL" && pwd -P)
	NEV="mentes-$IDO"
}

mentesek() {
	find "$CEL" -maxdepth 1 -type f -name 'mentes-*.tar.gz' -printf '%f\n' |
		grep -E '^mentes-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}\.tar\.gz$' | sort || true
}

naplo_beallit() {
	[ -n "$LOG" ] || LOG="$CEL/mentes.log"
	case "$LOG" in /*) ;; *) LOG="$PWD/$LOG" ;; esac
	if ! : 2> /dev/null >> "$LOG"; then
		LOG=""
		kilep "$EX_ENV" "a naplófájl nem írható"
	fi
}

zarol() {
	exec 9> "$CEL/.mentes.lock"
	if ! flock -n 9; then
		log "már fut egy mentés ($CEL), ez a példány kilép"
		echo "Már fut egy mentés ide: $CEL; ez a példány kilép." >&2
		exit "$EX_BUSY"
	fi
	if [ -n "$(find "$CEL" -maxdepth 1 -type d -name '.work.*' -print -quit)" ]; then
		find "$CEL" -maxdepth 1 -type d -name '.work.*' -exec rm -rf -- {} +
		log "megszakadt korábbi futás maradványai törölve (.work.*)"
	fi
}

keszit() {
	local kod=0 arch hash db meret
	[ ! -e "$CEL/$NEV.tar.gz" ] || kilep "$EX_FAIL" "már van ilyen nevű mentés: $NEV.tar.gz"
	WORK=$(mktemp -d "$CEL/.work.XXXXXX")
	arch="$WORK/$NEV.tar.gz"
	tar -czf "$arch" -C "$(dirname -- "$FORRAS")" -- "$(basename -- "$FORRAS")" 2>> "$LOG" || kod=$?
	[ "$kod" -lt 2 ] || kilep "$EX_FAIL" "a tar hibával leállt (kód: $kod)"
	[ "$kod" -eq 0 ] || log "figyelmeztetés: a forrás futás közben változott (tar kód: $kod)"
	tar -tzf "$arch" > "$WORK/lista" 2>> "$LOG" || kilep "$EX_FAIL" "a friss archívum nem olvasható vissza"
	db=$(grep -vc '/$' "$WORK/lista" || true)
	meret=$(stat -c %s "$arch")
	hash=$(sha256sum < "$arch" | cut -d' ' -f1)
	printf '%s  %s\n' "$hash" "$NEV.tar.gz" > "$WORK/$NEV.sha256"
	printf 'mentes=%s.tar.gz\nkeszult=%s\nforras=%s\nmeret_bajt=%s\nfajlok_szama=%s\nsha256=%s\n' \
		"$NEV" "$(date '+%F %T %z')" "$FORRAS" "$meret" "$db" "$hash" > "$WORK/$NEV.meta"
	mv -- "$WORK/$NEV.meta" "$WORK/$NEV.sha256" "$arch" "$CEL/"
	log "kész: $NEV.tar.gz ($meret bájt, $db fájl, sha256: $hash)"
	(cd "$CEL" && sha256sum -c --status -- "$NEV.sha256") || kilep "$EX_FAIL" "a kész mentés ellenőrzőösszege nem egyezik"
	log "ellenőrzés: a kész mentés sha256-ja egyezik"
}

retencio() {
	local lista=() db nev
	mapfile -t lista < <(mentesek)
	db=${#lista[@]}
	if [ "$db" -le "$KEEP" ]; then
		log "retenció: $db mentés van (megtartandó: $KEEP), nincs törlés"
		return 0
	fi
	for nev in "${lista[@]:0:db-KEEP}"; do
		rm -f -- "$CEL/$nev" "$CEL/${nev%.tar.gz}.sha256" "$CEL/${nev%.tar.gz}.meta"
		log "retenció: törölve: $nev"
	done
}

main() {
	trap 'tisztit' EXIT
	trap 'echo "Megszakítva, takarítok..." >&2; exit 130' INT
	trap 'echo "Leállítva, takarítok..." >&2; exit 143' TERM
	parse_args "$@"
	ellenoriz_bemenet
	naplo_beallit
	zarol
	log "indul: pid=$$ felhasználó=$(id -un) cwd=$PWD bejövő_PATH=${INDULO_PATH:-(üres)} PATH=$PATH forrás=$FORRAS cél=$CEL megtart=$KEEP"
	keszit
	retencio
	log "vége: siker"
	echo "OK: $NEV.tar.gz"
	return "$EX_OK"
}

main "$@"