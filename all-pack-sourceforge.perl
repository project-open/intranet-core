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
$dump = "pg_dump.$version.sql";
$tar = "project-open-Update-$version.tgz";


# *******************************************************************
# Check if we've got an argument and use as override for version

if (@ARGV == 1) {
    if ($version =~ /\d+\.\d+/) {
	$tar = "project-open-Update-$ARGV[0].tgz";
    }
}

# *******************************************************************
# Generate README and LICENSE
my $sed = "sed -e 's/X.Y.Z.V.W/$version/; s/YYYY-MM-DD/$date/; s/YYYY/$year/'";

print "all-pack-sourceforge: generating README in ~/\n" if $debug;
system("rm -f ~/$readme");
system("cat ~/packages/intranet-core/README.ProjectOpen.Update | $sed > ~/$readme");

print "all-pack-sourceforge: generating LICENSE in ~/\n" if $debug;
system("rm -f ~/$license");
system("cat ~/packages/intranet-core/LICENSE.ProjectOpen | $sed > ~/$license");

print "all-pack-sourceforge: generating CHANGELOG in ~/\n" if $debug;
system("rm -f ~/$changelog");
system("cat ~/packages/intranet-core/CHANGELOG.ProjectOpen | $sed > ~/$changelog");



# *******************************************************************
# Determine the packages to include
#
# Not Included:
#	acs-lang-server
#	auth-ldap
#	batch-importer
#	chat
#	ecommerce
#	batch-importer
#	contacts
#	intranet
#	intranet-amberjack
#	intranet-asus-server
#	intranet-audit
#	intranet-baseline
#	intranet-calendar-holidays		(obsolete)
#	intranet-contacts
#	intranet-cost-center
#	intranet-crm-tracking
#	intranet-earned-value-management	(enterprise)
#	intranet-freelance
#	intranet-freelance-invoices
#	intranet-freelance-rfqs
#	intranet-freelance-translation
#	intranet-gtd-dashboard
#	intranet-html2pdf			(obsolete)
#	intranet-notes-tutorial
#	intranet-ophelia
#	intranet-otp
#	intranet-pdf-htmldoc
#	intranet-procedures			(obsolete)
#	intranet-reporting-cubes
#	intranet-reporting-dashboard
#	intranet-reporting-finance
#	intranet-reporting-translation
#	intranet-riskmanagement			(not ready yet)
#	intranet-sencha				(GPL V3.0)
#	intranet-sencha-ticket-tracker		(GPL V3.0)
#	intranet-sharepoint
#	intranet-scrum
#	intranet-security-update-server
#	intranet-spam
#	intranet-sql-selectors
#	intranet-timesheet2-task-popup
#	intranet-trans-quality
#	intranet-ubl
#	intranet-update-server
#	telecom-number
#	trackback
#


$packages = "packages/acs-admin packages/acs-api-browser packages/acs-authentication packages/acs-automated-testing packages/acs-bootstrap-installer packages/acs-content-repository packages/acs-core-docs packages/acs-datetime packages/acs-developer-support packages/acs-events packages/acs-kernel packages/acs-lang packages/acs-mail packages/acs-mail-lite packages/acs-messaging packages/acs-reference packages/acs-service-contract packages/acs-subsite packages/acs-tcl packages/acs-templating packages/acs-translations packages/acs-workflow packages/ajaxhelper packages/attachments packages/auth-ldap-adldapsearch packages/bug-tracker packages/bulk-mail packages/calendar packages/categories packages/cms packages/diagram packages/file-storage packages/general-comments packages/intranet-big-brother packages/intranet-bug-tracker packages/intranet-calendar packages/intranet-confdb packages/intranet-core packages/intranet-cost packages/intranet-csv-import packages/intranet-cvs-integration packages/intranet-dw-light packages/intranet-dynfield packages/intranet-exchange-rate packages/intranet-expenses packages/intranet-expenses-workflow packages/intranet-filestorage packages/intranet-forum packages/intranet-funambol packages/intranet-ganttproject packages/intranet-helpdesk packages/intranet-hr packages/intranet-idea-management packages/intranet-invoices packages/intranet-invoices-templates packages/intranet-mail-import packages/intranet-material packages/intranet-milestone packages/intranet-nagios packages/intranet-notes packages/intranet-payments packages/intranet-planning packages/intranet-portfolio-management packages/intranet-release-mgmt packages/intranet-reporting packages/intranet-reporting-indicators packages/intranet-reporting-openoffice packages/intranet-reporting-tutorial packages/intranet-resource-management packages/intranet-rest packages/intranet-riskmanagement packages/intranet-rss-reader packages/intranet-scrum packages/intranet-search-pg packages/intranet-search-pg-files packages/intranet-security-update-client packages/intranet-sharepoint packages/intranet-simple-survey packages/intranet-sla-management packages/intranet-sysconfig packages/intranet-timesheet2 packages/intranet-timesheet2-invoices packages/intranet-timesheet2-tasks packages/intranet-timesheet2-workflow packages/intranet-tinytm packages/intranet-trans-invoices packages/intranet-translation packages/intranet-trans-project-wizard packages/intranet-update-client packages/intranet-wiki packages/intranet-workflow packages/intranet-xmlrpc packages/mail-tracking packages/notifications packages/oacs-dav packages/openacs-default-theme packages/organizations packages/oryx-ts-extensions packages/postal-address packages/ref-countries packages/ref-language packages/ref-timezones packages/ref-us-counties packages/ref-us-states packages/ref-us-zipcodes packages/rss-support packages/search packages/simple-survey packages/tsearch2-driver packages/wiki packages/workflow packages/xml-rpc packages/xotcl-core packages/xowiki";


# *******************************************************************
# Upload the tar to upload.sourceforge.net

print "all-pack-sourceforge: tarring code\n" if $debug;
system("rm -f ~/$tar");
print "all-pack-sourceforge: cd ~/; tar czf ~/$tar $readme $license $changelog $packages\n";
system("cd ~/; tar czf ~/$tar $readme $license $changelog $packages");



# *******************************************************************
# End
print "all-pack-sourceforge: SourceForge upload:\n";

# Old FRS
# print "rsync -avP -e ssh ~/$tar fraber\@frs.sourceforge.net:uploads/\n";

# New FRS 2009-10-20:
print "all-pack-sourceforge: rsync -avP -e ssh ~/$tar fraber,project-open\@frs.sourceforge.net:/home/frs/project/p/pr/project-open/project-open/V4.0/\n"

