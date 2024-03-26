#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob
current_dir=$(pwd)
# create a temporary directory to clone the repository
# this will be used to check out the repository and execute
# the build process
tmpdir=$(mktemp -d)
cursor_path="$tmpdir"/cursors

palette=("Frappe" "Latte" "Macchiato" "Mocha")
color=("Blue" "Dark" "Flamingo" "Green" "Lavender" "Light" "Maroon" "Mauve" "Peach" "Pink" "Red" "Rosewater" "Sapphire" "Sky" "Teal" "Yellow")

VARIANT="Mocha-Dark"
NAMED="hyprcursor"
ANIMRATE="50"
CURSORDIR="$cursor_path"
ANIMONE="wait"
ANIMTWO="progress"

helpme() {
	echo "Usage: $0 [-v variant] [-n name] [-r rate] [-d dir] [-a anim-one] [-b anim-two]"
	echo ""
	echo "     Hyprcursor-Catppuccin"
	echo "           /ᐠ 、    "
	echo '        ミ(˚. 。*フ '
	echo '          |   ˜〵   '
	echo '          しし._)ノ '
	echo ""
	echo "  -v Set the variant (default: Mocha-Dark)"
	echo "  -n Theme name (default: hyprcursor)"
	echo "  -r Animation rate (default: 50)"
	echo "  -d Set cursor directory (recommend not touching this)"
	echo "  -a 1st animation (default: wait)"
	echo "  -b 2nd animation (default: progress)"
	exit 1
}

while getopts ":v:n:r:d:a:b:h" opt; do
	case ${opt} in
	v)
		VARIANT="$OPTARG"
		;;
	n)
		NAMED="$OPTARG"
		;;
	r)
		ANIMRATE="$OPTARG"
		;;
	d)
		CURSORDIR="$OPTARG"
		;;
	a)
		ANIMONE="$OPTARG"
		;;
	b)
		ANIMTWO="$OPTARG"
		;;
	h)
		helpme
		;;
	\?)
		echo "Invalid option: $OPTARG" 1>&2
		exit 1
		;;
	:)
		echo "Option -$OPTARG requires an argument." 1>&2
		exit 1
		;;
	esac
done
shift $((OPTIND - 1))

if ! [[ "$ANIMRATE" =~ ^[0-9]+$ ]]; then
	echo -e "\e[31mError: ANIMRATE argument is missing or not an integer. Defaulting to 50.\e[0m" >&2
	ANIMRATE="50"
fi

print_green() {
	echo -e "\e[32m$1\e[0m"
}

echo -en "Building in temporary directory: $tmpdir\n"

# Sparsely check out to the repository
# specifically to the src/ directory where
# vector (svg) versions of the Catppuccin cursors
# are located
git clone --depth=1 --filter=blob:none --sparse https://github.com/catppuccin/cursors "$cursor_path"
cd "$cursor_path" || exit
git sparse-checkout init --cone
git sparse-checkout set src/
echo -en "Cloned repository at $tmpdir/cursors\n"

if [ ! -d "$CURSORDIR" ]; then
	echo "Error: Directory '$CURSORDIR' does not exist."
	exit 1
fi

if [ -f "$CURSORDIR/manifest.hl" ]; then
	echo "Error: $CURSORDIR already has a manifest.hl file."
	exit 1
fi

result_array=() # initialize results array

for item in "${palette[@]}"; do
	for col in "${color[@]}"; do
		result="${item}-${col}"
		result_array+=("$result")
	done
done

# Check if the string is an element of the result array
if [[ "${result_array[@]}" =~ "${VARIANT}" ]]; then
	true

else
	echo "Invalid variant provided: $VARIANT"
	echo "Valid palettes: ${palette[*]}" >&2
	echo "Valid colors: ${color[*]}" >&2
	exit 1
fi

# if variant is not in the list, exit

# prepare directory, remove any extraneous files

echo -en "Step 1: Preparing directory\n"
cd "$CURSORDIR"/src/Catppuccin-"$VARIANT"-Cursors || exit
mkdir -p cursors "$ANIMONE" "$ANIMTWO" || exit # if mkdir fails for any reason, exit early
mv -v "$ANIMONE"-* "$ANIMONE"
mv -v "$ANIMTWO"-* "$ANIMTWO"

# create a containing folder with name of icon
echo -en "Step 2: Creating folders\n"
rm *_24.svg
for file in *.svg; do
	file_contents="
    resize_algorithm = bilinear
    define_size = 64, $file
    "
	direct="${file%.svg}"
	mkdir -- "$direct"
	mv -- "$file" "$direct"
	echo "$file_contents" >"$direct"/meta.hl
done

function process_meta() {
	local ANIM="$1"
	local output=""
	for i in {1..12}; do
		output+="define_size = 64, $ANIM-$(printf "%02d" "$i").svg,$ANIMRATE\n"
	done

	echo -e "resize_algorithm = bilinear\n$output" >"$ANIM"/meta.hl
}

echo -en "Step 3: Processing meta files\n"
process_meta "$ANIMONE"
process_meta "$ANIMTWO"

mv !(cursors) ./cursors
rm cursors/index.theme

# index.theme gen
echo "[Icon Theme]
Name=$NAMED
Comment=generated by hyprman
" >>index.theme

echo "name = $NAMED
description = let there be ants
version = 0.1
cursors_directory = cursors
" >>manifest.hl

hyprcursor-util --create .
echo -en "finished making $NAMED, copying to $current_dir"

cp -r ../theme_"$NAMED" "$current_dir"/"$NAMED"
