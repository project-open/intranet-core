#!/usr/bin/perl
#
# *******************************************************************
# Creates a releasable TAR of ]po[ packages.
# Then prints out the command to upload the file to SourceForge.
#
# 2008-05-26
# Frank Bergmann <frank.bergmann@project-open.com>
# *******************************************************************


# *******************************************************************
$debug = 1;
$gen_version = 0;

$date = `/bin/date +"%Y-%m-%d"`;
chomp($date);
$year = `/bin/date +"%Y"`;
chomp($year);
$time = `/bin/date +"%H-%M"`;
chomp($time);



# *******************************************************************
# Get the version

my $version_line = `grep 'version name' ~/packages/intranet-core/intranet-core.info`;
my $version; my $x; my $y; my $z; my $v; my $w;
my $readme; my $tar; my $packages;
# <version name="3.3.1.2.0" url="http://projop.dnsalias.com/download/apm/intranet-core-3.3.1.2.0.apm">
if ($version_line =~ /\"(.)\.(.)\.(.)\.(.)\.(.)\"/) { 
    $x = $1;
    $y = $2;
    $z = $3;
    $v = $4;
    $w = $5;
    $version = "$x.$y.$z.$v.$w";
} else {
    die "Could not determine version.\n Version string: $version_line";
}

$readme = "README.project-open.$version.txt";
$license = "LICENSE.project-open.$version.txt";
$changelog = "CHANGELOG.project-open.$version.txt";
$tar = "project-open-$version-update.tgz";
$packages = "packages.$version";


# *******************************************************************
# Check if we've got an argument and use as override for version

if (@ARGV == 1) {
    if ($version =~ /\d+\.\d+/) {
	$tar = "project-open-$ARGV[0]-update.tgz";
    }
}


# *******************************************************************
# Cleanup /tmp/, create new folder and checkout version

# Delete the last version if exists
if ($gen_version) {
    print "all-upload: deleting /tmp/$packages\n" if $debug;
    system("rm -rf /tmp/$packages/");
    
    # Create a new directory and copy installer checkout
    print "all-upload: create directory /tmp/$packages\n" if $debug;
    system("mkdir -p /tmp/$packages");

    print "all-upload: checking out packages\n" if $debug;
    system("cp -f ~/packages/intranet-core/all-installer-checkout.sh /tmp/$packages/");
    system("cd /tmp/$packages/; bash all-installer-checkout.sh");

}

# *******************************************************************
# Generate README and LICENSE
my $sed = "sed -e 's/X.Y.Z.V.W/$version/; s/YYYY-MM-DD/$date/; s/YYYY/$year/'";

print "all-upload: generating README in /tmp/\n" if $debug;
system("rm -f /tmp/$readme");
system("cat ~/packages/intranet-core/README.ProjectOpen.Update | $sed > /tmp/$readme");

print "all-upload: generating LICENSE in /tmp/\n" if $debug;
system("rm -f /tmp/$license");
system("cat ~/packages/intranet-core/LICENSE.ProjectOpen | $sed > /tmp/$license");

print "all-upload: generating CHANGELOG in /tmp/\n" if $debug;
system("rm -f /tmp/$changelog");
system("cat ~/packages/intranet-core/CHANGELOG.ProjectOpen | $sed > /tmp/$changelog");



# *******************************************************************
# Tar the stuff in /tmp/packages

print "all-upload: deleting old tar\n" if $debug;
system("rm -f /tmp/$tar");
system("rm -f /tmp/$packages/all-installer-checkout.sh");


# *******************************************************************
# Upload the tar to upload.sourceforge.net

print "all-upload: tarring code\n" if $debug;
system("rm -f /tmp/$packages/all-installer-checkout.sh");
system("rm -f /tmp/$tar");
system("cd /tmp/; tar czf /tmp/$tar $readme $license $changelog $packages");



# *******************************************************************
# End
print "all-upload: SourceForge upload:\n";
print "rsync -avP -e ssh /tmp/$tar fraber\@frs.sourceforge.net:uploads/\n";

