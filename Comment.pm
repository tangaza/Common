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

package Nokia::Common::Comment;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ('leave_comment_menu');

use strict;
use DBI;
use File::Copy;
use Nokia::Common::Stamp;
use Nokia::Common::Sound;
use Nokia::Common::Tools;

######################################################################

sub leave_comment_menu {
    my ($self) = @_;

    # leave a comment about the system at the beep
    # press pound when you are finished with your message

    #if (&too_many_comments($self)) {
    #&stream_file ($self,'too-many-comments',"*#","0");
    #return;
    #}

    my $comment = &record_file
	($self, &msg($self,'leave-comment'), 90);
    if ($comment eq 'timeout' || $comment eq 'cancel' ||
	$comment eq 'hangup') {
	return;
    };
   
    $comment = &mv_tmp_to_comment_dir ($self, $comment);

    $self->log (4, "creating db record for new comment from ".
		"user_id $self->{user}->{id}");
    $self->{server}{comment_insert_sth} = $self->{server}{dbi}->prepare_cached
	("INSERT INTO comments (comment_id, user_id, timestamp, rank, filename) VALUES (NULL, ?, NULL, -1, ?)");
    $self->{server}{comment_insert_sth}->execute ($self->{user}->{id}, $comment);
    $self->{server}{comment_insert_sth}->finish();
    $self->log (4, "created db record for new comment from user_id ".
		$self->{user}->{id});

    &stream_file ($self,['comment-recorded', 'thank-you'],"*#","0");

}


sub too_many_comments {
    my ($self) = @_;
    my $MAX_COMMENTS_PER_DAY = 5;

    $self->{server}{comment_count_sth} =
	$self->{server}{dbi}->prepare_cached
	("select count(*) as comment_count from comments where user_id = ? AND timestamp > DATE_SUB(NOW(),INTERVAL 24 HOUR)");
    $self->{server}{comment_count_sth}->execute ($self->{user}->{id});
    my ($count) = $self->{server}{comment_count_sth}->fetchrow_array();
    $self->{server}{comment_count_sth}->finish();

    if ($count > $MAX_COMMENTS_PER_DAY) {
	return 1;
    }

    return 0;
}

1;
