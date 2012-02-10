#!/usr/bin/perl
#
# Modify the version information in all Packages
# in order to provide the APM with correct install/reinstall
# options
#
# 2009-05-21 
# Frank Bergmann <frank.bergmann@project-open.com>

if (@ARGV != 1) {
    die "
all-version-packages: You need to specify exactly one argument.
Usage:
	all-version-packages <VersionNumber>

VersionNumber = Maj.Min.Serv.Bug.Intl\n\n"
}

$version = $ARGV[0];

if ($version =~ /^\d+\.\d+\.\d+\.\d+\.\d+$/) {
    # Nothing, seems OK
} else {
    die "
all-version-packages: Wrong version number format
Usage:
	all-version-packages <VersionNumber>

VersionNumber = Maj.Min.Serv.Bug.Intl\n\n"
}

print "ver=$version\n";

$date = `/bin/date +"%Y-%m-%d"`;
$time = `/bin/date +"%H-%M"`;
$debug = 0;
$base_dir = "/web/po40demo";			# no trailing "/"!
$packages_dir = "$base_dir/packages";		# no trailing "/"!

# Remove trailing \n from date & time
chomp($date);
chomp($time);

# Main loop: use "find" to get the list of all packages
#
open(FILES, "cd $packages_dir; ls -1 | grep 'intranet-*' |");
while (my $file=<FILES>) {
        # Remove trailing "\n"
        chomp($file);

	print "update_info_files: updating '$file'\n";
	update_info_file($file);
}
close(FILES);


sub update_info_file {
    (my $module_name) = @_;
    
    $filename = $packages_dir . "/" . $module_name . "/" . $module_name . ".info";
    print "update_info_file: filename=$filename\n" if ($debug);

    my $cmd = "cd $packages_dir/$module_name; cvs edit $module_name.info";
    print "update_info_file: cmd=$cmd\n";
    system($cmd);

    $result = "";
    open(F, $filename);
    while (my $line = <F>) {
	chomp($line);

	# Check if the line is the "<version name= ...>" line and replace
	if ($line =~ /<version name=/) {
	    $result .= "    <version name=\"$version\" url=\"http://www.project-open.org/download/apm/$module_name-$version.apm\">\n";
	} else {
	    $result .= "$line\n";
	}

    }
    close(F);
    
    open(F, "> $filename");
    print F $result;
    close(F);
}

