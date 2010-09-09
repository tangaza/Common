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
package Nokia::Common::Phone;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ('is_valid_outbound_number','parse_callerid');

use strict;

######################################################################
sub is_valid_outbound_number {
    my ($self, $number) = @_;

    if (length($$number) < 7 || length($$number) > 20) {
	return 0;
    }

    # We do not want to call any number arbitrarily
    # i.e. 800 numbers, "900" numbers

    # Kenyan numbers
    #if ($$number =~ /^0[\d]{2}|7[1-3][\d][\d]{6,7}$/) {
    if ($$number =~ /^0(\d{2}|7\d{2})\d{6,7}$/) {
	return 1;
    }

    # US numbers for testing
    # Prepend 1 if missing
    if ($$number =~ /^1?\d\d\d\d\d\d\d\d\d\d$/) {

	if ($$number !~ /^1/) {
	    $$number = '1'.$$number;
	}

	return 1;
    }

    $self->log ("accepting for DEMO");

    #return 0;
    return 1;
}

######################################################################
sub parse_callerid {
    my ($self) = @_;

    my $callerid = $self->{callerid};

    $self->{user}->{incoming_phone} = $callerid;
    $self->{user}->{outgoing_phone} = $callerid;

    $self->log (4, "parsing callerid $callerid");

    # US number
    if ($callerid =~ /^1(\d\d\d)(\d\d\d\d\d\d\d)$/ || 
	$callerid =~ /^1-(\d\d\d)-(\d\d\d\d\d\d\d)$/ || 
	$callerid =~ /^(\d\d\d)(\d\d\d\d\d\d\d)$/ || 
	$callerid =~ /^(\d\d\d)-(\d\d\d-\d\d\d\d)$/) {

	$self->{user}->{place_id} = 1;
	$self->{user}->{phone} = $self->{callerid};
	$self->{user}->{phone} =~ s/-//;

	$self->log (4, "matched US number $callerid");
	return 1;
    }

    # Finland number
    if ($callerid =~ /^358(\d+)$/) {

	$self->{user}->{place_id} = 1;
	$self->{user}->{phone} = $self->{callerid};
	$self->{user}->{phone} =~ s/-//;

	$self->log (4, "matched Finland number $callerid");
	return 1;
    }

    #Kenya number
    #Allow formats 254(0**|71*|72*|73*|)(******(*))
    #the '*' represents any numeric digit 0-9
    #
    #if its a safaricom number prepend 254 for callerid (db record) 
    #and 0 for outgoing_phone
    
    if ($callerid =~ m/^7\d{8}$/) {
	#$self->{user}->{outgoing_phone} = "0".$callerid;
	$callerid = "254".$callerid;
    }
    
    #if ($callerid =~ m/^254(0[\d]{2}|7[1-3][\d][\d]{6,7})$/ ||
    if ($callerid =~ m/^2547\d{8}$/) {
	# Caller IDs are numbers only. i.e. no dashes, parentheses etc...at least at this end
	#$self->{user}->{phone} = $callerid;
	
	# Todo set the location based on the phone number?
	# What about other major cities in EA?
	$self->{user}->{place_id} = 1;
	
	$self->{user}->{outgoing_phone} = "0".substr($callerid, 3);
	$self->{user}->{callerid} = $callerid;
	$self->{user}->{phone} = $callerid;
	$self->{callerid} = $callerid;
	
	$self->log (4, "matched Kenya number ".$self->{user}->{phone});
	
	return 1;
    }

    $self->log (1, "Parse callerid failed $callerid");

    #return -1;
    $self->log (1, "Parse callerid accepting for DEMO");

    return 1;
}

1;
