###############################################################################
#
# itunes_insert_artwork.pl
#
# This script will tag your files using artwork downloaded using iTunes 7
#
# written by: Robert Jacobson (http://home.comcast.net/~teridon73/itunesscripts)
# Last Updated: 03 Jan 2007
# Version 1.0
#
# ImageMagick modification by: Russell Davis (https://github.com/russelldavis)
# This version will send all images through ImageMagick for better compression.
#
# This script is GPL v2.  see http://www.gnu.org/copyleft/gpl.html
#
# Use option "-k" to keep the artwork files extracted 
# (in the same location as the song file)
# (the default is to remove the files)
###############################################################################

use File::Basename;
my $PROGNAME = basename($0);
my $VERSION = "1.0";
my $AUTHOR = "Robert Jacobson";
my $HOMEPAGE = "http://home.comcast.net/~teridon73/";
my $YEAR = 2007;
my $GNU_URL = "http://www.gnu.org/copyleft/gpl.html";

{
	print
	"**************************************************************\n" .
	"$PROGNAME version $VERSION, Copyright (C) $YEAR $AUTHOR\n" .
	"Visit $HOMEPAGE for updates\n" . 
	"$PROGNAME comes with ABSOLUTELY NO WARRANTY;\n".
	"This is free software, and you are welcome\n" .
	"to redistribute it under certain conditions\n" .
	"for details see $GNU_URL.\n" .
	"**************************************************************\n" .
	"\n"
	;
}

use strict;
use Win32::OLE;

use Data::Dumper;
use File::Basename;
use Getopt::Std;
use Image::Magick;
  
# Create a signal handler to destroy the iTunes object
# in case our program quits before the end
use sigtrap 'handler', \&quit, 'normal-signals';

my %artformat = (
	0 => 'Unknown',
	1 => 'JPEG',
	2 => 'PNG',
	3 => 'BMP',
);

my %artformat_ext = (
	0 => 'unk',
	1 => 'jpg',
	2 => 'png',
	3 => 'bmp',
	);

getopts('k');

## Create the OLE Object
my $iTunes = Win32::OLE->new('iTunes.Application') or die Win32::OLE->LastError();

# Check version first!
my $version = $iTunes->Version;
if ($version !~ /^7/) {
	print "Sorry, this script requires iTunes 7\n";
	quit();
}


# Get the possible sources
my $sources = $iTunes->Sources();
my $sourcesCount = $sources->Count();
my $source = '';
my $sourceKind = '';

my $n = 1;

my $remove_files = 1;

our $opt_k;

if ($opt_k) {
	$remove_files = 0;
} else {
	print "Keep extracted image files? [n] ";
	chomp(my $answer = <STDIN>);
	if ($answer =~ /^y/i) {
		$remove_files = 0;
	}
}

# For each source, figure out kind	
for ($n = 1; $n <= $sourcesCount; $n++) {
	$source = $sources->Item($n);
	$sourceKind = $source->Kind();
# 	print "source no. " . $n . " is ";
# 	print $sourceKind . " -- ";
	
	if ($sourceKind == 0) {
		print "Unknown Source\n"; }
	if ($sourceKind == 1) {
		print "Library Source\n";
		# Get the playlists in the Library
		my $playlists = $source->Playlists();
		my $num_playlists = $playlists->Count();
		print "There are $num_playlists playlists\n";
		
		# For each playlist, show the name and number of tracks
		for (my $j = 1 ; $j <= $num_playlists; $j++) {
			my $playlist = $playlists->Item($j);
			my $playlist_name = $playlist->Name();
			print "\t$j : $playlist_name\n";
		}
		
		print "Enter comma-separated playlist numbers: ";
		chomp (my $nums = <STDIN>);
		my @nums = split(/,/ , $nums);
		for my $i (@nums) {
			my $playlist = $playlists->Item($i);
			my $playlist_name = $playlist->Name();
			print "You selected $playlist_name\n";
			
			my $tracks = $playlist->Tracks;
			my $num_tracks = $tracks->Count();
			print "\t$num_tracks tracks\n";
			
			my %seen;
			# Get all the tracks in the playlist
			for (my $k = 1 ; $k <= $tracks->Count ; $k++ ) {
				#print "num: " , $num_tracks , " Count: ",  $tracks->Count , " k: ", $k , "\n";
				my $track = $tracks->Item($k);
				my $track_kind = $track->Kind();

				if ($track_kind == 1) {
					my $count = $track->Artwork->Count;
					if ($count > 1) {
						print "ERROR - found file with more than one artwork " . $track->Name . "\n";
					}
					for (my $c = 1 ; $c <= $count ; $c++) {
						my $artwork = $track->Artwork->Item($c);
						if ($artwork->IsDownloadedArtwork) {
							my $name = $track->Name;
							my $album = $track->Album;
							print "name is \"$name\"\talbum: \"$album\"\n";
							my $format = $artwork->Format;
							my($fnFile, $fnDir, $fnExt) = fileparse($track->Location, qr/\.[^.]*/);
							my $fnBase = $fnDir . $fnFile;
							my $filename = $fnBase . ".art.orig." . $artformat_ext{$format};
							my $compressedFilename = $fnBase . ".art." . $artformat_ext{$format};
							
							$artwork->SaveArtworkToFile($filename);
							if (not -s $filename) {
								print "ERROR saving file $filename\n";
							} else {
								# Get the file down to a reasonable size (many of the jpegs from itunes images are over 500K)
  								my $image = new Image::Magick;
  								$image->Read($filename);
  								$image->Set(quality=>'85');
  								my $err = $image->Write($compressedFilename);
  								if ($err || not -s $compressedFilename) {
  									print "ERROR compressing $name: $err\n";
  								} else {
	  								# insert into file
									print "inserting artwork file $compressedFilename\n";
									my $hr = $artwork->SetArtworkFromFile($compressedFilename);
									if ($hr < 0) {
										print "ERROR setting artwork: $hr\n";
									}
  								}
							}
							
							if ($remove_files) {
								unlink $filename;
								unlink $compressedFilename;
							}
						}
					}
				}

			}
		}
	}
}

# Destroy the object.  Otherwise zombie object will come back
# to haunt you
quit();

sub quit 
{
	# This destroys the object
	undef $iTunes;
	exit;
}
