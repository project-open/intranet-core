#!/usr/bin/perl

$server_path = "/web/openacs5";
$debug = 1;

$search = $ARGV[0];
$replace = $ARGV[1];


open FILES "find $server_path -type f -exec grep -il '$search' {} \;
while ($file = <FILES>) {
	chomp($file);

	print "Opening $file\n" if ($debug);
	open F "$file"




}

