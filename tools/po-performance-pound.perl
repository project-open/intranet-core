#!/usr/bin/perl

# --------------------------------------------------------------
# po-performance-pound
#
# Analyzes the number of hits per second in the system
# 2007-09-05 Frank Bergmann
# --------------------------------------------------------------

# Constants, variables and parameters
#
$debug = 1;
$file = $ARGV[0];

%hits_per_min = ();
%urls_per_min = ();
%hits_per_hour = ();

print "po-performance-pound: Analyzing file: $file\n" if $debug > 0;

# Get the list of all databases. psql -l returns lines such as:
#  adquem       | adquem       | UNICODE
#
open(FILE, $file);
while (my $line=<FILE>) {
    chomp($line);
    
    # Skip lines from processes other then pound
    next if (!($line =~ /pound\:/));
    # Skip header images
    next if ($line =~ /GET \/intranet\/images/);
    # Skip internet worms etc.
    next if ($line =~ /pound\: bad header/);
    # Skip requests to / or other non-existing URLs
    next if ($line =~ /pound\: no backend/);
    # Skip start/stop
    next if ($line =~ /pound\: received signal/);
    next if ($line =~ /pound\: starting/);

    print "po-performance-pound: Line=$line\n" if $debug > 1;

    # Analyze lines - they look like this:
    # Sep  5 08:06:59 openmat pound: openmat 192.168.1.142 - - [05/Sep/2007:08:06:59 +0200] "GET /intranet/js/showhide.js HTTP/1.1" 304 - "http://openmat/register/" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NETCLR 1.1.4322; InfoPath.1)"

    if ($line =~ /^(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*pound\:\s*(\S*)\s*([0-9\.]*)\s*(\S*)\s*(\S*)\s*\[([^\]]*)\]\s*\"([^\"]*)\"\s*(\S*)\s*(\S*)/) {
	$month = $1;
	$day = $2;
	$time = $3;
	$host = $4;
	$host2 = $5;
	$ip = $6;
	$ttt1 = $7;
	$ttt2 = $8;
	$date = $9;
	$url_proto = $10;
	$ret_code = $11;
	$ttt3 = $12;

	$time =~ /(..)\:(..)\:(..)/;
	$hour = "$1";
	$minute = "$1:$2";
	
	$url_proto =~ /(\S*)\s*(\S*)\s*(\S*)/;
	$method = $1;
	$url = $2;
	$proto = $3;

	$url =~ /([^\?]*)/;
	$url_body = $1;

	# Exclude style sheets and images
	next if ($url_body =~ /\.css$/);
	next if ($url_body =~ /\.gif$/);
	next if ($url_body =~ /\.jpg$/);
	next if ($url_body =~ /\.js$/);

#	print "po-performance-pound: time=$time, minute=$minute, url=$url\n" if $debug > 0;
    } else {
	print "po-performance-pound: Bad line=$line\n" if $debug > 0;
	next;
    }

    # Per Minute
    $s = $hits_per_min{$minute};
    $s = $s+1;
    $hits_per_min{$minute} = $s;

    $s = $urls_per_min{$minute};
    $urls_per_min{$minute} = "$s\t$ret_code\t$url_body\n";

    # Per Hour
    $s = $hits_per_hour{$hour};
    if (length $s == 0) { $s = 0; }
    $s = $s+1;
    $hits_per_hour{$hour} = $s;

}
close(FILE);

foreach my $key (sort(keys(%hits_per_hour))) {
    next if ($hits_per_hour{$key} <= 10);
    print "po-performance-pound: hits_per_hour($key) = $hits_per_hour{$key}\n";
}

print "\n\n";

foreach my $key (sort(keys(%hits_per_min))) {
    next if ($hits_per_min{$key} <= 3);
    print "po-performance-pound: hits_per_min($key) = $hits_per_min{$key}\n";
    print "po-performance-pound: urls_per_min($key)\n$urls_per_min{$key}\n";
}
