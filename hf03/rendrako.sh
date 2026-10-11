#!/usr/bin/env bash
#jelentés egy könyvtárról, kérésre rendrakás
#Használat: ./rendrako.sh [--rendezd] <könyvtár>
#   alapból csak jelentést ír, nem módosít semmit
#   --rendezd: kiírja a tervet, majd a fájlokat kiterjesztés szerint a
#              <könyvtár>/_rendezett/ alá másolja, és elveszi a mindenki
#              írhatja jogot 
#Kilépési kód: 
#   0: siker
#   nem 0: a könyvtár hiányzik vagy nem létezik

rendezd=0
dir=""
for arg in "$@"; do
	if [ "$arg" = "--rendezd" ]; then
		rendezd=1
	else
		dir="${arg%/}"
	fi
done

if [ -z "$dir" ]; then
	echo "Használat: $0 [--rendezd] <könyvtár>" >&2
	exit 1
fi
if [ ! -d "$dir" ]; then
	echo "Hiba: nem létező könyvtár: $dir" >&2
	exit 1
fi

kereses() {
	find "$dir" -mindepth 1 -type d -name _rendezett -prune -o "$@"
}

fajl_db=$(kereses -type f -print0 | tr -cd '\0' | wc -c)
iroh=()
while IFS= read -r -d '' f; do
	iroh+=("$f")
done < <(kereses -type f -perm -o+w -print0)

printf 'Fájlok: %s\n' "$fajl_db"
printf 'Könyvtárak: %s\n' "$(kereses -type d -print0 | tr -cd '\0' | wc -c)"
printf '30 napnál régebbi fájlok: %s\n' "$(kereses -type f -mtime +30 -print0 | tr -cd '\0' | wc -c)"

echo "5 legnagyobb fájl (bájt):"
kereses -type f -printf '%s\t%p\0' | sort -z -rn | head -z -n 5 | tr '\0' '\n' | sed 's/^/\t/'

echo "Üres fájlok:"
kereses -type f -empty -print0 | tr '\0' '\n' | sed 's/^/\t/'

echo "Kiterjesztések:"
kereses -type f -printf '%f\n' | sed -E 's/^\.//; /\./!s/.*/(nincs)/; s/.*\.//' | sort | uniq -c | sort -rn |
	while read -r db kit; do
		printf '\t%s\t%s\n' "$db" "$kit"
	done

echo "Mindenki számára írható fájlok:"
if [ "${#iroh[@]}" -gt 0 ]; then
	printf '\t%s\n' "${iroh[@]}"
fi

if [ "$rendezd" -eq 1 ]; then
	echo
	echo "Rendrakás terv:"
	printf '\t%s fájl másolása ide: %s/_rendezett/<kiterjesztés>/ (kiterjesztés nélkül: _egyeb/)\n' "$fajl_db" "$dir"
	printf '\tchmod o-w: %s fájlon\n' "${#iroh[@]}"

	for f in "${iroh[@]}"; do
		chmod o-w -- "$f" && printf '\tchmod o-w: %s\n' "$f"
	done

	while IFS= read -r -d '' f; do
		nev="${f##*/}"
		kit=""
		[[ "${nev#.}" == *.* ]] && kit="${nev##*.}"
		cel="$dir/_rendezett/${kit:-_egyeb}"
		mkdir -p -- "$cel"
		[ -e "$cel/$nev" ] || cp -p -- "$f" "$cel/"
	done < <(kereses -type f -print0)
fi

exit 0