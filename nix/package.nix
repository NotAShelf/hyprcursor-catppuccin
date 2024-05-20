{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  unzip,
  rename,
  hyprcursor,
  xcur2png,
}: let
  dimensions = {
    palette = ["Frappe" "Latte" "Macchiato" "Mocha"];
    color = ["Blue" "Dark" "Flamingo" "Green" "Lavender" "Light" "Maroon" "Mauve" "Peach" "Pink" "Red" "Rosewater" "Sapphire" "Sky" "Teal" "Yellow"];
  };

  product = lib.attrsets.cartesianProductOfSets dimensions;
  variantName = {
    palette,
    color,
  }:
    (lib.strings.toLower palette) + color;
  variants = map variantName product;

  name = "hyprcursor-catppuccin";
  version = "0.2.0";
  src = builtins.path {
    name = "hyrcursor-catppuccin";
    path = fetchFromGitHub {
      owner = "catppuccin";
      repo = "cursors";
      rev = "refs/tags/v0.2.0";
      sha256 = "sha256-TgV5f8+YWR+h61m6WiBMg3aBFnhqShocZBdzZHSyU2c=";
      sparseCheckout = ["cursors"]; # zipped cursors
    };
  };
in
  stdenvNoCC.mkDerivation {
    inherit name version src;

    outputs = variants ++ ["out"];
    outputsToInstall = [];

    nativeBuildInputs = [hyprcursor xcur2png unzip rename];

    phases = ["unpackPhase" "installPhase"];
    installPhase = ''
      runHook preInstall

      mkdir -p $out

      for output in $(getAllOutputNames); do
        if [ "$output" != "out" ]; then
          local outputDir="''${!output}"

          # Convert to kebab case with the first letter of each word capitalized
          local variant=$(sed 's/\([A-Z]\)/-\1/g' <<< "$output")
          local variant=''${variant^}
          local name="Catppuccin-$variant-Cursors"

          # unzip all cursor zipfiles
          local extracted=$(mktemp -d)

          # extract desired cursor theme
          unzip -q "$src"/cursors/"$name".zip -d "$extracted"


          # extract xcursor files from extracted cursor artifacts
          local build=$(mktemp -d)
          hyprcursor-util --extract "$extracted"/"$name" --output "$build"
          mv "$build"/extracted_"$name" "$build"/cursors

          # generate Hyprcursor theme
          echo -en "
          name = $name
          description = Catppuccin Cursors for Hyprcursor
          version = ${version}
          cursors_directory = hyprcursors
          " > "$build"/cursors/manifest.hl

          hyprcursor-util --create "$build"/cursors --output "$build"
          mv "$build"/theme_"$name" "$outputDir"
        fi
      done

      runHook postInstall
    '';

    meta = {
      description = "Soothing pastel mouse cursors";
      homepage = "https://github.com/catppuccin/cursors";
      license = lib.licenses.gpl3Plus;
      maintainers = with lib.maintainers; [NotAShelf];
      platforms = lib.platforms.linux;
    };
  }
