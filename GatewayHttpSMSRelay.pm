#
#    Common: Shared library for voice-based applications.
#
#    Copyright (C) 2010-2012 Nokia Corporation.
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

package Nokia::Common::GatewayHttpSMSRelay;

#use Exporter;
#@ISA = ('Exporter');
#@EXPORT = ('sms_relay');
use strict;
use HTTP::Request::Common;
use LWP::Simple;

=head1 NAME

Nokia::Common::GatewayHttpSMSRelay - SMS relay from Asterisk to Django and back

=head1 DESCRIPTION

Library for simple daemon that takes SMS messages from Asterisk
and relays them to a local http process (e.g. one running django)

=head2 METHODS

=cut

######################################################################

=head2 sms_relay

Waits for SMS messages, relays them to http process, waits for result,
and sends it back to Asterisk.

=cut

sub sms_relay {
    my $self = shift;

    # Grab the url encoded SIP message,
    # which is of the form [senders number]\n[message contents]
    my $smsEncodedIn = $self->agi->get_variable("SMSIN");

    # Decode it
    my $smsIn = uri_unescape($smsEncodedIn);

    # Divide it into the sender's number and the message contents
    my ($sender, $msg) = split (/\n/, $smsIn);

    $self->log (3, "received msg sender $sender msg $msg");

    my $response = &post_msg($self, $sender, $msg);

    if ($response eq '') {
	# error condition
	$self->agi->set_variable("SMSOUT", "");
    } else {
	my $smsOut = "$sender\n$response";

	# Make it possible to send back to Asterisk
	my $smsEncodedOut = uri_escape($smsOut);

	# Assign it to a variable so it is available when we return from
	# the AGI.
	$self->agi->set_variable("SMSOUT", $smsEncodedOut);
    }
}

######################################################################

sub post_msg {
    my ($self, $sender, $msg) = @_;

    # same as url in /etc/tangaza/kannel/tangaza.conf
    my $url = "http://localhost/tangaza/";
    my $ua = LWP::UserAgent->new;

    my $response = $ua->post($url, "X_KANNEL_FROM" => $sender,
			     "Content" => $msg);
    if ($response->is_success) {
	my $content = $response->content;
	$self->log (4, "content $content");
	#print "content $content";
	return $content;
    } else {
	$self->log (3, "post_msg error ".$response->status_line);
	#print "post_msg error ".$response->status_line;
	return '';
    }

}

=head1 AUTHORS

Billy Odero, Jonathan Ledlie

Copyright (C) 2010-2012 Nokia Corporation.

=cut

1;
