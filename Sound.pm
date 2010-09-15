#
#    Common: Shared library for voice-based applications.
#
#    Copyright (C) 2010 Nokia Corporation.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Authors: Billy Odero, Jonathan Ledlie

package Nokia::Common::Sound;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ('msg', 'init_sound', 'get_language_name');

use Digest::MD5 qw(md5_hex);
use File::Basename;
use strict;
use warnings;

######################################################################
# TODO As messages get solidified and recorded properly, put them in here.

my %msgs = ();
# TODO make this smarter so that it is not an absolute path
#my $snd_dir = '/home/mosoko/mosoko/trunk/sounds/';
#my $snd_dir_matt = "$snd_dir/matt/";
#my $snd_dir_charles = "$snd_dir/charles/";
#my $ast_snd_dir = '/var/lib/asterisk/sounds/';

my %language_id2name = ();

######################################################################
sub init_sound {
    my $self = shift;


    my $rs = $self->{server}{schema}->resultset('Languages');
    
    while (my $language = $rs->next) {
        $language_id2name{$language->language_id} = $language->name;
    }
    
}

######################################################################
sub get_language_name {
    my ($self, $language_id) = @_;
    
    if (defined ($language_id2name{$language_id})) {
	return $language_id2name{$language_id};
    }
    die ("No language for $language_id");
}

######################################################################
sub msg {
    my ($self, $words) = @_;

    if (!defined ($self) || !defined($words)) {
	my @func = (caller(1));

	if (!defined ($self)) {
	    print STDERR ("self not def\n");
	} 
	if (!defined($words)) {
	    print STDERR ("words not def\n");
	}

	die ("bad call to msg from $func[3] line $func[2]");
    }

    $self->log (4, "language= ".$self->{user}->{language});
    $self->log (4, "words= ".$words);

    my $lang_words = $self->{user}->{language}.'/'.$words;

    if (defined($msgs{$lang_words})) {
	$self->log (4, "found msg in hash: $lang_words");
	return $msgs{$lang_words};
    }

    die("sound_path not defined. ".
	"Check if sound_path parameter is defined ".
	"in the agi file") if (!defined($self->get_property('sound_path')));

    $self->log (4, "searching directories for: $lang_words");
    foreach my $snd_dir (split(/:/,$self->get_property('sound_path'))) {

	# if the sound file exists, add it to the msgs hash
	# (we won't check for it again)
	
	$self->log (4, "looking for ".
		    "$snd_dir"."$lang_words.sln");


	# first look for it with a language prefix

	if (-e "$snd_dir"."$lang_words.sln" ||
	    -e "$snd_dir"."$lang_words.gsm" ||
	    -e "$snd_dir"."$lang_words.wav" ) {
	    $self->log (4, "sound (lang) found $lang_words in $snd_dir");
	    $msgs{$lang_words} = $snd_dir.$lang_words;
	    return $msgs{$lang_words};
	}

	$self->log (4, "looking for ".
		    "$snd_dir"."$words.sln");

	if (-e "$snd_dir"."$words.sln" ||
	    -e "$snd_dir"."$words.gsm" ||
	    -e "$snd_dir"."$words.wav" ) {
	    $self->log (4, "sound (no lang) found $words in $snd_dir");
	    $msgs{$lang_words} = $snd_dir.$words;
	    return $msgs{$lang_words};
	}

    }

    # if it doesn't exist, take the input words and
    # make a text-to-speech prompt

    $self->log (2, "tts $words");
    $words =~ s/_/ /g;
    $words =~ s/-/ /g;
    $msgs{$lang_words} = &getTTSFilename($self, $words);
    return $msgs{$lang_words};

}

######################################################################

# location of the wave file cache and working directory
my $SOUNDDIR = "/var/lib/asterisk/festivalcache/";

# festival text2wave location 
my $T2WDIR= "/usr/bin/";

################################################################################
# sub getTTSFilename 
# http://search.cpan.org/src/JAMESGOL/asterisk-perl-0.10/examples/directory.agi
################################################################################
# 
sub getTTSFilename {
  
    my ($self, $text) = @_;

    my $hash = md5_hex($text);
    my $wavefile = "$SOUNDDIR"."tts-diirectory-$hash.wav";

    unless( -f $wavefile ) {
	$self->log (1, "missing sound: $text");
	open( fileOUT, ">$SOUNDDIR"."say-text-$hash.txt" );
	print fileOUT "$text";
	close( fileOUT );
	my $execf=$T2WDIR."text2wave $SOUNDDIR"."say-text-$hash.txt -F 8000 -o $wavefile";
	system( $execf );
	unlink( $SOUNDDIR."say-text-$hash.txt" );
    }

    return "$SOUNDDIR".basename($wavefile,".wav");
} # sub getTTSFilename 



1;
