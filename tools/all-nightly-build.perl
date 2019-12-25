#!/usr/bin/perl
#
# *******************************************************************
# Creates a current snapshot of public ]po[ packages.
#
# 2015-09-25
# Frank Bergmann <frank.bergmann@project-open.com>
# *******************************************************************

# This file assumes a ~/.ssh/fraber\@shell.sf.net
# private key in the .ssh directory of the user (po50dev)
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


print "all-nightly-build: starting: $date\n";


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
$tar2 = "project-open-Update-$version.tgz";


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


$packages = "packages/acs-admin packages/acs-api-browser packages/acs-authentication packages/acs-automated-testing packages/acs-bootstrap-installer packages/acs-content-repository packages/acs-core-docs packages/acs-datetime packages/acs-developer-support packages/acs-events packages/acs-kernel packages/acs-lang packages/acs-mail packages/acs-mail-lite packages/acs-messaging packages/acs-reference packages/acs-service-contract packages/acs-subsite packages/acs-tcl packages/acs-templating packages/acs-translations packages/acs-workflow packages/ajaxhelper packages/attachments packages/calendar packages/categories packages/diagram packages/file-storage packages/general-comments packages/intranet-agile packages/intranet-baseline packages/intranet-calendar packages/intranet-confdb packages/intranet-core packages/intranet-cost packages/intranet-crm-opportunities packages/intranet-csv-import packages/intranet-cvs-integration packages/intranet-demo-data packages/intranet-dw-light packages/intranet-dynfield packages/intranet-earned-value-management packages/intranet-exchange-rate packages/intranet-expenses packages/intranet-expenses-workflow packages/intranet-filestorage packages/intranet-forum packages/intranet-gantt-editor packages/intranet-ganttproject packages/intranet-helpdesk packages/intranet-hr packages/intranet-idea-management packages/intranet-invoices packages/intranet-jira packages/intranet-mail-import packages/intranet-material packages/intranet-milestone packages/intranet-nagios packages/intranet-notes packages/intranet-notes-tutorial packages/intranet-payments packages/intranet-planning packages/intranet-portfolio-management packages/intranet-portfolio-planner packages/intranet-project-scoring packages/intranet-release-mgmt packages/intranet-reporting packages/intranet-reporting-dashboard packages/intranet-reporting-finance packages/intranet-reporting-indicators packages/intranet-reporting-openoffice packages/intranet-reporting-tutorial packages/intranet-resource-management packages/intranet-rest packages/intranet-riskmanagement packages/intranet-rule-engine packages/intranet-search-pg packages/intranet-search-pg-files packages/intranet-security-update-client packages/intranet-sharepoint packages/intranet-sla-management packages/intranet-simple-survey packages/intranet-sql-selectors packages/intranet-sysconfig packages/intranet-task-management packages/intranet-timesheet2 packages/intranet-timesheet2-invoices packages/intranet-timesheet2-tasks packages/intranet-timesheet2-workflow packages/intranet-wiki packages/intranet-workflow packages/notifications packages/oacs-dav packages/openacs-default-theme packages/ref-countries packages/ref-currency packages/ref-language packages/ref-timezones packages/rss-support packages/search packages/sencha-core packages/sencha-extjs-v421 packages/senchatouch-timesheet packages/senchatouch-v242 packages/simple-survey packages/tsearch2-driver packages/workflow packages/xotcl-core packages/xotcl-request-monitor packages/xowiki";


# *******************************************************************
# Upload the tar to upload.sourceforge.net

print "all-nightly-build: tarring code\n" if $debug;

if (!(-e "$tar_dir/$tar")) {
    system("rm -f $tar_dir/$tar");
}

system("cd ~/; tar  --create --gzip -f $tar_dir/$tar --exclude='upgrade-3.*' --exclude='upgrade-4.*' --exclude='*~' --exclude-vcs $readme $license $changelog $packages");


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

    # Create a SourceForge "shell"
    system("echo exit | ssh -t -i ~/.ssh/fraber\@shell.sf.net fraber,project-open\@shell.sourceforge.net create");

    # Upload the file
    system("scp -i ~/.ssh/fraber\@shell.sf.net $tar_dir/$tar fraber,project-open\@shell.sourceforge.net:/home/frs/project/project-open/project-open/V5.0/nightly/");

    # Rename the tar 
    system("mv $tar_dir/$tar $tar_dir/$tar2");

    # Update the 2nd tar with only version name
    system("scp -i ~/.ssh/fraber\@shell.sf.net $tar_dir/$tar2 fraber,project-open\@shell.sourceforge.net:/home/frs/project/project-open/project-open/V5.0/update/");

    # Destroy the shell
    system("echo exit | ssh -t -i ~/.ssh/fraber\@shell.sf.net fraber,project-open\@shell.sourceforge.net shutdown");

    # Send out a message
    system("echo $tar_dir/$tar | mail -s 'po50dev: $tar' fraber@fraber.de");

} else {
    print "all-nightly-build: Nothing changed - no SourceForge upload necessary\n";
}


# move current to last
system("cd $tar_dir; rm -rf last");
system("cd $tar_dir; mv current last");

