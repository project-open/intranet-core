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
$dump = "pg_dump.$version.sql.bz2";
$tar = "project-open-$version-update.tgz";


# *******************************************************************
# Check if we've got an argument and use as override for version

if (@ARGV == 1) {
    if ($version =~ /\d+\.\d+/) {
	$tar = "project-open-$ARGV[0]-update.tgz";
    }
}

# *******************************************************************
# Generate README and LICENSE
my $sed = "sed -e 's/X.Y.Z.V.W/$version/; s/YYYY-MM-DD/$date/; s/YYYY/$year/'";

print "all-upload: generating README in ~/\n" if $debug;
system("rm -f ~/$readme");
system("cat ~/packages/intranet-core/README.ProjectOpen.Update | $sed > ~/$readme");

print "all-upload: generating LICENSE in ~/\n" if $debug;
system("rm -f ~/$license");
system("cat ~/packages/intranet-core/LICENSE.ProjectOpen | $sed > ~/$license");

print "all-upload: generating CHANGELOG in ~/\n" if $debug;
system("rm -f ~/$changelog");
system("cat ~/packages/intranet-core/CHANGELOG.ProjectOpen | $sed > ~/$changelog");



# *******************************************************************
# Determine the packages to include

$packages = "packages/acs-admin packages/acs-api-browser packages/acs-authentication packages/acs-automated-testing packages/acs-bootstrap-installer packages/acs-content-repository packages/acs-core-docs packages/acs-datetime packages/acs-developer-support packages/acs-events packages/acs-kernel packages/acs-lang packages/acs-mail packages/acs-mail-lite packages/acs-messaging packages/acs-reference packages/acs-service-contract packages/acs-subsite packages/acs-tcl packages/acs-templating packages/acs-workflow packages/ajaxhelper packages/auth-ldap-adldapsearch packages/bug-tracker packages/bulk-mail packages/calendar packages/categories packages/chat packages/cms packages/contacts packages/diagram packages/ecommerce packages/events packages/general-comments packages/intranet-big-brother packages/intranet-bug-tracker packages/intranet-calendar packages/intranet-confdb packages/intranet-core packages/intranet-cost packages/intranet-dw-light packages/intranet-dynfield packages/intranet-exchange-rate packages/intranet-expenses packages/intranet-filestorage packages/intranet-forum packages/intranet-ganttproject packages/intranet-helpdesk packages/intranet-hr packages/intranet-invoices packages/intranet-invoices-templates packages/intranet-mail-import packages/intranet-material packages/intranet-milestone packages/intranet-nagios packages/intranet-notes packages/intranet-payments packages/intranet-release-mgmt packages/intranet-reporting packages/intranet-reporting-indicators packages/intranet-reporting-tutorial packages/intranet-search-pg packages/intranet-security-update-client packages/intranet-simple-survey packages/intranet-sysconfig packages/intranet-timesheet2 packages/intranet-timesheet2-invoices packages/intranet-timesheet2-tasks packages/intranet-tinytm packages/intranet-trans-invoices packages/intranet-translation packages/intranet-trans-project-wizard packages/intranet-update-client packages/intranet-wiki packages/intranet-workflow packages/lars-blogger packages/notifications packages/organizations packages/oryx-ts-extensions packages/postal-address packages/ref-countries packages/ref-language packages/ref-timezones packages/ref-us-counties packages/ref-us-states packages/ref-us-zipcodes packages/rss-support packages/search packages/simple-survey packages/wiki packages/workflow packages/xml-rpc";



# *******************************************************************
# Upload the tar to upload.sourceforge.net

print "all-upload: tarring code\n" if $debug;
system("rm -f ~/$tar");
system("cd ~/; tar czf ~/$tar $readme $license $changelog $dump $packages");



# *******************************************************************
# End
print "all-upload: SourceForge upload:\n";
print "rsync -avP -e ssh ~/$tar fraber\@frs.sourceforge.net:uploads/\n";

