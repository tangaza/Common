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
package Nokia::Common::Auth;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ('auth_pin','set_pin');

use strict;
use DBI;
use Nokia::Common::Tools;
use Nokia::Common::Sound;

# Both functions assume four digit pins

######################################################################

sub auth_pin {
    my ($self) = @_;

    # Give user three chances to match four digit pin
    # if the user has a pin.
    # If no pin, do nothing.

    # Pins (and auth in general) are pretty important here,
    # because callerid is simple to falsify.

    # However, we do not want to create a significant barrier to entry.

    # Assumes no pin means user_pin = 0
    my $MAX_CHANCES = 3;

    if (defined($self->{user}->{pin})) {

	$self->log (4, "auth_pin user_id ".$self->{user}->{id}.
	    " pin ".$self->{user}->{pin});
	
	# We already have the pin.  No DB access necessary.
	# return -1 if user fails to auth.

	for ( my $tries = 0; $tries < $MAX_CHANCES; $tries++ ) {
	    my @number_list = ();
	    # we do not want to say the users pin back to him
	    
	    my @prompt = ();
	    if ($tries == 0) {
		push (@prompt, &msg($self, $self->{welcome_msg}));
		$self->{played_intro} = 1;
		push (@prompt, &msg($self,"your-account-has-a-pin"));
	    }
	    
	    # user has a pin, need to check it
	    push (@prompt, &msg($self,'please-enter-your-pin'));
	    
	    my $entered_pin = &get_unchecked_large_number
		($self, \@prompt, \@number_list);
	    
	    $self->log (4, "user entered pin $entered_pin real pin is ".
			 $self->{user}->{pin});
	    
	    if ($entered_pin eq 'timeout' || 
		$entered_pin eq 'hangup' ||
		$entered_pin eq 'cancel') {
		# bad input or user hung up
		return $entered_pin;
	    }

	    # XXX sometimes this is blank in the db and sometimes it is NULL
	    # it should just be NULL
	    if (($entered_pin =~ /^\d{4}$/) && ($entered_pin eq $self->{user}->{pin})) {
		$self->log (4, 'pin walk thru');
		return 'ok';
	    }
	    &stream_file ($self, 'sorry-that-pin-was-not-correct',"*#","0"),

	}

	# May need to give user a person to talk to to reset pin.
	&stream_file ($self, 'sorry-we-could-not-authenticate-your-pin', "#", "0"),
	#&request_attendant ($self);
	return 'cancel';

    } else {
	$self->log (4, "auth_pin user_id ".$self->{user}->{id}.
	    " no pin");
    }

    return 'ok';

}

######################################################################

sub set_pin {
    my ($self) = @_;

    # Get user entry of four digit pin and set it in DB

    my $MAX_CHANCES = 3;
    my $entered_pin = -1;

    &stream_file ($self, 'pin-creation-menu', "#", "0");

    for ( my $tries = 0; $tries < $MAX_CHANCES && $entered_pin == -1; $tries++ ) {

	$self->log (4, "top of loop, entered_pin=$entered_pin, tries=$tries");

	my @number_list = ();
	$entered_pin = &get_unchecked_large_number
	    ($self, &msg($self,'please-enter-a-four-digit-pin-or-to-cancel-press-star'), \@number_list);
	$self->log (4, "entered_pin $entered_pin, length ".$#number_list);

	if ($entered_pin eq 'timeout' || $entered_pin eq 'cancel' || $entered_pin eq 'hangup') {
	    return $entered_pin;
	}

	# ah perl counting
	if ($#number_list != 3) {
	    &stream_file ($self,'sorry-that-was-not-the-right-number-of-digits',"#","0"),
		$entered_pin = -1;
	} else {
	    
	    my $confirm_pin = &get_unchecked_large_number
		($self, &msg($self,'please-reenter-your-new-pin-for-confirmation'), \@number_list);
	    
	    $self->log (4, "confirm_pin $confirm_pin");
	    
	    if ($confirm_pin eq 'timeout' || $confirm_pin eq 'cancel' || $confirm_pin eq 'hangup') {
		return $confirm_pin;
	    }
	    
	    if ($entered_pin != $confirm_pin) {
		$entered_pin = -1;
		$self->log (4, "pins did not match");
		&stream_file ($self,'sorry-the-pins-you-entered-did-not-match-please-try-again',"#","0");
	    } else {
		$self->log (4, "pins matched, entered_pin=$entered_pin");
	    }
	}

	$self->log (4, "bottom of loop, entered_pin=$entered_pin, tries=$tries");

    }

    $self->log (4, "update pin? entered_pin=$entered_pin");

    if ($entered_pin != -1) {

	$self->log (4, "UPDATE users SET user_pin=$entered_pin WHERE where user_id=".
		     $self->{user}->{id});
	
	$self->{server}{set_pin_sth} = 
	    $self->{server}{dbi}->prepare_cached
	    ("UPDATE users SET user_pin=? WHERE user_id=?");
	
	$self->{server}{set_pin_sth}->execute($entered_pin, $self->{user}->{id});
	$self->{server}{set_pin_sth}->finish();

	&stream_file ($self,'your-pin-is-now-set', "#", "0");
	
	$self->{user}->{pin} = $entered_pin;
	
	$self->log (4, "set pin for user_id $self->{user_id} ".
		  "pin $entered_pin");
    } else {
	$self->log (4, "did not set pin for user_id $self->{user_id}, entered_pin=$entered_pin ");
    }

    return 'ok';

}

######################################################################

1;
