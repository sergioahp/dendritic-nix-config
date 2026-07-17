# Vendored color helpers. The canonical color representation across the repo
# is a hex string: "#rgb", "#rgba", "#rrggbb" or "#rrggbbaa" (case
# insensitive). Transforms take and return hex strings so they compose;
# formatters ("to*") go from a hex string to some app-native textual format.
# Underscore prefix keeps this file out of import-tree's module auto-import;
# consumers do `import ./theme/_color-lib.nix { inherit lib; }`.
{ lib }:

let
  inherit (builtins) floor stringLength substring elemAt;

  hexDigit = {
    "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4;
    "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
    a = 10; b = 11; c = 12; d = 13; e = 14; f = 15;
  };

  hexToInt = s:
    lib.foldl' (acc: ch: acc * 16 + hexDigit.${ch}) 0
      (lib.stringToCharacters (lib.toLower s));

  hexChars = "0123456789abcdef";
  byteToHex = n: substring (n / 16) 1 hexChars + substring (lib.mod n 16) 1 hexChars;

  clamp = lo: hi: x: if x < lo then lo else if x > hi then hi else x;
  round = x: floor (x + 0.5);
  abs = x: if x < 0 then 0 - x else x;
  fmod = x: y: x - y * floor (x / y); # result in [0, y) for y > 0

  # -> { r g b a }, each 0-255
  parse = s:
    let
      body = if substring 0 1 s == "#" then substring 1 (stringLength s - 1) s else s;
      len = stringLength body;
      nibble = i: hexToInt (substring i 1 body + substring i 1 body);
      byte = i: hexToInt (substring i 2 body);
    in
    if len == 3 then { r = nibble 0; g = nibble 1; b = nibble 2; a = 255; }
    else if len == 4 then { r = nibble 0; g = nibble 1; b = nibble 2; a = nibble 3; }
    else if len == 6 then { r = byte 0; g = byte 2; b = byte 4; a = 255; }
    else if len == 8 then { r = byte 0; g = byte 2; b = byte 4; a = byte 6; }
    else throw "color-lib: cannot parse color ${toString s}";

  fromRgba = { r, g, b, a ? 255 }:
    let byte = v: byteToHex (clamp 0 255 v);
    in "#" + byte r + byte g + byte b + (if a == 255 then "" else byte a);

  # h in [0,360), s/l in [0,1], a stays 0-255
  rgbToHsl = { r, g, b, a ? 255 }:
    let
      rf = r / 255.0;
      gf = g / 255.0;
      bf = b / 255.0;
      mx = lib.max rf (lib.max gf bf);
      mn = lib.min rf (lib.min gf bf);
      l = (mx + mn) / 2.0;
      d = mx - mn;
      s = if d == 0.0 then 0.0 else d / (1.0 - abs (2.0 * l - 1.0));
      h6 =
        if d == 0.0 then 0.0
        else if mx == rf then fmod ((gf - bf) / d) 6.0
        else if mx == gf then (bf - rf) / d + 2.0
        else (rf - gf) / d + 4.0;
    in { h = h6 * 60.0; inherit s l a; };

  hslToRgb = { h, s, l, a ? 255 }:
    let
      c = (1.0 - abs (2.0 * l - 1.0)) * s;
      h6 = fmod (h / 60.0) 6.0;
      x = c * (1.0 - abs (fmod h6 2.0 - 1.0));
      rgb1 =
        if h6 < 1.0 then [ c x 0.0 ]
        else if h6 < 2.0 then [ x c 0.0 ]
        else if h6 < 3.0 then [ 0.0 c x ]
        else if h6 < 4.0 then [ 0.0 x c ]
        else if h6 < 5.0 then [ x 0.0 c ]
        else [ c 0.0 x ];
      m = l - c / 2.0;
      byte = v: round (clamp 0.0 255.0 ((v + m) * 255.0));
    in { r = byte (elemAt rgb1 0); g = byte (elemAt rgb1 1); b = byte (elemAt rgb1 2); inherit a; };

  onHsl = f: s: fromRgba (hslToRgb (f (rgbToHsl (parse s))));

  # "0.8" rather than "0.800000": up to 3 decimals, trailing zeros trimmed
  alphaDecimal = a:
    let
      milli = round (a * 1000.0 / 255.0);
      trimmed = lib.concatStrings (lib.foldr
        (ch: acc: if acc == [ ] && ch == "0" then [ ] else [ ch ] ++ acc)
        [ ]
        (lib.stringToCharacters (lib.fixedWidthNumber 3 milli)));
    in
    if milli >= 1000 then "1"
    else if milli <= 0 then "0"
    else "0." + trimmed;

in
{
  inherit parse onHsl;

  # transforms: hex -> hex

  # set the alpha channel; alpha is a float in [0,1]
  withAlpha = s: alpha:
    fromRgba (parse s // { a = round ((clamp 0.0 1.0 alpha) * 255.0); });

  # multiply the existing alpha channel by a factor
  scaleAlpha = s: factor:
    let c = parse s;
    in fromRgba (c // { a = round (clamp 0.0 255.0 (c.a * factor)); });

  # linear per-channel blend (alpha included); t = 0 -> s1, t = 1 -> s2
  mix = s1: s2: t:
    let
      c1 = parse s1;
      c2 = parse s2;
      lerp = v1: v2: round (clamp 0.0 255.0 (v1 + (v2 - v1) * t));
    in fromRgba {
      r = lerp c1.r c2.r;
      g = lerp c1.g c2.g;
      b = lerp c1.b c2.b;
      a = lerp c1.a c2.a;
    };

  # HSL lightness/saturation shifts; amount is an absolute delta in [0,1]
  darken = s: amount: onHsl (hsl: hsl // { l = clamp 0.0 1.0 (hsl.l - amount); }) s;
  lighten = s: amount: onHsl (hsl: hsl // { l = clamp 0.0 1.0 (hsl.l + amount); }) s;
  desaturate = s: amount: onHsl (hsl: hsl // { s = clamp 0.0 1.0 (hsl.s - amount); }) s;
  saturate = s: amount: onHsl (hsl: hsl // { s = clamp 0.0 1.0 (hsl.s + amount); }) s;

  # formatters: hex -> app-native string

  # "#rrggbb", alpha dropped (X resources and friends)
  toRgbHex = s: fromRgba (parse s // { a = 255; });

  # "#rrggbbaa", alpha always present
  toRgbaHex = s: let c = parse s; in
    "#" + byteToHex c.r + byteToHex c.g + byteToHex c.b + byteToHex c.a;

  # "rgba(r,g,b,a)" with a as a decimal in [0,1] (zathura/gdk)
  toRgbaCss = s: let c = parse s; in
    "rgba(${toString c.r},${toString c.g},${toString c.b},${alphaDecimal c.a})";

  # "rgb(r, g, b)" (hyprlock)
  toRgbCss = s: let c = parse s; in
    "rgb(${toString c.r}, ${toString c.g}, ${toString c.b})";
}
