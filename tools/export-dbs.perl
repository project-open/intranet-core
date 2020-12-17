#!/usr/bin/perl

# --------------------------------------------------------------
# export-dbs
# (c) 2009 ]project-open[

# Licensed under GPL V2.0 or higher
# Determines the list of databases available and backs up all DBs
# Author: Frank Bergmann <frank.bergmann@project-open.com>
# --------------------------------------------------------------

# Constants, variables and parameters
#
my $debug =	1;
my $psql =	"/usr/bin/psql";
my $pg_dump =	"/usr/bin/pg_dump";
my $bzip2 =	"/usr/bin/bzip2";

my $exportdir =	"/var/backup";
my $logdir =	"/var/log/backup";

my $backup_email = "backup\@fraber.de";
my $pg_owner = "postgres";
my $computer_name = `hostname`;

my $time = `/bin/date +\%Y\%m\%d.\%H\%M`;
my $weekday = `/bin/date +%w`;

chomp($computer_name);
chomp($time);
chomp($weekday);

# Get the list of all databases. psql -l returns lines such as:
#  projop       | projop       | UNICODE
#
open(DBS, "su - $pg_owner -c '$psql -l' |");
while (my $db_line=<DBS>) {

	chomp($db_line);
	$db_line =~ /^\s*(\w*)/;
        my $db_name = $1;

	next if (length($db_name) < 2);
	next if ($db_name =~ /^\s$/);
	next if ($db_name =~ /^List$/);
	next if ($db_name =~ /^Name$/);

	next if ($db_name =~ /^postgres$/);
	next if ($db_name =~ /^template0$/);
	next if ($db_name =~ /^template1$/);

        next if ($db_name =~ /^ponet$/);

	print "export-dbs: '\n" if $debug;
	print "export-dbs: '\n" if $debug;
	print "export-dbs: Exporting '$db_name'\n" if $debug;
	print "export-dbs: '\n" if $debug;
	print "export-dbs: \n" if $debug;

	my $file = "$exportdir/pgback.$computer_name.$db_name.$time.sql";
	my $log_file = "$logdir/export-dbs.$db_name.$time.log";

        # Write out backup
	my $cmd = "su - $pg_owner --command='$pg_dump $db_name -c -O -F p -f $file'";
	print "export-dbs: $cmd\n" if ($debug);
	system $cmd;

	my $cmd2 = "su - $pg_owner --command='$bzip2 $file'";
	print "export-dbs: $cmd2\n" if ($debug);
	system $cmd2;

        if ($db_name =~ /fier/) {
            my $cmd6 = "uuencode $file.bz2 $file.bz2 | mail -s pgback.$computer_name.$db_name.$time system\@fier.net";
            print "mailing: $cmd6\n" if ($debug);
            system $cmd6;
        }

	# Skip backup of some customers
	next if ($db_name =~ /^qabiria$/);
	next if ($db_name =~ /^localingua2$/);

	# Tar the entire web server to backup area, except for packages and filestorage backup.
	my $file9 = "$exportdir/webback.$computer_name.$db_name.$time.tgz";
	# my $cmd9 = "tar --exclude='/web/$db_name/log' --exclude='/web/$db_name/packages' --exclude='/web/$db_name/filestorage/backup' -c -z -f $file9 /web/$db_name/";
	my $cmd9 = "tar --exclude='/web/$db_name/log' --exclude='/web/$db_name/filestorage/backup' --exclude='/web/$db_name/builds' -c -z -f $file9 /web/$db_name/";
	print "export-dbs: $cmd9\n" if ($debug);
	system $cmd9;

}
close(DBS);

