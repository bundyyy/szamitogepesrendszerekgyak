#!/usr/bin/env bash
#
# logriport.sh - riport egy webszerver access logjáról
#
# Használat: ./logriport.sh <logfájl>
# Kilépési kód: 0: siker 
#               1: hiányzó paraméter, nem létező, olvashatatlan vagy üres fájl
               

if [ "$#" -ne 1 ]; then
	echo "Használat: $0 <logfájl>" >&2
	exit 1
fi
if [ ! -f "$1" ] || [ ! -r "$1" ]; then
	echo "Hiba: nem létező vagy nem olvasható fájl: $1" >&2
	exit 1
fi
if [ ! -s "$1" ]; then
	echo "Hiba: üres a logfájl: $1" >&2
	exit 1
fi

awk '
function cim(s) { printf "\n%s\n", s; fflush() }
function atl(nev, ossz, db) {
	if (db) printf "%s  %7.3f\n", nev, ossz / db
	else printf "%s  %7s\n", nev, "-"
}
{
	ip[$1]++
	st[$9]++
	if ($9 >= 400) hiba[$7]++
	split($4, d, ":")
	ora = substr(d[1], 2) " " d[2] ":00"
	if (!(ora in oraDb)) sorrend[++no] = ora
	oraDb[ora]++
	ossz += $NF
	if ($9 == 200) { ossz200 += $NF; db200++ }
	if ($9 == 500) { ossz500 += $NF; db500++ }
}
END {
	for (k in ip) {
		egyedi++
		if (ip[k] > max) { max = ip[k]; top = k }
	}
	printf "Kérések összesen:  %6d\n", NR
	printf "Egyedi IP-címek:   %6d\n", egyedi

	cim("A 10 legaktívabb IP (IP, kérések)")
	cmd = "sort -k2,2nr -k1,1 | head -10"
	for (k in ip) printf "%-16s %6d\n", k, ip[k] | cmd
	close(cmd)

	cim("Státuszkódok (kód, db, %)")
	cmd = "sort -n"
	for (k in st) printf "%-6s %6d %6.1f%%\n", k, st[k], 100 * st[k] / NR | cmd
	close(cmd)

	cim("Hibás kérések (4xx, 5xx) URL szerint (URL, db)")
	cmd = "sort -k2,2nr -k1,1"
	for (k in hiba) printf "%-24s %6d\n", k, hiba[k] | cmd
	close(cmd)

	cim("Kérések óránként (óra, db)")
	for (o in oraDb)
		if (oraDb[o] > oraMax) oraMax = oraDb[o]
	for (i = 1; i <= no; i++) {
		o = sorrend[i]
		printf "%-17s %6d%s\n", o, oraDb[o], (oraDb[o] == oraMax ? "  <- csúcs" : "")
	}

	cim("Átlagos válaszidő (mp)")
	atl("összes:", ossz, NR)
	atl("200-as:", ossz200, db200)
	atl("500-as:", ossz500, db500)

	printf "\nA legaktívabb IP a %s, ami az összes kérés %.1f%%-át adta.\n", top, 100 * max / NR
}
' "$1"