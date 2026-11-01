#!/usr/bin/env bash
#
# URL-listából tölt le: újrapróbál, atomi írással ír, naplóz, összegez
#
# Használat: ./letoltő.sh [-h] URL_LISTA [CÉLKÖNYVTÁR]
#   URL_LISTA    szövegfájl, soronként egy URL 
#   CÉLKÖNYVTÁR  ide kerülnek a kész fájlok (alapból: ./letoltesek)
# Napló: ./letolto.log (a LETOLTO_LOG környezeti változóval felülírható)
# Kilépési kód: 0: minden letöltés sikerült
#               1: volt sikertelen letöltés
#               2: hibás használat 
#               3: az URL-lista nem olvasható;
#               4: a környezet nem megfelelő (nincs curl)

set -euo pipefail

readonly EX_OK=0 EX_FAIL=1 EX_USAGE=2 EX_NOLIST=3 EX_ENV=4
readonly MAX_UJRA=3 
readonly CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-10}"
readonly MAX_TIME="${MAX_TIME:-30}"
readonly LOG="${LETOLTO_LOG:-./letolto.log}"

LISTA=""
CEL=""
WORK="" 
SIKERES=0
HIBAK=()

KOD=0 HTTP="" HIBA_OK=""

usage() {
	cat <<EOF
Használat: ${0##*/} [-h] URL_LISTA [CÉLKÖNYVTÁR]

Letölti az URL_LISTA soronként megadott címeit a CÉLKÖNYVTÁRBA (alapból: ./letoltesek).
Hálózati hibánál legfeljebb $MAX_UJRA-szor újrapróbál (1s, 2s, 4s várakozással), a kész fájl
csak teljes letöltés után kerül a helyére. A napló: $LOG
Kilépési kód: 0 minden sikerült, 1 volt sikertelen letöltés, 2 hibás használat,
              3 a lista nem olvasható, 4 a környezet nem megfelelő.
EOF
}

log() {
	printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}

tisztit() {
	local kod=$?
	if [ -n "$WORK" ]; then
		rm -rf -- "$WORK"
		log "takarítás kész, kilépési kód: $kod"
	fi
}

parse_args() {
	case "${1:-}" in
		-h | --help) usage; exit "$EX_OK" ;;
		-?*) echo "Hiba: ismeretlen kapcsoló: $1" >&2; usage >&2; exit "$EX_USAGE" ;;
	esac
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		usage >&2
		exit "$EX_USAGE"
	fi
	LISTA=$1
	CEL=${2:-./letoltesek}
	CEL=${CEL%/}
}

ellenoriz_bemenet() {
	if [ ! -f "$LISTA" ] || [ ! -r "$LISTA" ]; then
		echo "Hiba: az URL-lista nem létezik vagy nem olvasható: $LISTA" >&2
		exit "$EX_NOLIST"
	fi
	if ! command -v curl > /dev/null; then
		echo "Hiba: a curl nincs telepítve." >&2
		exit "$EX_ENV"
	fi
	if ! mkdir -p -- "$CEL" 2> /dev/null || [ ! -w "$CEL" ]; then
		echo "Hiba: a célkönyvtár nem írható: $CEL" >&2
		exit "$EX_ENV"
	fi
	if ! : 2> /dev/null >> "$LOG"; then
		echo "Hiba: a naplófájl nem írható: $LOG" >&2
		exit "$EX_ENV"
	fi
}

kimenet_nev() {
	local nev=${1#*://}
	nev=${nev//[^A-Za-z0-9._-]/_}
	printf '%s\n' "${nev:0:150}"
}

hiba_szoveg() { 
	case "$1" in
		0) echo "üres válasz" ;; 
		6) echo "a név nem oldható fel" ;;
		7) echo "nem sikerült kapcsolódni" ;;
		28) echo "időtúllépés ($MAX_TIME s)" ;;
		22) echo "HTTP hiba: $2" ;;
		*) echo "curl hiba (kód: $1)" ;;
	esac
}

vegleges_hiba() { 
	[ "$1" -eq 22 ] || return 1
	case "$2" in
		408 | 429) return 1 ;;
		4[0-9][0-9]) return 0 ;;
		*) return 1 ;;
	esac
}


probal_egyszer() { 
	rm -f -- "$2"
	KOD=0
	HTTP=$(curl --silent --show-error --location --fail \
		--connect-timeout "$CONNECT_TIMEOUT" --max-time "$MAX_TIME" \
		--output "$2" --write-out '%{http_code}' "$1" 2> "$WORK/curl.err") || KOD=$?
}

helyre_tesz() { 
	if mv -f -- "$1" "$2"; then
		log "kész: $2 ($(($(wc -c < "$2"))) bájt)"
	else
		HIBA_OK="a célfájl nem írható: $2"
	fi
}

letolt_egyet() { 
	local url=$1 cel=$2 tmp="$WORK/letoltes.part"
	local ujra=0 varakozas=1
	HIBA_OK=""
	while true; do
		log "kísérlet $((ujra + 1))/$((MAX_UJRA + 1)): $url"
		probal_egyszer "$url" "$tmp"
		if [ "$KOD" -eq 0 ] && [ -s "$tmp" ]; then
			helyre_tesz "$tmp" "$cel"
			return 0
		fi
		HIBA_OK=$(hiba_szoveg "$KOD" "$HTTP")
		log "sikertelen: $HIBA_OK; $(tr '\n' ' ' < "$WORK/curl.err")"
		if vegleges_hiba "$KOD" "$HTTP"; then
			log "végleges hiba, nem próbálom újra"
			return 0
		fi
		if [ "$ujra" -ge "$MAX_UJRA" ]; then
			HIBA_OK="$HIBA_OK ($((ujra + 1)) kísérlet után)"
			log "feladom: $url"
			return 0
		fi
		ujra=$((ujra + 1))
		log "újrapróbálkozás $ujra/$MAX_UJRA, várakozás: ${varakozas}s"
		sleep "$varakozas"
		varakozas=$((varakozas * 2))
	done
}

feldolgoz() {
	local url cel db=0
	while IFS= read -r url || [ -n "$url" ]; do
		url=${url//[[:space:]]/}
		if [ -z "$url" ] || [ "${url:0:1}" = "#" ]; then
			continue
		fi
		db=$((db + 1))
		cel="$CEL/$(kimenet_nev "$url")"
		log "[$db] indul: $url -> $cel"
		letolt_egyet "$url" "$cel"
		if [ -z "$HIBA_OK" ]; then
			SIKERES=$((SIKERES + 1))
			printf 'OK    %s\n' "$url"
		else
			HIBAK+=("$url"$'\t'"$HIBA_OK")
			printf 'HIBA  %s\n' "$url"
		fi
	done < "$LISTA"
}

osszefoglalo() {
	local sor
	printf '\nÖsszefoglaló: %d sikerült, %d nem sikerült (összesen %d)\n' \
		"$SIKERES" "${#HIBAK[@]}" "$((SIKERES + ${#HIBAK[@]}))"
	log "összefoglaló: $SIKERES sikerült, ${#HIBAK[@]} nem sikerült"
	if [ "${#HIBAK[@]}" -gt 0 ]; then
		echo "Sikertelen letöltések:"
		for sor in "${HIBAK[@]}"; do
			printf '\t%s - %s\n' "${sor%%$'\t'*}" "${sor#*$'\t'}"
		done
	fi
	printf 'Naplófájl: %s\n' "$LOG"
}

main() {
	trap 'tisztit' EXIT
	trap 'echo "Megszakítva, takarítok..." >&2; exit 130' INT
	trap 'echo "Leállítva, takarítok..." >&2; exit 143' TERM
	parse_args "$@"
	ellenoriz_bemenet
	WORK=$(mktemp -d "$CEL/.letoltes.XXXXXX")
	log "indul: lista=$LISTA cél=$CEL"
	feldolgoz
	osszefoglalo
	if [ "${#HIBAK[@]}" -gt 0 ]; then
		return "$EX_FAIL"
	fi
	return "$EX_OK"
}

main "$@"