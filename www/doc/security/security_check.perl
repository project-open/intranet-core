#!/usr/bin/perl

# --------------------------------------------------------------
# security_check.perl
#
# Automatic Security Check for TCL files
# 2004-08-06 Frank Bergmann
# Based on material from P/O
# --------------------------------------------------------------

use strict;

# Constants, variables and parameters
#
my $debug = 0;
my $folder_root = "N:/aimdev/packages/";


# Write a .CSV Header line so that the output can 
# be opened by Excel directly.
print "filename,status,require_login,ad_maybe_redirect_for_registration,ad_verify_and_get_user_id,unsave_dollar,comment\n";

# Main loop: use "find" to get the list of all TCL
# files in $folder_root.
#
my $last_package_key = "";
open(FILES, "find $folder_root -type f |");
while (my $file=<FILES>) {
	# Remove trailing "\n"
	chomp($file);

	# Print a header line for every package
	&print_header($file);
	
	# Extract the file extension
	$file =~ /\.([^\.]*)$/;
	my $file_ext=$1;

	# Treat the files according to their extension
	if ($file_ext =~ /tcl/) { &analyze_tcl($file); }
#	if ($file_ext =~ /adp/) { &analyze_adp($file); }
	if ($file_ext =~ /xql/) { &analyze_xql($file); }
}
close(FILES);


# Print a new line in the CSV file for every 
# package that we find...
# file may look like: "N:\aimdev\packages\nesta-static\..."
#
sub print_header {
	(my $file) = @_;
	print "print_header: file='$file'\n" if ($debug);	

	if ($file =~ /packages\/([^\/]*)\//) {
		my $package_key = $1;
		if ($last_package_key ne $package_key) {
			print "$package_key\n";
			$last_package_key = $package_key;
		}
	
	}
}


# Analyze a single TCL file:
# We're currently checking for the the presence of 
# autentication only ([auth::require_login] or similar).
#
sub analyze_tcl {
	(my $file) = @_;
	print "analyze_tcl: file='$file'\n" if ($debug);

	my $require_login = 0;
	my $ad_maybe_redirect_for_registration = 0;
	my $ad_verify_and_get_user_id = 0;
	my $unsave_dollar = 0;
	my $comment = "";
	
	open(F, $file);
	while (my $line = <F>) {
		$require_login++ if ($line =~ /require_login/);
		$ad_maybe_redirect_for_registration++ if ($line =~ /ad_maybe_redirect_for_registration/);
		$ad_verify_and_get_user_id++ if ($line =~ /ad_verify_and_get_user_id/);
	}	
	close(F);

	# Calculate the status - green, yellow or red
	my $sum = $require_login + $ad_maybe_redirect_for_registration + $ad_verify_and_get_user_id;
	my $status = "undefined";
	if ($sum == 0) {
		$status = "red";
		$comment = "Didn't find any authentication in file";
	}
	if ($sum > 0) {
		$status = "yellow";
		$comment = "Authentication found, but deprecated";
	}
	$status = "green" if ($require_login > 0);

	print "$file,$status,$require_login,$ad_maybe_redirect_for_registration,$ad_verify_and_get_user_id,$unsave_dollar,\"$comment\"\n";
}


# Analyze a single XQL file:
# We just check that it doesn't contain "$"-variables.
# 
#
sub analyze_xql {
	(my $file) = @_;
	print "analyze_xql: file='$file'\n" if ($debug);

	my $dollar_count = 0;
	my $status = "undefined";
	my $comment = "";

	open(F, $file);
	while (my $line = <F>) {
		if ($line =~ /\$(\w*)/) {
			$dollar_count++;
			$comment = $comment." \$$1";
		}
	}	
	close(F);

	# Calculate the status - green, yellow or red
	$status = "green";
	if ($dollar_count > 0) {
		$status = "yellow";
		$comment = $comment." - Found a \$ character in XQL file";
	}

	print "$file,$status,0,0,0,$dollar_count,\"$comment\"\n";
}

