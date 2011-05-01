itunes_insert_artwork
=====

iTunes makes it really easy to download album art for an entire music library in one fell swoop (select-all, Advanced->Get Album Artwork). It's a little trickier to embed the artwork into the MP3s themselves. [Teridon](http://mysite.verizon.net/teridon/itunesscripts/index.html)'s [itunes_insert_artwork](http://mysite.verizon.net/teridon/itunesscripts/itunes_insert_artwork.txt) script makes it easy.

Unfortunately, a lot of the jpegs from iTunes are ridiculously large. Some 600x600 images weigh in at over 800 KB. (Re-encoding them even at 100% quality results in much smaller files.) So, I tweaked the script to send the images through ImageMagick first. (At quality 85, those 800K images come down to 200K.)

## Requirements ##

You'll need to have ImageMagick and PerlMagick installed. If you're using ActivePerl, you may need the older 5.8.x version to make it work.
