branding="./branding"

drawable="$branding/res/drawable";
font="Montserrat-Bold";
wordmark="PolarBear";


convert -background transparent -fill black -font $font -gravity center -size x120 label:$wordmark $drawable/ic_wordmark_text_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x120 label:$wordmark $drawable/ic_wordmark_text_private.webp

convert -background transparent -fill black -font $font -gravity center -size x80 label:$wordmark $drawable-mdpi/ic_logo_wordmark_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x80 label:$wordmark $drawable-mdpi/ic_logo_wordmark_private.webp
convert -background transparent -fill black -font $font -gravity center -size x80 label:$wordmark $drawable-mdpi/ic_wordmark_text_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x80 label:$wordmark $drawable-mdpi/ic_wordmark_text_private.webp

convert -background transparent -fill black -font $font -gravity center -size x120 label:$wordmark $drawable-hdpi/ic_logo_wordmark_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x120 label:$wordmark $drawable-hdpi/ic_logo_wordmark_private.webp
convert -background transparent -fill black -font $font -gravity center -size x120 label:$wordmark $drawable-hdpi/ic_wordmark_text_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x120 label:$wordmark $drawable-hdpi/ic_wordmark_text_private.webp

convert -background transparent -fill black -font $font -gravity center -size x160 label:$wordmark $drawable-xhdpi/ic_logo_wordmark_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x160 label:$wordmark $drawable-xhdpi/ic_logo_wordmark_private.webp
convert -background transparent -fill black -font $font -gravity center -size x160 label:$wordmark $drawable-xhdpi/ic_wordmark_text_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x160 label:$wordmark $drawable-xhdpi/ic_wordmark_text_private.webp

convert -background transparent -fill black -font $font -gravity center -size x240 label:$wordmark $drawable-xxhdpi/ic_logo_wordmark_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x240 label:$wordmark $drawable-xxhdpi/ic_logo_wordmark_private.webp
convert -background transparent -fill black -font $font -gravity center -size x240 label:$wordmark $drawable-xxhdpi/ic_wordmark_text_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x240 label:$wordmark $drawable-xxhdpi/ic_wordmark_text_private.webp

convert -background transparent -fill black -font $font -gravity center -size x320 label:$wordmark $drawable-xxxhdpi/ic_logo_wordmark_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x320 label:$wordmark $drawable-xxxhdpi/ic_logo_wordmark_private.webp
convert -background transparent -fill black -font $font -gravity center -size x320 label:$wordmark $drawable-xxxhdpi/ic_wordmark_text_normal.webp
convert -background transparent -fill white -font $font -gravity center -size x320 label:$wordmark $drawable-xxxhdpi/ic_wordmark_text_private.webp



# icons
mipmap="$branding/res/mipmap"

convert $branding/logo.png -resize x155 -background transparent -gravity center -extent 155x160 $drawable/ic_wordmark_logo.webp

convert $branding/logo.png -resize x48 -background transparent -gravity center -extent 48x48 $mipmap-mdpi/ic_launcher.webp
convert $branding/logo.png -resize x72 -background transparent -gravity center -extent 72x72 $mipmap-hdpi/ic_launcher.webp
convert $branding/logo.png -resize x96 -background transparent -gravity center -extent 96x96 $mipmap-xhdpi/ic_launcher.webp
convert $branding/logo.png -resize x144 -background transparent -gravity center -extent 144x144 $mipmap-xxhdpi/ic_launcher.webp
convert $branding/logo.png -resize x192 -background transparent -gravity center -extent 192x192 $mipmap-xxxhdpi/ic_launcher.webp
