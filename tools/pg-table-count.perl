#!/usr/bin/perl -w

# --------------------------------------------------------
#
# pg_table_count.perl
#
# ]project-open[
# (c) 2008 - 2010 ]project-open[
# frank.bergmann@project-open.com
#
# --------------------------------------------------------


use Data::Dumper;

# --------------------------------------------------------
$file = $ARGV[0];
$debug = 0;                          # Debug? 0=no output, 10=very verbose

# --------------------------------------------------------
#
%table_hash = ();
my $table = "";
my $cnt = 0;
open(FILE, $file);
while (my $line=<FILE>) {
    chomp($line);
    if ($line =~ /^COPY ([a-zA-Z0-9_]+).*?FROM stdin;/) { 
	print "pg-table-count: new table=$1\n" if ($debug > 0);
	$table = $1;
    }
    if (exists $table_hash{$table}) {
	$table_hash{$table}++;
    } else {
	$table_hash{$table} = 1;
    }
}

print "\nResults:\n";
foreach my $t (sort(keys(%table_hash))) {
    print "$t\t$table_hash{$t}\n";
}

print "\n\n";
exit 0;
