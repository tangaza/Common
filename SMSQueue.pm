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

package Nokia::Common::SMSQueue;

# Library for simple daemon that buffers outgoing SMS messages.
# Started with daemon/sms-send-daemon.pl.

use base qw(Net::Server);


use strict;
use POSIX qw(strftime);
use Data::Dumper;
use Nokia::Common::Tools;

######################################################################
# server side of sms queue.
# waits for SMS messages and sends them out FIFO

sub process_request {
    my $self = shift;

    my $line = <STDIN>;
    my (@items) = split (/\s/,$line);
    if ($#items < 2) {
	$self->log (4, "not enough args ".$#items);	    
	return;
    }
    my $phone = $items[0];
    shift (@items);
    my $msg = join (' ',@items);
    # Add some sleeping / buffering?

    if (!defined ($phone)) {
	$self->log (4, "phone not defined");
	return;
    }
    if (!defined ($msg)) {
	$self->log (4, "msg not defined");
	return;
    }

    $self->log (3, "queue phone $phone msg $msg");
    &send_sms ($self, $phone, $msg);
}

#######################################################################
# Example:
# &send_sms ($self, $self->{user}->{phone}, "Here is the message");

sub send_sms {
    my ($self, $phone, $message) = @_;

    $self->log (4, "trying sms to $phone msg $message");

    my $browser = LWP::UserAgent->new;

    my $kannel_url = $self->get_property('kannel_url');
    my $kannel_user = $self->get_property('kannel_user');
    my $kannel_pw = $self->get_property('kannel_pw');

    my $origin = $self->get_property('origin');
    my $url = URI->new($self->get_property("sms_url_$origin"));
    
    if ($origin eq 'ke') {
	$url->query_form
	    ('username' => $self->get_property("sms_username_$origin"),
	     'password' => $self->get_property("sms_password_$origin"),
	     'source' => $self->get_property("sms_number_$origin"),
	     'destination' => $phone,
	     'message' => $message
	     );
    }
    else {
	$url->query_form 
	    ('to' => $phone,
	     'text' => $message,
	     'username' => $self->get_property("sms_username_$origin"),
	     'password' => $self->get_property("sms_password_$origin")
	     );
    }
    
    $self->log (4, "created query form $url");

    my $response = $browser->get($url);
    
    $self->log (4, "sent sms to $phone msg $message");

    # check return code??
    if (! ($response->is_success)) {
	$self->log (1, "sending sms to $phone failed: ".$response->status_line);
	return -1;
    }

    $self->log (4, "all done");

    return 0;
}


######################################################################
sub write_to_log_hook {
    my $self = shift;
    my $level  = shift;
    my $msg  = shift || '';
    my $date = strftime("[%d-%b-%Y %H:%M:%S]:", localtime);
    my $func_name = (caller(2))[3];
    $self->Net::Server::write_to_log_hook($level, "$date $func_name $msg");
}

1;
