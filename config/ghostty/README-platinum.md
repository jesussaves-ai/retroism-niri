# Platinum terminal surface

`platinum-bg.png` gives the terminal its "paper" depth: subtle pinstripes,
a light-to-mid vertical gradient, and an inner shadow along the top edge.

Regenerate (ImageMagick):

```fish
cd ~/.config/ghostty
magick -size 4x4 xc:'#ffffff00' -fill '#00000014' -draw 'rectangle 0,0 3,0' /tmp/pin.png
magick -size 1920x1080 gradient:'#f8f8f8-#c3c3c3' \
  \( -size 1920x1080 tile:/tmp/pin.png \) -compose over -composite \
  \( -size 1920x60 gradient:'#00000033-#00000000' \) -gravity north -composite \
  -alpha off -type TrueColor PNG24:platinum-bg.png
```
