#!/usr/bin/perl
#
# Tag all P/O modules with a new version
#
# 2005-05-03 
# Frank Bergmann <frank.bergmann@project-open.com>

$version = "3.0.0.0.4";
$date = `/bin/date +"%Y-%m-%d"`;
$time = `/bin/date +"%H-%M"`;
$debug = 0;
$base_dir = "/web/ptdemo";			# no trailing "/"!
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
	my $module_name = $file;

	my $cmd = "cd $packages_dir; cvs tag edit $module_name.info";
	print "update_info_file: cmd=$cmd\n";
	system($cmd);
}
close(FILES);


