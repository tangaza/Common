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

######################################################################
# TODO As messages get solidified and recorded properly, put them in here.

my %msgs = ();
# TODO make this smarter so that it is not an absolute path
#my $snd_dir = '/home/mosoko/mosoko/trunk/sounds/';
#my $snd_dir_matt = "$snd_dir/matt/";
#my $snd_dir_charles = "$snd_dir/charles/";
#my $ast_snd_dir = '/var/lib/asterisk/sounds/';

my %language_id2name = ();

sub init_sound {
    my $self = shift;



    
    $self->{server}{select_languages_sth} =
	$self->{server}{dbi}->prepare_cached
	("select language_id, name from languages");
    $self->{server}{select_languages_sth}->execute ();


    my $languages = $self->{server}{select_languages_sth}->
	fetchall_arrayref
	({ language_id => 1, name => 1});

    for (my $l = 0; $l <= $#$languages; $l++) {
	$language_id2name{$languages->[$l]->{language_id}} =
	    $languages->[$l]->{name};

	#print STDERR "id $languages->[$l]->{language_id}\n";
	#print STDERR "name $languages->[$l]->{name}\n";

    }

    $self->{server}{select_languages_sth}->finish ();

    &init_sound_files ($self);
}

sub get_language_name {
    my ($language_id) = @_;
    if (defined ($language_id2name{$language_id})) {
	return $language_id2name{$language_id};
    }
    die ("No language for $language_id");
}

sub init_sound_files {
    my $self = shift;



    #$msgs{'main-menu'} =
#	&getTTSFilename('For housing, press 1, '.
#			'Jobs, press 2, '.
#			'Goods for sale, press 3, '.
#			'For other options, press 4 ');

#   $msgs{'secondary-menu'} =
#	&getTTSFilename('To edit your posts, press 1, '.
#			'To tell your friends about Mosoko, press 2, '.
#			'To leave a comment, press 3, '.
#			'To edit your profile, press 4');

    ############################################################
    # General

    # should default to installed sound dir
    $msgs{'beep'} = 'beep';

#    $msgs{'sorry-invalid-number'} = &getTTSFilename ("Sorry.  That phone number seems invalid.");

#    $msgs{'leave-comment-if-error'} =
#	&getTTSFilename ("Please leave a comment if you feel you have encountered an error.");

#    $msgs{'thank-you'} = &getTTSFilename("Thank you.");

#    $msgs{'goodbye'} = 	&getTTSFilename("Goodbye.");

 #   $msgs{'when-finished-press-pound'} = "$snd_dir_charles/when-finished-press-ound";
	#&getTTSFilename("When you are finished press pound.");

 #   $msgs{'record-message-at-beep'} =
	#&getTTSFilename("Record your comment at the beep.");

#    $msgs{'to-save-press-pound'} =
#	&getTTSFilename("Press pound to keep your message.");

#    $msgs{'to-cancel-press-star'} =
#	&getTTSFilename("Press star to cancel.");

#    $msgs{'yes-press-one-no-press-two'} =
#	&getTTSFilename("To indicate yes, press one. For no, press two.");

#    $msgs{'you-have'} = "$snd_dir/you-have";

#    $msgs{'matching-posts'} = "$snd_dir/you-have";

#    $msgs{'welcome-to-mosoko'} = "$snd_dir/welcome-to-mosoko";

#    $msgs{'about-mosoko'} =
#	&getTTSFilename("Mosoko is a project developed by Nokia Research and a group of voluteer developers.  For more information google Nokia Mosoko.");

    ############################################################
    # Generic Postings

    # This is already captured by the general section.
#    $msgs{'press star to cancel at any time'} =
#	&getTTSFilename('Press star to cancel at any time.');

#    $msgs{'creating-new-posting'} =
#	&getTTSFilename('Creating new posting.');

#    $msgs{'new-posting-created'} =
#	&getTTSFilename('New posting created.');

#    $msgs{'this-posting-will-expire-in-one-week'} =
#	&getTTSFilename('This posting will expire in one week.');

#    $msgs{'are-you-ready-to-create-the-posting'} =
#	&getTTSFilename('Are you ready to create the posting?');

#    $msgs{'too-many-postings'} =
#	&getTTSFilename('Sorry.  You have too many postings in this topic.  Please try again later.');

#    $msgs{'to-keep-your-recording'} =
#	&getTTSFilename('To keep your recording.  Press 1.  To hear your recording.  Press 2.  To record again.  Press 3.');

#    $msgs{'enter-a-location'} =
#	&getTTSFilename('Enter a location');

    ############################################################
    # Housing Specific

 #   $msgs{'housing-menu'} =
#	&getTTSFilename
#	('For apartments. Press 1. '.
#	 'For flatmates. Press 2.');

#    $msgs{'apartment-menu'} =
#	&getTTSFilename('To search for apartments. Press 1. '.
#			'To post a new apartment rental listing. Press 2.');

#    $msgs{'apartment-main-menu'} =
#	&getTTSFilename('Apartment Rentals Main Menu');

#    $msgs{'flatmate-menu'} =
#	&getTTSFilename('To search for a room to let, press 1, '.
#			'To post that you have a room to let, press 2');

#    $msgs{'flatmate-main-menu'} =
#	&getTTSFilename('Flatmate Main Menu');


#    $msgs{'create-housing-rental-posting-menu'} =
#	&getTTSFilename('Creating a new rental listing.');

#    $msgs{'create-flatmate-posting'} =
#	&getTTSFilename('Creating a new flatmate posting.');

#    $msgs{'flatmate-sex'} =
#	&getTTSFilename
#	('If men or women are OK. Press 1'.
#	 'If just wommen are OK. Press 2'.
#	 'If just men are OK. Press 3.');

#    $msgs{'flat-furnished'} =
#	&getTTSFilename
#	('Is the room furnished?');

#    $msgs{'are-you-a-broker'} =
#	&getTTSFilename('Are you a broker?');

#    $msgs{'is-there-a-rental-fee'} =
#	&getTTSFilename('Is there a rental fee?');

#    $msgs{'what-is-the-rent-per-month'} =
#	&getTTSFilename('What is the rent per month?');

#    $msgs{'how-many-bedrooms-are-there'} =
#	&getTTSFilename('How many bedrooms are there?');

#    $msgs{'is-the-apartment-available-now'} =
#	&getTTSFilename('Is the apartment available now?  Press 1 if it is available within the next month.  Press 2 if it is a future rental.');


    ############################################################
    # Telling Your Friends

 #   $msgs{'tell-sorry-invitations-limited'} = &getTTSFilename("Sorry only a limited number of invitations are allowed per day.  Please try again later.");

 #   $msgs{'tell-prompt'} = &getTTSFilename("Enter the phone number of a friend you want to invite to Mosoko. Press star to cancel.  Press pound when you are finished entering the number.");

 #   $msgs{'tell-sending-invitation'} = &getTTSFilename ("Sending invitation.");

 #   $msgs{'tell-sent'} =  &getTTSFilename ("You invitation has been sent.");

    ############################################################
    # Leaving a Comment

 #   $msgs{'cancelled-leaving-comment'} =
#	&getTTSFilename("You cancelled leaving a comment.");

#    $msgs{'comment-recorded'} = &getTTSFilename("Your comment was recorded.");

#    $msgs{'leave-comment'} =
#	&getTTSFilename("Please leave a comment, criticism, or suggestion for the Mosoko development team.");
	
#    $msgs{'too-many-comments'} =
#	&getTTSFilename("Sorry you have left too many comments recently.");

    ############################################################
    # Places

#    $msgs{'place-1_1-add'} = &getTTSFilename("To add Dagoretti, press 1");
#    $msgs{'place-1_1-remove'} = &getTTSFilename("To remove Dagoretti, press 1");
#    $msgs{'place-1_1-select'} = &getTTSFilename("For Dagoretti, press 1");

#    $msgs{'place-1_2-add'} = &getTTSFilename("To add Embakasi, press 2");
#    $msgs{'place-1_2-remove'} = &getTTSFilename("To remove Embakasi, press 2");
#    $msgs{'place-1_2-select'} = &getTTSFilename("For Embakasi, press 2");

 #   $msgs{'place-1_3-add'} = &getTTSFilename("To add Kamukunji, press 3");
#    $msgs{'place-1_3-remove'} = &getTTSFilename("To remove Kamukunji, press 3");
#    $msgs{'place-1_3-select'} = &getTTSFilename("For Kamukunji, press 3");

#    $msgs{'place-1_4-add'} = &getTTSFilename("To add Kasarani, press 4");
#    $msgs{'place-1_4-remove'} = &getTTSFilename("To remove Kasarani, press 4");
#    $msgs{'place-1_4-select'} = &getTTSFilename("For Kasarani, press 4");

#    $msgs{'place-1_5-add'} = &getTTSFilename("To add Langata, press 5");
#    $msgs{'place-1_5-remove'} = &getTTSFilename("To remove Langata, press 5");
#    $msgs{'place-1_5-select'} = &getTTSFilename("For Langata, press 5");

#    $msgs{'place-1_6-add'} = &getTTSFilename("To add Makadara, press 6");
#    $msgs{'place-1_6-remove'} = &getTTSFilename("To remove Makadara, press 6");
#    $msgs{'place-1_6-select'} = &getTTSFilename("For Makadara, press 6");

#    $msgs{'place-1_7-add'} = &getTTSFilename("To add Starehe, press 7");
#    $msgs{'place-1_7-remove'} = &getTTSFilename("To remove Starehe, press 7");
#    $msgs{'place-1_7-select'} = &getTTSFilename("For Starehe, press 7");

#    $msgs{'place-1_8-add'} = &getTTSFilename("To add Westlands, press 8");
#    $msgs{'place-1_8-remove'} = &getTTSFilename("To remove Westlands, press 8");
#    $msgs{'place-1_8-select'} = &getTTSFilename("For Westlands, press 8");


    ############################################################
    # Query Results

#    $msgs{'walk-query-results-long'} =
#	&getTTSFilename
#	('You will hear the titles of the postings that match your search.'.
#	 'For each result, you have a few options. '.
#	 'To hear a longer description and contact information for the posting.  Press 9.'.
#	 'To save the posting and hear it again later.  Press pound.'.
#	 'If you do not like it and do not want to hear it again during this call.  Press 7.'.
#	 'To repeat the posting.  Press 4.'.
#	 'To skip ahead to the next posting.  Press 3.'.
#	 'To jump backward to the previous posting.  Press 1.'.
#	 'If this posting is inappropriate and you want to let Mosoko know about it.  Press 6.'.
#	 'To hear these directions again at any time.  Press 0.'.
#	 'When you are all finished.  Press star.');

#    $msgs{'walk-query-results-brief'} =
#	&getTTSFilename
#	('For posting details. Press 9.'.
#	 'To save it for later.  Press pound.'.
#	 'If you are not interested in this posting.  Press 7.'.
#	 'To repeat the posting.  Press 4.'.
#	 'To skip ahead to the next posting.  Press 3.'.
#	 'To jump backward to the previous posting.  Press 1.'.
#	 'To flag the posting as inappropriate.  Press 6.'.
#	 'To hear the directions.  Press 0.'.
#	 'If you are finished.  Press star.');




    ############################################################
    # Extra



}

######################################################################

sub init_zone_sound_files {

    # not used.  Put landmark list into a single file.

    my $self = shift;

    my %zone2landmarkList = ();

    my $neighborhoods = 
	$self->{server}{dbi}->selectall_arrayref
	("SELECT neighborhood_id, city_id, zone, name, filename ".
	 "FROM neighborhoods", { Slice => {} } );
    foreach my $n (@$neighborhoods) {
	print STDERR "hood $n->{neighborhood_id} $n->{name}\n";
	# create entries of the form
	# &msg("zone-$state->{city_id}-$zone-landmarks")

	my $key = 'zone-'.$n->{city_id}.'-'.$n->{zone}.'-landmarks';

	# TODO change to filename when files exist
	my $snd_file = &getTTSFilename($n->{name});

	if (!defined($zone2landmarkList{$key})) {
	    my @landmarks = ();
	    $zone2landmarkList{$key} = \@landmarks;
	}
	my $marks = $zone2landmarkList{$key};
	$marks->[@$marks+1] = $snd_file;
	print STDERR "key $key name ".$n->{name}."\n";

    }

    foreach my $zone (keys %zone2landmarkList) {
	my $marks = $zone2landmarkList{$zone};
	$msgs{$zone} = @$marks;
	print STDERR "zone $zone\n";
    }

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

    #my $lang_words = '/home/mosoko/mosoko/trunk/sounds/swahili/'.$words;
    # $self->{user}->{language}.'/swahili/'.$words;

    if (defined($msgs{$lang_words})) {
	$self->log (4, "found msg in hash: $lang_words");
	return $msgs{$lang_words};
    }

    die if (!defined($self->get_property('sound_path')));

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
