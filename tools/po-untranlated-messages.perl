#!/usr/bin/perl

# --------------------------------------------------------------
# po-untranslated-messages.perl
#
# Analyzes a log file and creates a number of DB statements to insert the missing language keys
# 2010-04-05 Frank Bergmann
# --------------------------------------------------------------

# Constants, variables and parameters
#
$debug = 0;
$file = $ARGV[0];

print "po-untranslated-messages: Analyzing file: $file\n" if $debug > 0;

open(FILE, $file);
while (my $line=<FILE>) {
    chomp($line);

    # line looks like this:
    # [11/Apr/2010:14:49:38][28470.78687120][-conn2-] Error: lang::message::lookup: Key 'intranet-core.Translation_Freelance_List' does not exist in en_US
    if ($line =~ /Error: lang::message::lookup: Key \'([^']*)\' does not/) {
	my $compound_key = $1;
	print "po-untranslated-messages: found untranslated key '$compound_key'\n" if $debug > 0;

	if ($compound_key =~ /^([a-zA-Z\-]*)\.(.*)/) {
	    my $package_key = $1;
	    my $message_key = $2;

	    if ($package_key =~ /\ /) {
		print "ERROR: package_key '$package_key' contains spaces.\n";
		next;
	    }
	    if ($message_key =~ /\ /) {
		print "ERROR: message_key '$message_key' contains spaces.\n";
		next;
	    }

	    print "SELECT im_lang_add_message('en_US','$package_key','$message_key','$message_key');\n"
	}
    }
}
close(FILE);

