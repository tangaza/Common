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

package Nokia::Common::Callback;

use strict;
use Data::Dumper;
use POSIX qw(strftime);
use base 'Asterisk::FastAGI';
use Nokia::Common::Tools;
use Nokia::Common::Sound;


######################################################################

my $DEBUG = 0;
my $RING_SECONDS = 2;

=head1 NAME

Nokia::Common::Callback - Entry point

=head1 DESCRIPTION

Entry point into the system that tries to figure out whether the user is
calling through or just wants to be called back.

=head1 METHODS

=cut

######################################################################
=head2 callback

Entry point into the system. Invoked by Asterisk from extensions.conf.
It sets up the calling user's initial state for each new call.

Listens to the state of a channel to determine whether the user was trying 
to call us or wants to be called back. It sets `CBSTATE` to the appropriate
state.

=cut

sub callback {
    my ($self) = @_;

    $self->log (4, "START COMMON ".&get_channel_desc($self)."\n\n");

    my $stamp = time;
    
    $self->{stamp} = time;
    $self->{callerid} = $self->input('callerid');
    if (defined($self->{callerid})) {
	$self->log(4, "CallerID: ".$self->{callerid});
    }

    $self->{origin} = $self->agi->get_variable('origin');
    if (defined($self->{origin})) {
	$self->log(4, "Origin: ".$self->{origin});
    }

    $self->{callout_ext} = $self->agi->get_variable("callout-ext-$self->{origin}");
    $self->{sms_number} = $self->agi->get_variable("sms-number-$self->{origin}");

    my $ext_origin = "ext-$self->{origin}";
    if (defined($ext_origin)) {
	$self->log(4, "Call Origin: $ext_origin");
    }


    eval {

	my $init_user_res = &init_user($self);
	if ($init_user_res < 0) {
	    $self->log (4, "init_user rejecting callerid $self->{callerid}");
	    return;
	}

	my $status = 0;

	for (my $i = 0; $i < 6 && defined($status); $i++) {
	    if ($DEBUG) { print STDERR "sleeping $i\n"; }
	    sleep ($RING_SECONDS);
	    $status = $self->agi->channel_status("");
	}

	$self->log (4, "done sleeping for callerid $self->{callerid}");

	if (!defined($status)) {
	    # User has hung up.
	    # Call him back or reject him.

	    if ($DEBUG) { print STDERR "user hungup\n"; }

	    # include new user bonus somehow?

	    $self->{seconds_remaining} = &get_seconds_remaining_count($self);
	    if ($self->{seconds_remaining} > 0) {
		$self->{cbstate} = 'calledback';
	    } else {
		$self->{cbstate} = 'rejected';
	    }
	    $self->agi->hangup();

	} elsif ($status == 4) {

	    if ($DEBUG) { print STDERR "user called us\n"; }

	    # User has rung through.
	    # Connect him to Interact.
	    $self->{cbstate} = 'calledus';

	} else {
	    die ("Unknown status $status\n");
	}
	
	$self->log (4, "id ".$self->{user}->{id}.
		    " status $self->{cbstate}");
	
    };

    if ($@) {
	print STDERR "$stamp error in callback: $@\n";
    }

    $self->agi->set_variable("CBSTATE","$self->{cbstate}"); 
    $self->agi->set_variable("OUTBOUNDID","$self->{user}->{phone}"); 

    $self->log (4, "END COMMON ".&get_channel_desc($self)."\n\n");

}

######################################################################

=head1 AUTHORS

Billy Odero, Jonathan Ledlie

Copyright (C) 2010 Nokia Corporation.

=cut


1;
