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

package Nokia::Common::Stamp;

=head1 NAME

Nokia::Common::Stamp

=head1 DESCRIPTION

This module manages all time/date conversions

=head1 METHODS

=cut

use Exporter;
@ISA = ('Exporter');
@EXPORT = ('year_month_day','year_month_day_dir','year_month',
	   'year_month_day_plus_n_days_dir');

my $one_hour_delay = 1;

my $SEC_PER_DAY = 60*60*24;
my $SEC_PER_WEEK = 604800;

######################################################################

=head2 year_month_day

Returns the current time into a date-time value of the form yyyymmdd

=cut
sub year_month_day {

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
    localtime(time);
  $year += 1900;
  $mon++;

  my $stamp = sprintf ("$year%02d%02d", $mon, $mday);
  return $stamp;
}

######################################################################

=head2 year_month_day_plus_n_days_dir

Returns a directory path of the form yyyy/mm/dd/ formed from the current 
date-time

=over 4

=item Args:

$days: delay adjustment to the current time

=back

=cut
sub year_month_day_plus_n_days_dir {
    my ($days) = @_;

    my $delay = $days * $SEC_PER_DAY;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime(time+($delay));
    $year += 1900;
    $mon++;

    my $stamp = sprintf ("$year/%02d/%02d/", $mon, $mday);
    return $stamp;
}

######################################################################

=head2 year_month_day_dir

Returns a directory path of the form yyyy/mm/dd/ formed from the current 
date-time

=cut
sub year_month_day_dir {
    my ($days) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime(time);
    $year += 1900;
    $mon++;

    my $stamp = sprintf ("$year/%02d/%02d/", $mon, $mday);
    return $stamp;
}

######################################################################

=head2 year_month

Returns the current date-time in the form C<yyyy-mm>

=cut
sub year_month {

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
    localtime(time);
  $year += 1900;
  $mon++;

  my $stamp = sprintf ("$year-%02d", $mon);
  return $stamp;
}

######################################################################
sub epoch2stamp {
    my ($epoch) = @_;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
    localtime($epoch);
  $year += 1900;
  $mon++;

  my $stamp = sprintf ("$year-%02d-%02d %02d:%02d", $mon,
		       $mday,$hour,$min);
  return $stamp;
}

######################################################################
sub epoch2year_mo_day {
    my ($epoch) = @_;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
    localtime($epoch);
  $year += 1900;
  $mon++;

  my $stamp = sprintf ("$year-%02d-%02d", $mon, $mday);
  return $stamp;
}

######################################################################
sub file2epochdelta {
    my ($file) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	$atime,$mtime,$ctime,$blksize,$blocks)
	= stat($file) or die ("Could not stat file $file");

    if ($file =~ /(\d\d\d\d\d\d\d\d\d\d)/) {
	my $epoch = $1;
	if ($one_hour_delay) {
	    $epoch = $epoch + 3600;
	}
	my $epochdelta = $mtime - $epoch;
	#print "ctime: ".&epoch2stamp($ctime)."\n";
	#print "atime: ".&epoch2stamp($atime)."\n";
	#print "mtime: ".&epoch2stamp($mtime)."\n";
	#print "name:  ".&epoch2stamp($epoch)."\n";
	#print "ep $epochdelta\n";
	return $epochdelta

    } else {
	die ("File name does not contain epoch time: $filename");
    }
}

=head1 AUTHORS

Billy Odero, Jonathan Ledlie

Copyright (C) 2010 Nokia Corporation. 

=cut

1;
