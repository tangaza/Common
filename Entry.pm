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
# 

package Nokia::Common::Entry;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ('configure_hook', 'pre_server_close_hook', 'write_to_log_hook', 'post_configure_hook');

use strict;
use Data::Dumper;
use POSIX qw(strftime);
use base 'Asterisk::FastAGI';
use DBI;
use Math::Random;
use Nokia::Common::Tools;
use Nokia::Common::Stamp;
use Nokia::Common::Sound;
use Nokia::Common::Phone;
use Nokia::Common::Auth;

######################################################################

sub entry {
    my ($self) = @_;
    
    my @items_to_back = qw(fn_start_call fn_end_call fn_main_menu server welcome_msg);
    my $self_backup = {};


    foreach my $item (@items_to_back) {
	$self_backup->{$item} = $self->{$item};
    }

    foreach my $key (keys %$self) {
	delete $self->{$key};
    }
    
    foreach my $item (@items_to_back) {
	$self->{$item} = $self_backup->{$item};
    }    
    
    $self->log (3, "starting ".&get_channel_desc($self));

    &db_connect ($self);

    $self->{stamp} = time;
    $self->{callerid} = $self->input('callerid');

    my $seed = $self->input('channel').' '.$self->{stamp}.' '.$self->{callerid};
    $self->log (4, "seed $seed");
    Math::Random::random_set_seed_from_phrase ($seed);

    if (! &user_has_hungup($self)) {

	$self->log (1, "NO EVAL TRAP");
	#eval {
	    # No DB operations outside of here.

	    if (&init_user($self) < 0) {
		$self->log (2, $self->{stamp}." bad callerid ".$self->{callerid});
		#$self->agi->stream_file
		 #   ([&msg($self, 'sorry'),
		  #    &msg($self, 'your caller id is invalid'),
		   #   &msg($self, 'goodbye')],"*","0");
		$self->log (2, "sorry");
		&stream_file ($self, 'sorry',"*","0");
		$self->log (2, "done sorry");

		return;
	    }

	    if (&start_call($self) eq 'ok') {

		$self->{fn_main_menu}->($self);

		if (! &user_has_hungup($self)) {
		    $self->log (3, "ending session for user_id ".$self->{user}->{id}.
			      " callerid ".$self->{callerid});
		    &stream_file ($self, 'goodbye', "*","0");
		    $self->agi->hangup ();
		}
		&end_call($self);
	    }

	    if ($@) {
		$self->log (1, "Error caught by main: $@");

		# Error occurred.
		#

		&stream_file ($self, ['an-error-has-occured', 'goodbye'],"*","0");
	    }

        #};

    }

    my $endTime = time;
    my $diffTime = $endTime - $self->{stamp};
    
    $self->log (3, "ending Common::Entry callerid $self->{callerid}, ran for $diffTime sec");
}

######################################################################

sub start_call {
    my ($self) = @_;

    $self->log (3, "starting welcome_msg");
    
    my $auth_res = &auth_pin ($self);
    
    if ($auth_res ne 'ok') {
		return $auth_res;
    }

    $self->{cbstate} = $self->agi->get_variable("CBSTATE");
    $self->log (3, "cbstate ".$self->{cbstate});

    if ($self->{cbstate} eq 'calledback') {


	$self->{user}->{seconds_remaining} = &get_seconds_remaining_count
	    ($self);

	$self->log (3, "calledback id ".$self->{user}->{id}.
	    " seconds remaining ".$self->{user}->{seconds_remaining});

	if ($self->{newuser} == 1) {
	    my $NEWUSER_BONUS_SECONDS = 120;
	    $self->{user}->{seconds_remaining} += $NEWUSER_BONUS_SECONDS;
	}

	$self->log (2, "SKIPPING ALARMS");
	#&set_alarms ($self);

    }
    # else user calledus

    $self->log (2, "SKIPPING INVITATION CHECK");
    #&check_for_invitation ($self);

    if ($self->{newuser} == 1) {
	$self->log (3, "newuser id ".$self->{user}->{id});
	# TODO do extra stuff here if new user
	# before main menu
	# Such as selecting a language

    }

    $self->log (3, "ending welcome_msg");

    $self->{fn_start_call}->($self);

    return 'ok';
}

######################################################################

sub set_alarms {
    my ($self) = @_;

    $self->log (3, "start set_alarms");

    # mention of alarms here
    # http://www.voip-info.org/wiki-Asterisk+cmd+monitor


}

######################################################################

sub end_call {
    my ($self) = @_;

    my $endTime = time;
    my $seconds = $endTime - $self->{stamp};

    $self->{server}{call_insert_sth} =
	$self->{server}{dbi}->prepare_cached
	("INSERT INTO calls (call_id, user_id, timestamp, seconds, cbstate) ".
	 "VALUES (NULL, ?, NULL, ?, ?)");
    $self->{server}{call_insert_sth}->execute
	($self->{user}->{id}, $seconds, $self->{cbstate});

    $self->{fn_end_call}->($self);

    $self->log (4, "end_call user ".$self->{user}->{id}." sec ".$seconds);

}

######################################################################

sub check_for_invitation {
    my ($self) = @_;

    $self->log (3, "check_for_invitation start");

    $self->{server}{check_for_invitation_sth} =
	$self->{server}{dbi}->prepare_cached
	("SELECT user_id FROM invitations WHERE status='new' ".
	 "AND phone_number=?");
	$self->{server}{check_for_invitation_sth}->execute
	($self->{user}->{phone});

    $self->log (3, "A");

    if ($self->{server}{check_for_invitation_sth}->rows > 0) {

	$self->log (3, "A-1");

	my $friend_user_id =
	    $self->{server}{check_for_invitation_sth}->fetchrow_arrayref()->[0];
	$self->log (3, "check_for_invitation: user_id $friend_user_id ".
		   "invited phone ".$self->{user}->{phone});
	$self->{newuser} = 1;

	my $friends_name_file = &get_users_name ($self,$friend_user_id);
	&stream_file ($self, ['welcome-to-socnet', 'You were invited', $friends_name_file], "*#", "0");
	$self->{played_intro} = 1;

	$self->{server}{told_user_invitation_sth} =
	    $self->{server}{dbi}->prepare_cached
	("UPDATE invitations SET status='connected' WHERE phone_number=?");
	$self->{server}{told_user_invitation_sth}->execute
	    ($self->{user}->{phone});
	$self->{server}{told_user_invitation_sth}->finish();

    }

    $self->log (3, "Done");

    $self->{server}{check_for_invitation_sth}->finish();

}


######################################################################

sub configure_hook {
    my $self = shift;

    $self->log ("conf hook");

    #print STDERR "conf hook";

    &db_connect ($self);
    &init_sound ($self);
    #&init_places ($self);
    &init_tools ($self);

}

######################################################################

sub pre_server_close_hook {
    my $self = shift;
    print STDERR "Running pre_server_close_hook\n";
    &db_disconnect ($self);
}

######################################################################

sub post_configure_hook {
    my $self = shift;

    #$self->log (2, "db ".$self->get_property('DB_DSN'));
    #$self->log (2, "db ".$self->get_property(DB_DSN));

    #print STDERR Dumper ($self);

    #exit (0);

}


######################################################################

sub pre_configure_hook {
    my $self = shift;

    #$self->log (2, "db ".$self->get_property('DB_DSN'));
    #$self->log (2, "db ".$self->get_property(DB_DSN));

    #print STDERR Dumper ($self);
}

######################################################################
sub write_to_log_hook {
    my $self = shift;
    my $level  = shift;
    my $msg  = shift || '';
    my $date = strftime("[%d-%b-%Y %H:%M:%S]:", localtime);
    my $func_name = (caller(2))[3];

    # TODO Add uid

    #$self->SUPER::log($level, "$date $func_name $msg");
    #$self->log($level, "$date $func_name $msg");
    $self->Net::Server::write_to_log_hook($level, "$date $func_name $msg");

    return;
}


1;
