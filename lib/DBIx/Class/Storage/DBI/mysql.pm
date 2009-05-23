package DBIx::Class::Storage::DBI::mysql;

use strict;
use warnings;

use base qw/DBIx::Class::Storage::DBI/;

# __PACKAGE__->load_components(qw/PK::Auto/);

sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  $self->dbh->do('SET foreign_key_checks=0');
  $sub->();
  $self->dbh->do('SET foreign_key_checks=1');
}

sub _dbh_last_insert_id {
  my ($self, $dbh, $source, $col) = @_;
  $dbh->{mysql_insertid};
}

sub sqlt_type {
  return 'MySQL';
}

sub _svp_begin {
    my ($self, $name) = @_;

    $self->dbh->do("SAVEPOINT $name");
}

sub _svp_release {
    my ($self, $name) = @_;

    $self->dbh->do("RELEASE SAVEPOINT $name");
}

sub _svp_rollback {
    my ($self, $name) = @_;

    $self->dbh->do("ROLLBACK TO SAVEPOINT $name")
}
 
sub is_replicating {
    my $status = shift->dbh->selectrow_hashref('show slave status');
    return ($status->{Slave_IO_Running} eq 'Yes') && ($status->{Slave_SQL_Running} eq 'Yes');
}

sub lag_behind_master {
    return shift->dbh->selectrow_hashref('show slave status')->{Seconds_Behind_Master};
}

# MySql can not do subquery update/deletes, only way is slow per-row operations.
# This assumes you have proper privilege separation and use innodb.
sub subq_update_delete {
  return shift->_per_row_update_delete (@_);
}

1;

=head1 NAME

DBIx::Class::Storage::DBI::mysql - Automatic primary key class for MySQL

=head1 SYNOPSIS

  # In your table classes
  __PACKAGE__->load_components(qw/PK::Auto Core/);
  __PACKAGE__->set_primary_key('id');

=head1 DESCRIPTION

This class implements autoincrements for MySQL.

=head1 AUTHORS

Matt S. Trout <mst@shadowcatsystems.co.uk>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
