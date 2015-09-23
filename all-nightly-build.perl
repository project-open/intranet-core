#!/usr/bin/perl
#
# *******************************************************************
# Creates a current snapshot of public ]po[ packages.
#
# 2015-09-25
# Frank Bergmann <frank.bergmann@project-open.com>
# *******************************************************************

# This file assumes a ~/.ssh/fraber\@shell.sf.net
# private key in the .ssh directory of the user (po40dev)
# in order to upload the nightly builds to the SF
# server:
# 1. Create a key pair:
#    ssh-keygen -t dsa -C "fraber@shell.sf.net"
#    and save as ~/.ssh/fraber\@shell.sf.net.
# 2. Past the ~/.ssh/fraber\@shell.sf.net.pub
#    public key content into:
#    https://sourceforge.net/auth/shell_services
# 3. Wait 30minutes until the key has been 
#    distributed within SF.



use File::Compare;

# *******************************************************************
$debug = 1;

$date = `/bin/date +"%Y-%m-%d"`;
chomp($date);
$year = `/bin/date +"%Y"`;
chomp($year);
$time = `/bin/date +"%H-%M"`;
chomp($time);
$date_short = `/bin/date +"%Y%m%d"`;
chomp($date_short);
$time_short = `/bin/date +"%H%M%S"`;
chomp($time_short);



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

$tar_dir = "~/builds";
$tar = "project-open-Nightly-$version-$date_short-$time_short.tgz";


# *******************************************************************
# Check if we've got an argument and use as override for version

if (@ARGV == 1) {
    if ($version =~ /\d+\.\d+/) {
	$tar = "project-open-Nightly-$ARGV[0].tgz";
    }
}

# *******************************************************************
# Generate README and LICENSE
my $sed = "sed -e 's/X.Y.Z.V.W/$version/; s/YYYY-MM-DD/$date/; s/YYYY/$year/'";

print "all-nightly-build: generating README in ~/\n" if $debug;
system("rm -f ~/$readme");
system("cat ~/packages/intranet-core/README.ProjectOpen.Update | $sed > ~/$readme");

print "all-nightly-build: generating LICENSE in ~/\n" if $debug;
system("rm -f ~/$license");
system("cat ~/packages/intranet-core/LICENSE.ProjectOpen | $sed > ~/$license");

print "all-nightly-build: generating CHANGELOG in ~/\n" if $debug;
system("rm -f ~/$changelog");
system("cat ~/packages/intranet-core/CHANGELOG.ProjectOpen | $sed > ~/$changelog");



# *******************************************************************
# Determine the packages to include
#
# Not Included:
#packages/acs-lang-server
#packages/auth-ldap
#packages/batch-importer
#packages/intranet-big-brother
#packages/chat
#packages/ecommerce
#packages/batch-importer
#packages/cms
#packages/contacts
#packages/intranet
#packages/intranet-amberjack
#packages/intranet-asus-server
#packages/intranet-audit
#packages/intranet-baseline
#packages/intranet-calendar-holidayspackages/packages/(obsolete)
#packages/intranet-contacts
#packages/intranet-cost-center
#packages/intranet-crm-tracking
#packages/intranet-earned-value-managementpackages/(enterprise)
#packages/intranet-freelance
#packages/intranet-freelance-invoices
#packages/intranet-freelance-rfqs
#packages/intranet-freelance-translation
#packages/intranet-funambol
#packages/intranet-gtd-dashboard
#packages/intranet-html2pdfpackages/packages/packages/(obsolete)
#packages/intranet-notes-tutorial
#packages/intranet-ophelia
#packages/intranet-otp
#packages/intranet-pdf-htmldoc
#packages/intranet-procedurespackages/packages/packages/(obsolete)
#packages/intranet-reporting-cubes
#packages/intranet-reporting-dashboard
#packages/intranet-reporting-finance
#packages/intranet-reporting-translation
#packages/intranet-riskmanagement			(not ready yet)
#packages/intranet-sencha				(GPL V3.0)
#packages/intranet-sencha-ticket-tracker		(GPL V3.0)
#packages/intranet-sharepoint
#packages/intranet-scrum
#packages/intranet-security-update-server
#packages/intranet-spam
#packages/intranet-sql-selectors
#packages/intranet-timesheet2-task-popup
#packages/intranet-tinytm
#packages/intranet-trans-quality
#packages/intranet-ubl
#packages/intranet-update-server
#packages/telecom-number
#packages/trackback
#


$packages = "packages/acs-admin packages/acs-api-browser packages/acs-authentication packages/acs-automated-testing packages/acs-bootstrap-installer packages/acs-content-repository packages/acs-core-docs packages/acs-datetime packages/acs-developer-support packages/acs-events packages/acs-kernel packages/acs-lang packages/acs-mail packages/acs-mail-lite packages/acs-messaging packages/acs-reference packages/acs-service-contract packages/acs-subsite packages/acs-tcl packages/acs-templating packages/acs-translations packages/acs-workflow packages/ajaxhelper packages/attachments packages/auth-ldap-adldapsearch packages/bug-tracker packages/bulk-mail packages/calendar packages/categories packages/diagram packages/file-storage packages/general-comments packages/intranet-bug-tracker packages/intranet-calendar packages/intranet-confdb packages/intranet-core packages/intranet-cost packages/intranet-csv-import packages/intranet-cvs-integration packages/intranet-dw-light packages/intranet-dynfield packages/intranet-exchange-rate packages/intranet-expenses packages/intranet-expenses-workflow packages/intranet-filestorage packages/intranet-forum packages/intranet-ganttproject packages/intranet-helpdesk packages/intranet-hr packages/intranet-idea-management packages/intranet-invoices packages/intranet-invoices-templates packages/intranet-mail-import packages/intranet-material packages/intranet-milestone packages/intranet-nagios packages/intranet-notes packages/intranet-payments packages/intranet-portfolio-management packages/intranet-release-mgmt packages/intranet-reporting packages/intranet-reporting-indicators packages/intranet-reporting-openoffice packages/intranet-reporting-tutorial packages/intranet-resource-management packages/intranet-rest packages/intranet-riskmanagement packages/intranet-rss-reader packages/intranet-search-pg packages/intranet-search-pg-files packages/intranet-security-update-client packages/intranet-sharepoint packages/intranet-simple-survey packages/intranet-sla-management packages/intranet-sysconfig packages/intranet-timesheet2 packages/intranet-timesheet2-invoices packages/intranet-timesheet2-tasks packages/intranet-timesheet2-workflow packages/intranet-trans-invoices packages/intranet-translation packages/intranet-trans-project-wizard packages/intranet-update-client packages/intranet-wiki packages/intranet-workflow packages/intranet-xmlrpc packages/mail-tracking packages/notifications packages/oacs-dav packages/openacs-default-theme packages/organizations packages/oryx-ts-extensions packages/intranet-planning packages/postal-address packages/ref-countries packages/ref-language packages/ref-timezones packages/ref-us-counties packages/ref-us-states packages/ref-us-zipcodes packages/rss-support packages/search packages/simple-survey packages/tsearch2-driver packages/wiki packages/workflow packages/xml-rpc packages/xotcl-core packages/xowiki";


# *******************************************************************
# Upload the tar to upload.sourceforge.net

print "all-nightly-build: tarring code\n" if $debug;
system("rm -f $tar_dir/$tar");
system("cd ~/; tar  --create --gzip -f $tar_dir/$tar --exclude='upgrade-*' --exclude='*~' --exclude-vcs $readme $license $changelog $packages");



# *******************************************************************
# Check if the new file is different from the old one
# and load the new file to sourceforge.net
#

# Create a dummy "last" if not yet present
if (!(-e "$tar_dir/last")) {
    system("mkdir -p $tar_dir/last");
}

# Create a "current" directory with current content
system("rm -rf $tar_dir/current");
system("mkdir -p $tar_dir/current");
system("cd $tar_dir/current; tar xzf $tar_dir/$tar");
system("chmod -R ug+w $tar_dir/current");

# Check if the two folders are different
$modified_lines = `diff -w -r $tar_dir/last $tar_dir/current | wc -l`;
chomp($modified_lines);
print "all-nightly-build: Diff size: '$modified_lines'\n";


if ("0" ne $modified_lines) {
    print "all-nightly-build: SourceForge upload:\n";
    system("scp -i ~/.ssh/fraber\@shell.sf.net $tar_dir/$tar fraber,project-open\@shell.sourceforge.net:/home/frs/project/project-open/project-open/V4.1/");
    system("echo $tar_dir/$tar | mail -s 'po40dev: $tar' fraber@fraber.de");
} else {
    print "all-nightly-build: Nothing changed - no SourceForge upload necessary\n";
}


# move current to last
system("cd $tar_dir; rm -rf last");
system("cd $tar_dir; mv current last");

