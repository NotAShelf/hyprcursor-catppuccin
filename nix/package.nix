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

  catppuccin-cursor-src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "cursors";
    rev = "ref/tags/0.2.0";
    sha256 = "sha256-TgV5f8+YWR+h61m6WiBMg3aBFnhqShocZBdzZHSyU2c=";
    sparseCheckout = ["cursors"];
  };
in
  stdenvNoCC.mkDerivation {
    pname = "hyprcursor-catppuccin";
    version = "0.2.0";

    src = builtins.path {
      path = catppuccin-cursor-src;
      name = "hyrcursor-catppuccin";
    };

    outputs = variants ++ ["out"];
    outputsToInstall = [];

    nativeBuildInputs = [hyprcursor xcur2png unzip rename];

    phases = ["unpackPhase" "installPhase"];
    installPhase = ''
      runHook preInstall

      echo "Extracting Catppuccin cursors..."
      mkdir -p $out/{extracted,hyprcursor}


      # unzip all cursor zipfiles
      directory="$src/cursors"
      for zipfile in "$directory"/*.zip; do
        unzip -q "$zipfile" -d "$out/extracted"
      done

      for output in $(getAllOutputNames); do
        if [ "$output" != "out" ]; then
          local outputDir="''${!output}"
          local iconsDir="$outputDir"/share/icons

          mkdir -p "$iconsDir"

          # Convert to kebab case with the first letter of each word capitalized
          local variant=$(sed 's/\([A-Z]\)/-\1/g' <<< "$output")
          local variant=''${variant^}
          local name="Catppuccin-$variant-Cursors"

          # convert xcursor to hyprcursor format
          hyprcursor-util --extract "$out/extracted/$name" --output "$out/hyprcursor";

          # sanitize extracted cursor directory names
          rename 's/^extracted_//' "$out/hyprcursor/extracted_*"
          echo "Finished extracting Catppuccin cursors."

          # move extracted cursor artifact to the icon dir
          # it'll be located in extracted-cursors/extracted
          cp -rv "$out/hyprcursor/extracted_$name" "$iconsDir/$name"
        fi
      done

      runHook postInstall
    '';

    # TODO: in fixupPhase, patch manifest to properly define name, description and version

    meta = {
      description = "Soothing pastel mouse cursors";
      homepage = "https://github.com/catppuccin/cursors";
      license = lib.licenses.gpl3Plus;
      maintainers = with lib.maintainers; [NotAShelf];
      platforms = lib.platforms.linux;
    };
  }
