#!/usr/bin/perl
# -----------------------------------------------------------------------
# benchmark-mixed.perl
#
# A benchmark that models users logging into a system, looking at 
# a project and at a few other pages.
# This behaviour corresponds more or less with reality, the pages
# selected are taken from production systems.
# 
# The default parameters correspond to a "vanilla" system.
# -----------------------------------------------------------------------

use strict;
use warnings;
use CGI ':standard';
use LWP::UserAgent;
use HTML::Form;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use Getopt::Long;
use threads;

my $debug = 0;					# 0=no, 1=slow queries, 5=very verbose
my $threads = 5;				# How many parallel users?
my $sleep = 10;	 				# Average wait between pages. Real users first read...
my $host = 'http://localhost:8000';		# :8000 for direct, :80 for NGINX
my $email = 'sysadmin@tigerpond.com';		# SysAdmin email - default for ]po[
my $pass = 'system';				# SysAdmin password - default for ]po[
my $iterations = 10;				# Repeat how many times? First and last are different

# More constants than parameters...
my $max_exp = 14;				# Max 2**14 milliseconds in histogram display
my $slow_page_ms = 1000;			# When is a page "slow"? -> 1000ms

GetOptions (
    "debug=i" => \$debug,
    "threads=i" => \$threads,
    "sleep=i" => \$sleep,
    "iterations=i" => \$iterations,
    "host=s" => \$host,
    "email=s" => \$email,
    "pass=s" => \$pass
) or die ("Error in command line arguments\n");


my @projects;
my @users;

# Turn on auto-flush for STDOUT
$| = 1;

print "debug=$debug, sleep=$sleep, iterations=$iterations, host=$host, email=$email, pass=$pass\n";
print_time_histogram_header();

my @thread_list;
for (my $t = 0; $t < $threads; $t++) { push @thread_list, $t; }
foreach (@thread_list) { $_ = threads->create(\&run); sleep(1); }
foreach (@thread_list) { $_->join(); }
exit 0;


sub run {
    for (my $iter = 0; $iter < $iterations; $iter++) {
	my %url_time_hash = ("asdf" => [1]);
	my $ref = \%url_time_hash;

	my $ua = login($ref, $host);
	@users = list_users($ref, $ua); sleep(rand 2*$sleep);
	my $rand_user_id = $users[rand @users];
	become($ref, $ua, $rand_user_id);
	view_home($ref, $ua, $rand_user_id); sleep(rand 2*$sleep);
	@projects = list_projects($ref, $ua); sleep(rand 2*$sleep);
	log_hours($ref, $ua, $rand_user_id); sleep(rand 2*$sleep);
	my $rand_project_id = $projects[rand @projects];
	view_project($ref, $ua, $rand_project_id, $rand_user_id); sleep(rand 2*$sleep);
	view_pages($ref, $ua, $rand_user_id);
	print_time_histogram($ref);
    }

}

sub log_time {
    my ($ref, $url, $start, $end) = @_;
    my %url_time_hash = %$ref;

    my $duration = int(10.0 * 1000.0 * ($end - $start)) / 10.0;
    print "log_time($url, $duration)\n" if ($debug > 6);
    push @{ $ref->{$url} }, $duration;

    # print Dumper(%url_time_hash);
}

# Returns browser
sub login {
    my ($ref, $host) = @_;
    print "login($host)\n" if ($debug > 1);

    # Get the Web page: Encode URL and keep cookies
    my $browser = LWP::UserAgent->new;
    # Allow the browser to store cookies
    $browser->cookie_jar({});
    # Allow the browser to redirect after a POST request
    push @{$browser->requests_redirectable}, 'POST';

    my $base_url = '/intranet/auto-login';
    my $auto_login_url = $host.$base_url;
    my %parameters = (
	'email' => $email,
	'password' => $pass,
	'url' => '/favicon.ico'
	);
    my $url = URI->new($auto_login_url);
    $url->query_form(%parameters);

    my $repeat = 1;
    while ($repeat) {
	my $start = gettimeofday();
	my $response = $browser->get($url);
	my $end = gettimeofday();
	log_time($ref, $base_url, $start, $end);
	print "login($host): response=".$response->status_line."\n" if ($debug > 3);
	if ($response->is_success) {
	    $repeat = 0;
	} else {
	    print "login($host): $response->status_line\n";
	    print "login($host): ".Dumper($response->status_line)."\n";
	    $repeat = 1;
	}
    }

    return $browser
}

sub list_users {
    my ($ref, $browser) = @_;
    print "users()\n" if ($debug > 2);

    my $users_url = $host.'/intranet/users/index?how_many=100000&user_group_name=employees';
    my $start = gettimeofday();
    my $response = $browser->get($users_url);
    my $end = gettimeofday();
    log_time($ref, $users_url, $start, $end);
    print "users(): response=".$response->status_line."\n" if ($debug > 3 || !$response->is_success);

    my $html = $response->decoded_content; 
    my @lines = split('\n', $html);
    my @users = ();
    for my $line (@lines) {
	if ($line =~ /intranet\/users\/view\?user_id=([0-9]+)/) { push @users, $1; }
    }

    # Convert array into unique array
    my %user_hash = map { $_, 1 } @users;
    return keys %user_hash
}


sub list_projects {
    my ($ref, $browser) = @_;
    print "projects()\n" if ($debug > 2);

    my $projects_url = $host.'/intranet/projects/index?how_many=100000';
    my $start = gettimeofday();
    my $response = $browser->get($projects_url);
    my $end = gettimeofday();
    log_time($ref, $projects_url, $start, $end);

    print "projects(): response=".$response->status_line."\n" if ($debug > 3 || !$response->is_success);
    my $html = $response->decoded_content; 
    my @lines = split('\n', $html);
    my @projects = ();
    for my $line (@lines) {
	if ($line =~ /intranet\/projects\/view\?project_id=([0-9]+)/) { push @projects, $1; }
    }

    # Convert array into unique array
    my %projects_hash = map { $_, 1 } @projects;
    return keys %projects_hash
}


sub view_project {
    my ($ref, $browser, $pid, $uid) = @_;
    print "view_project($pid,$uid)\n" if ($debug > 2);

    my @urls = (
"/intranet/projects/view?project_id=$pid",
"/intranet-gantt-editor/controller/GanttButtonController.js",
"/intranet-gantt-editor/controller/GanttSchedulingController.js",
"/intranet-gantt-editor/controller/GanttTreePanelController.js",
"/intranet-gantt-editor/controller/GanttZoomController.js",
"/intranet-gantt-editor/view/GanttBarPanel.js",
"/intranet-rest/data-source/project-task-tree.json?read=1&_dc=1514716515105&project_id=$pid&node=root",
"/intranet-rest/group?_dc=1514716515091&format=json&page=1&start=0&limit=100000",
"/intranet-rest/im_category?_dc=1514716515086&format=json&category_type=%27Intranet%20Project%20Status%27&page=1&start=0&limit=25",
"/intranet-rest/im_cost_center?_dc=1514716515090&format=json&page=1&start=0&limit=25",
"/intranet-rest/im_material?_dc=1514716515089&format=json&page=1&start=0&limit=100000&sort=%5B%7B%22property%22%3A%22material_name%22%2C%22direction%22%3A%22DESC%22%7D%5D",
"/intranet-rest/im_sencha_preference?_dc=1514716515106&format=json&preference_url=%27%2Fintranet%2Fprojects%2Fview%3F%26return_url%3D%252fintranet-timesheet2%252fhours%252findex%253fjulian_date%253d2458119%2526user_id_from_search%253d$uid%26project_id%3D$pid%27&preference_object_id=$uid&user_id=$uid&auth_token=E49C48C78552E96CA8D24AD31985A9846C98C05B&page=1&start=0&limit=100000",
"/intranet-rest/user?_dc=1514716515091&format=json&query=user_id%20in%20(%09%09%09%09%09%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20select%09r.object_id_two%09%09%09%09%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20from%09acs_rels%20r%2C%09%09%09%09%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20im_projects%20main_p%2C%09%09%09%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20im_projects%20sub_p%09%09%09%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20where%09main_p.project_id%20%3D%20$pid%20and%09%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20sub_p.tree_sortkey%20between%20main_p.tree_sortkey%20and%20tree_right(main_p.tree_sortkey)%20and%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20r.object_id_one%20%3D%20sub_p.project_id%09%20%20%20%20%20%20%20%20)&page=1&start=0&limit=100000",
"/intranet-rest/user?_dc=1514716515106&format=json&query=user_id%20in%20(select%20object_id_two%20from%20acs_rels%20where%20object_id_one%20in%20(select%20group_id%20from%20groups%20where%20group_name%20%3D%20%27Employees%27))&page=1&start=0&limit=100000",
"/intranet/images/navbar_default/add.png",
"/intranet/images/navbar_default/arrow_out.png",
"/intranet/images/navbar_default/arrow_refresh.png",
"/intranet/images/navbar_default/clock.png",
"/intranet/images/navbar_default/cog.png",
"/intranet/images/navbar_default/cog_go.png",
"/intranet/images/navbar_default/delete.png",
"/intranet/images/navbar_default/disk.png",
"/intranet/images/navbar_default/lock.png",
"/intranet/images/navbar_default/zoom.png",
"/intranet/images/navbar_default/zoom_in.png",
"/intranet/images/navbar_default/zoom_out.png",
"/sencha-core/Utilities.js",
"/sencha-core/class/PreferenceStateProvider.js",
"/sencha-core/controller/ResizeController.js",
"/sencha-core/controller/StoreLoadCoordinator.js",
"/sencha-core/model/category/Category.js",
"/sencha-core/model/group/Group.js",
"/sencha-core/model/helpdesk/Ticket.js",
"/sencha-core/model/timesheet/CostCenter.js",
"/sencha-core/model/timesheet/Material.js",
"/sencha-core/model/timesheet/TimesheetTask.js",
"/sencha-core/model/user/SenchaPreference.js",
"/sencha-core/model/user/User.js",
"/sencha-core/store/CategoryStore.js",
"/sencha-core/store/group/GroupStore.js",
"/sencha-core/store/helpdesk/TicketStore.js",
"/sencha-core/store/timesheet/TaskCostCenterStore.js",
"/sencha-core/store/timesheet/TaskMaterialStore.js",
"/sencha-core/store/timesheet/TaskStatusStore.js",
"/sencha-core/store/timesheet/TaskTreeStore.js",
"/sencha-core/store/user/SenchaPreferenceStore.js",
"/sencha-core/store/user/UserStore.js",
"/sencha-core/view/field/POComboGrid.js",
"/sencha-core/view/field/PODateField.js",
"/sencha-core/view/field/POTaskAssignment.js",
"/sencha-core/view/gantt/AbstractGanttPanel.js",
"/sencha-core/view/gantt/GanttTaskPropertyPanel.js",
"/sencha-core/view/gantt/GanttTreePanel.js",
"/sencha-core/view/menu/AlphaMenu.js",
"/sencha-core/view/menu/ConfigMenu.js",
"/sencha-core/view/menu/HelpMenu.js",
"/sencha-core/view/task/TaskManagementMixin.js",
"/sencha-core/view/theme/TaskStatusTheme.js",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/exclamation.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/text-bg.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/trigger.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/grid3-hd-btn.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/e-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/ne-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/nw-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/s-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/se-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/sw-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/arrows.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/util/splitter/mini-left.gif"
	);

    for my $url (@urls) {
	my $start = gettimeofday();
	my $response = $browser->get($host.$url);
	my $end = gettimeofday();
	log_time($ref, $url, $start, $end);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	print threads->tid()."\t".$hour.":".$min.":".$sec."\t"."view_project($pid,$uid,$url): response=".$response->status_line."\n" if ($debug > 5 || !$response->is_success);
    }
}



sub view_home {
    my ($ref, $browser, $uid) = @_;
    print "home($uid)\n" if ($debug > 2);

    my @urls = (
"/intranet/",
"/intranet/images/add.png",
"/intranet/images/cancel.png",
"/intranet/images/component-seperator.gif",
"/intranet/images/conf_wizard_help.png",
"/intranet/images/conf_wizard_professional_support.png",
"/intranet/images/conf_wizard_professional_versions.png",
"/intranet/images/conf_wizard_saas.png",
"/intranet/images/folder-add.png",
"/intranet/images/lock-add.png",
"/intranet/images/lock-delete.png",
"/intranet/images/navbar_default/arrow_comp_down.png",
"/intranet/images/navbar_default/arrow_comp_left.png",
"/intranet/images/navbar_default/arrow_comp_maximize.png",
"/intranet/images/navbar_default/arrow_comp_right.png",
"/intranet/images/navbar_default/arrow_comp_up.png",
"/intranet/images/navbar_default/bug.png",
"/intranet/images/navbar_default/coins.png",
"/intranet/images/navbar_default/comp_delete.png",
"/intranet/images/navbar_default/config.png",
"/intranet/images/navbar_default/help.png",
"/intranet/images/navbar_default/house.png",
"/intranet/images/navbar_default/key.png",
"/intranet/images/navbar_default/nav-hamburger-active.png",
"/intranet/images/navbar_default/time.png",
"/intranet/images/navbar_default/wrench.png",
"/intranet/images/navbar_saltnpepper/gradback_light_grey.gif",
"/intranet/images/navbar_saltnpepper/tableftJ.gif",
"/intranet/images/navbar_saltnpepper/tabrightJ.gif",
"/intranet/images/plus_blue_15_15.gif",
"/intranet/images/zip-download.gif",
"/intranet/images/zip-upload.gif",
"/intranet/js/jquery.min.js",
"/intranet/js/rounded_corners.inc.js",
"/intranet/js/showhide.js",
"/intranet/js/smartmenus/jquery.smartmenus.min.js",
"/intranet/js/style.saltnpepper.js",
"/intranet/style/print.css",
"/intranet/style/smartmenus/sm-core-css.css",
"/intranet/style/smartmenus/sm-simple/sm-simple.css",
"/intranet/style/style.common.css",
"/intranet/style/style.saltnpepper.css",
"/resources/acs-developer-support/acs-developer-support.css",
"/resources/acs-subsite/core.js",
"/resources/acs-subsite/default-master.css",
"/resources/acs-templating/forms.css",
"/resources/acs-templating/lists.css",
"/resources/acs-templating/mktree.css",
"/resources/acs-templating/mktree.js",
"/resources/acs-templating/plus.gif",
"/sencha-core/Utilities.js",
"/sencha-core/model/helpdesk/Ticket.js",
"/sencha-core/store/helpdesk/TicketStore.js",
"/sencha-core/view/menu/AlphaMenu.js",
"/sencha-core/view/menu/HelpMenu.js",
"/sencha-core/view/task/TaskManagementMixin.js",
"/sencha-core/view/theme/TaskStatusTheme.js",
"/sencha-extjs-v421/ext-all.js",
"/sencha-extjs-v421/resources/css/ext-all-gray.css",
"/sencha-extjs-v421/resources/ext-theme-gray/ext-theme-gray-all.css",
"/sencha-extjs-v421/resources/ext-theme-gray/images/button/arrow.gif"
    );

    for my $url (@urls) {
	my $start = gettimeofday();
	my $response = $browser->get($host.$url);
	my $end = gettimeofday();
	log_time($ref, $url, $start, $end);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	print threads->tid()."\t".$hour.":".$min.":".$sec."\t"."home($uid,$url): response=".$response->status_line."\n" if ($debug > 5 || !$response->is_success);
    }
}


sub view_pages {
    my ($ref, $browser, $uid) = @_;
    print "view_pages($uid)\n" if ($debug > 2);

    my @urls = (
"/intranet/companies/", "",
"/intranet/companies/dashboard", "",
"/intranet-confdb/index", "",
"/intranet-crm-opportunities/", "",
"/intranet-crm-opportunities/opportunities", "",
"/intranet-expenses/", "",
"/intranet-gantt-editor/controller/GanttButtonController.js",
"/intranet-gantt-editor/controller/GanttSchedulingController.js",
"/intranet-gantt-editor/controller/GanttTreePanelController.js",
"/intranet-gantt-editor/controller/GanttZoomController.js",
"/intranet-gantt-editor/view/GanttBarPanel.js",
# "/intranet-ganttproject/gantt-resources-cube?&config=resource_planning_report", "", # old and slow > 1500ms
"/intranet-helpdesk/", "",
"/intranet-helpdesk/dashboard", "",
"/intranet-helpdesk/new", "",
"/intranet-idea-management/", "",
"/intranet/images/add.png",
"/intranet/images/bb_clear.gif",
"/intranet/images/bb_red.gif",
"/intranet/images/bb_yellow.gif",
"/intranet/images/cancel.png",
"/intranet/images/cleardot.gif",
"/intranet/images/component-seperator.gif",
"/intranet/images/delete.gif",
"/intranet/images/del.gif",
"/intranet/images/demoserver/andrew_accounting_bw.jpg",
"/intranet/images/demoserver/andrew_accounting.jpg",
"/intranet/images/demoserver/angelique_picard_bw.jpg",
"/intranet/images/demoserver/angelique_picard.jpg",
"/intranet/images/demoserver/ben_bigboss_bw.jpg",
"/intranet/images/demoserver/ben_bigboss.jpg",
"/intranet/images/demoserver/bobby_bizconsult_bw.jpg",
"/intranet/images/demoserver/bobby_bizconsult.jpg",
"/intranet/images/demoserver/dagmar_tejada_bw.jpg",
"/intranet/images/demoserver/dagmar_tejada.jpg",
"/intranet/images/demoserver/david_developer_bw.jpg",
"/intranet/images/demoserver/david_developer.jpg",
"/intranet/images/demoserver/ester_arenas_bw.jpg",
"/intranet/images/demoserver/ester_arenas.jpg",
"/intranet/images/demoserver/larry_littleboss_bw.jpg",
"/intranet/images/demoserver/larry_littleboss.jpg",
"/intranet/images/demoserver/laura_leadarchitect_bw.jpg",
"/intranet/images/demoserver/laura_leadarchitect.jpg",
"/intranet/images/demoserver/petra_projectmanager_bw.jpg",
"/intranet/images/demoserver/petra_projectmanager.jpg",
"/intranet/images/demoserver/sally_sales_bw.jpg",
"/intranet/images/demoserver/sally_sales.jpg",
"/intranet/images/demoserver/samuel_salesmanager_bw.jpg",
"/intranet/images/demoserver/samuel_salesmanager.jpg",
"/intranet/images/demoserver/tracy_troubleshoot_bw.jpg",
"/intranet/images/demoserver/tracy_troubleshoot.jpg",
"/intranet/images/empty21.gif",
"/intranet/images/empty_9.gif",
"/intranet/images/exp-gif.gif",
"/intranet/images/exp-jpg.gif",
"/intranet/images/exp-pdf.gif",
"/intranet/images/exp-text.gif",
"/intranet/images/exp-unknown.gif",
"/intranet/images/exp-word.gif",
"/intranet/images/external.png",
"/intranet/images/folder-add.png",
"/intranet/images/folder_s.gif",
"/intranet/images/foldin2.gif",
"/intranet/images/foldout2.gif",
"/intranet/images/k.gif",
"/intranet/images/lock-add.png",
"/intranet/images/lock-delete.png",
"/intranet/images/m.gif",
"/intranet/images/minus_9.gif",
"/intranet/images/navbar_default/1100.png",
"/intranet/images/navbar_default/1102.png",
"/intranet/images/navbar_default/1106.png",
"/intranet/images/navbar_default/1190.gif",
"/intranet/images/navbar_default/add.png",
"/intranet/images/navbar_default/arrow_comp_down.png",
"/intranet/images/navbar_default/arrow_comp_left.png",
"/intranet/images/navbar_default/arrow_comp_maximize.png",
"/intranet/images/navbar_default/arrow_comp_minimize.png",
"/intranet/images/navbar_default/arrow_comp_right.png",
"/intranet/images/navbar_default/arrow_comp_up.png",
"/intranet/images/navbar_default/arrow_in.png",
"/intranet/images/navbar_default/arrow_left.png",
"/intranet/images/navbar_default/arrow_out.png",
"/intranet/images/navbar_default/arrow_refresh.png",
"/intranet/images/navbar_default/arrow_right.png",
"/intranet/images/navbar_default/bb_clear.gif",
"/intranet/images/navbar_default/bb_green.gif",
"/intranet/images/navbar_default/bb_red.gif",
"/intranet/images/navbar_default/bb_yellow.gif",
"/intranet/images/navbar_default/box.png",
"/intranet/images/navbar_default/brick_link.png",
"/intranet/images/navbar_default/bug.png",
"/intranet/images/navbar_default/calculator.png",
"/intranet/images/navbar_default/chart_curve.png",
"/intranet/images/navbar_default/clock.png",
"/intranet/images/navbar_default/cog_go.png",
"/intranet/images/navbar_default/cog.png",
"/intranet/images/navbar_default/coins.png",
"/intranet/images/navbar_default/comments.png",
"/intranet/images/navbar_default/comp_delete.png",
"/intranet/images/navbar_default/computer.png",
"/intranet/images/navbar_default/config.png",
"/intranet/images/navbar_default/csv-doc.png",
"/intranet/images/navbar_default/cup.png",
"/intranet/images/navbar_default/database_table.png",
"/intranet/images/navbar_default/default_object_type_gif.png",
"/intranet/images/navbar_default/delete.png",
"/intranet/images/navbar_default/disk.png",
"/intranet/images/navbar_default/error.png",
"/intranet/images/navbar_default/group_add.png",
"/intranet/images/navbar_default/group.png",
"/intranet/images/navbar_default/help.png",
"/intranet/images/navbar_default/hourglass.png",
"/intranet/images/navbar_default/house.png",
"/intranet/images/navbar_default/key.png",
"/intranet/images/navbar_default/layout.png",
"/intranet/images/navbar_default/lightning_add.png",
"/intranet/images/navbar_default/lightning.png",
"/intranet/images/navbar_default/link_add.png",
"/intranet/images/navbar_default/link_break.png",
"/intranet/images/navbar_default/link.png",
"/intranet/images/navbar_default/lock.png",
"/intranet/images/navbar_default/magifier_zoom_out.png",
"/intranet/images/navbar_default/magnifier_zoom_in.png",
"/intranet/images/navbar_default/milestone.png",
"/intranet/images/navbar_default/money_dollar.png",
"/intranet/images/navbar_default/money.png",
"/intranet/images/navbar_default/nav-hamburger-active.png",
"/intranet/images/navbar_default/nav-hamburger.png",
"/intranet/images/navbar_default/newspaper_add.png",
"/intranet/images/navbar_default/newspaper.png",
"/intranet/images/navbar_default/note_add.png",
"/intranet/images/navbar_default/note.png",
"/intranet/images/navbar_default/package.png",
"/intranet/images/navbar_default/page.png",
"/intranet/images/navbar_default/page_white_star.png",
"/intranet/images/navbar_default/tag_blue_add.png",
"/intranet/images/navbar_default/tag_blue.png",
"/intranet/images/navbar_default/thumbs_up.pale.24.gif",
"/intranet/images/navbar_default/thumbs_up.pressed.24.gif",
"/intranet/images/navbar_default/tick_add.png",
"/intranet/images/navbar_default/tick.png",
"/intranet/images/navbar_default/time.png",
"/intranet/images/navbar_default/user_go.png",
"/intranet/images/navbar_default/user_green.png",
"/intranet/images/navbar_default/user.png",
"/intranet/images/navbar_default/wrench.png",
"/intranet/images/navbar_default/zoom_in.png",
"/intranet/images/navbar_default/zoom_out.png",
"/intranet/images/navbar_default/zoom.png",
"/intranet/images/navbar_saltnpepper/gradback_light_grey.gif",
"/intranet/images/navbar_saltnpepper/gradhover_light_grey.gif",
"/intranet/images/navbar_saltnpepper/tableftJ.gif",
"/intranet/images/navbar_saltnpepper/tabrightJ.gif",
"/intranet/images/p.gif",
"/intranet/images/plus_9.gif",
"/intranet/images/project_open.70x26.gif",
"/intranet/images/project-types/pm-agile.png",
"/intranet/images/project-types/pm-classic.png",
"/intranet/images/project-types/pm-maintenance.png",
"/intranet/images/project-types/pm-mixed.png",
"/intranet/images/turn.gif",
"/intranet/images/zip-download.gif",
"/intranet/images/zip-upload.gif",
"/intranet/js/jquery.min.js",
"/intranet/js/rounded_corners.inc.js",
"/intranet/js/showhide.js",
"/intranet/js/smartmenus/jquery.smartmenus.min.js",
"/intranet/js/style.saltnpepper.js",
"/intranet/master-data", "",
"/intranet-milestone/", "",
"/intranet-portfolio-management/", "",
"/intranet-portfolio-management/dashboard", "",
"/intranet-portfolio-management/programs-list", "",
"/intranet-portfolio-management/risk-vs-roi", "",
"/intranet-portfolio-management/strategic-value-vs-roi", "",
"/intranet-portfolio-planner/", "",
"/intranet-portfolio-planner/cost-center-tree-resource-availability.json",
"/intranet-portfolio-planner/main-projects-forward-load.json",
"/intranet-portfolio-planner/store/CostCenterTreeResourceLoadStore.js",
"/intranet-portfolio-planner/store/ProjectResourceLoadStore.js",
"/intranet-portfolio-planner/view/PortfolioPlannerCostCenterPanel.js",
"/intranet-portfolio-planner/view/PortfolioPlannerCostCenterTree.js",
"/intranet-portfolio-planner/view/PortfolioPlannerProjectPanel.js",
"/intranet/projects/dashboard", "",
"/intranet-reporting/", "",
"/intranet-reporting-dashboard/top-customers.json",
# "/intranet-reporting-indicators/", "",
"/intranet-reporting/view?report_code=rest_portfolio_planner_updates&format=json", "",
"/intranet-resource-management/index", "",
"/intranet-resource-management/resources-planning", "",
"/intranet-rest/group",
"/intranet-rest/im_category",
"/intranet-rest/im_company",
"/intranet-rest/im_cost_center",
# "/intranet-rest/im_indicator_result",
"/intranet-rest/im_material",
"/intranet-rest/im_project?query=parent_id%20is%20null",
"/intranet-rest/user",
"/intranet-riskmanagement/index", "",
"/intranet-riskmanagement/new", "",
"/intranet-riskmanagement/project-risks-report", "",
# "/intranet-search/search?type=all&q=documents", "", # slow
# "/intranet-search/search?type=all&q=task", "", # slow
"/intranet-simple-survey/reporting/traffic-light-report", "",
"/intranet/style/print.css",
"/intranet/style/smartmenus/sm-core-css.css",
"/intranet/style/smartmenus/sm-simple/sm-simple.css",
"/intranet/style/style.common.css",
"/intranet/style/style.saltnpepper.css",
"/intranet-task-management/images/status_blue",
"/intranet-task-management/images/status_grey",
"/intranet-task-management/images/status_purple",
"/intranet-task-management/images/status_red",
"/intranet-task-management/images/status_yellow",
"/intranet-timesheet2/absences/dashboard", "",
"/intranet-timesheet2/absences/index", "",
"/intranet-timesheet2/absences/new", "",
"/intranet-timesheet2/hours/dashboard", "",
"/intranet-timesheet2/hours/index", "",
# "/intranet-timesheet2-workflow/reports/unsubmitted-hours.tcl", "", # slow
"/intranet/users/biz-card-add", "",
"/intranet/users/dashboard", "",
"/intranet/users/index", "",
"/intranet/users/index?filter_advanced_p=1", "",
"/intranet/users/new", "",
"/intranet/whos-online", "",
"/intranet-workflow/", "",
"/resources/acs-developer-support/acs-developer-support.css",
"/resources/acs-subsite/core.js",
"/resources/acs-subsite/default-master.css",
"/resources/acs-templating/calendar.gif",
"/resources/acs-templating/forms.css",
"/resources/acs-templating/lists.css",
"/resources/acs-templating/mktree.css",
"/resources/acs-templating/mktree.js",
"/resources/acs-templating/sort-descending.png",
"/resources/acs-templating/sort-neither.png",
"/resources/diagram/diagram/diagram_dom.js",
"/resources/diagram/diagram/diagram.js",
"/resources/xowiki/get-http-object.js",
"/resources/xowiki/sprite16.png",
"/resources/xowiki/xowiki.css",
"/sencha-core/class/PreferenceStateProvider.js",
"/sencha-core/controller/ResizeController.js",
"/sencha-core/controller/StoreLoadCoordinator.js",
"/sencha-core/model/category/Category.js",
"/sencha-core/model/finance/CostCenter.js",
"/sencha-core/model/group/Group.js",
"/sencha-core/model/helpdesk/Ticket.js",
"/sencha-core/model/project/Project.js",
"/sencha-core/model/timesheet/CostCenter.js",
"/sencha-core/model/timesheet/Material.js",
"/sencha-core/model/timesheet/TimesheetTaskDependency.js",
"/sencha-core/model/timesheet/TimesheetTask.js",
"/sencha-core/model/user/SenchaPreference.js",
"/sencha-core/model/user/User.js",
"/sencha-core/store/CategoryStore.js",
"/sencha-core/store/group/GroupStore.js",
"/sencha-core/store/helpdesk/TicketStore.js",
"/sencha-core/store/project/ProjectMainStore.js",
"/sencha-core/store/timesheet/TaskCostCenterStore.js",
"/sencha-core/store/timesheet/TaskMaterialStore.js",
"/sencha-core/store/timesheet/TaskStatusStore.js",
"/sencha-core/store/timesheet/TaskTreeStore.js",
"/sencha-core/store/timesheet/TimesheetTaskDependencyStore.js",
"/sencha-core/store/user/SenchaPreferenceStore.js",
"/sencha-core/store/user/UserStore.js",
"/sencha-core/Utilities.js",
"/sencha-core/ux/chart/axis/KPIGauge.js",
"/sencha-core/ux/chart/series/KPIGauge.js",
"/sencha-core/view/field/POComboGrid.js",
"/sencha-core/view/field/PODateField.js",
"/sencha-core/view/field/POTaskAssignment.js",
"/sencha-core/view/gantt/AbstractGanttPanel.js",
"/sencha-core/view/gantt/GanttTaskPropertyPanel.js",
"/sencha-core/view/gantt/GanttTreePanel.js",
"/sencha-core/view/menu/AlphaMenu.js",
"/sencha-core/view/menu/ConfigMenu.js",
"/sencha-core/view/menu/HelpMenu.js",
"/sencha-core/view/task/TaskManagementMixin.js",
"/sencha-core/view/theme/TaskStatusTheme.js",
"/sencha-extjs-v421/ext-all.js",
"/sencha-extjs-v421/resources/css/ext-all-gray.css",
"/sencha-extjs-v421/resources/ext-theme-gray/ext-theme-gray-all.css",
"/sencha-extjs-v421/resources/ext-theme-gray/images/button/arrow.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/button/s-arrow-light.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/dd/drop-no.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/editor/tb-sprite.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/checkbox.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/date-trigger.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/exclamation.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/spinner.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/spinner-small.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/text-bg.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/form/trigger.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/columns.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/dirty.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/grid3-hd-btn.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/hmenu-asc.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/hmenu-desc.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/invalid_line.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/loading.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/grid/sort_asc.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/menu/checked.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/menu/menu-parent.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/menu/scroll-bottom.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/menu/scroll-top.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/menu/unchecked.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/shared/icon-info.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/shared/icon-question.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/shared/left-btn.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/shared/right-btn.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/e-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/ne-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/nw-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/se-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/s-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/sizer/sw-handle.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tab-bar/default-scroll-left-top.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tab-bar/default-scroll-right-top.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/toolbar/more.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tools/tool-sprites.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/arrows.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/drop-above.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/drop-append.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/drop-below.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/drop-between.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/elbow-end.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/elbow-end-minus.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/elbow.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/elbow-line.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/elbow-minus.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/elbow-plus.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/folder.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/folder-open.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/tree/leaf.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/util/splitter/mini-left.gif",
"/sencha-extjs-v421/resources/ext-theme-gray/images/util/splitter/mini-right.gif",
"/shared/images/info.gif",
"/xowiki/", ""
    );

    for my $url (@urls) {
	if ("" eq $url) {
	    sleep(rand 2*$sleep);
	    next;
	}

	my $start = gettimeofday();
	my $response = $browser->get($host.$url);
	my $end = gettimeofday();
	log_time($ref, $url, $start, $end);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	print threads->tid()."\t".$hour.":".$min.":".$sec."\t"."view_pages($uid,$url): response=".$response->status_line."\n" if ($debug > 5 || !$response->is_success);
    }
}



sub member_add {
    my ($ref, $browser, $pid, $uid) = @_;
    print "member_add($pid, $uid)\n" if ($debug > 2);

    my $member_url = "$host/intranet/member-add-2?object_id=$pid&user_id_from_search=$uid&role_id=1300&return_url=/intranet/";
    my $response = $browser->get($member_url);
    print "member(): response=".$response->status_line."\n" if ($debug > 3 || !$response->is_success);
}



sub become {
    my ($ref, $browser, $uid) = @_;
    print "become($uid)\n" if ($debug > 1);

    my $become_url = $host.'/intranet/users/become?user_id='.$uid;
    my $start = gettimeofday();
    my $response = $browser->get($become_url);
    my $end = gettimeofday();
    log_time($ref, $become_url, $start, $end);
    print "become($uid): response=".$response->status_line."\n" if ($debug > 3 || !$response->is_success);
}


sub log_hours {
    my ($ref, $browser, $uid) = @_;
    print "log_hours($uid)\n" if ($debug > 1);

    my $base_url = "/intranet-timesheet2/hours/new";
    my $url = $host.$base_url.'?show_week_p=0&user_id_from_search='.$uid;
    my $start = gettimeofday();
    my $response = $browser->get($url);
    my $end = gettimeofday();
    log_time($ref, $base_url, $start, $end);
    print "log_hours($uid): response=".$response->status_line."\n" if ($debug > 3 || !$response->is_success);

    # Extract forms from HTML. The third form should be called "timesheet"
    my @forms = HTML::Form->parse($response);
    if (!@forms) { 
	print "log_hours($uid): no form found\n";
	die $response->decoded_content; 
    }

    # Get the timesheet form
    @forms = grep "timesheet" eq (defined($_->attr("name")) ? $_->attr("name") : ""), @forms;
    if (!@forms) { 
	print "log_hours($uid): no projects found - adding\n";
	my $rand_pid = $projects[rand @projects];
	member_add($ref, $browser, $rand_pid, $uid);
	return; 
    }

    # Get the list of "hour" entry fields
    my $form = shift @forms;
    my @input_names = $form->param;
    my @hours = ();
    foreach my $input_name (@input_names) {
	if ($input_name =~ /^hours/) { push @hours, $input_name; }
    }
    if (@hours == 0) { 
	print "log_hours($uid): no hours found, adding\n";
	my $rand_pid = $projects[rand @projects];
	member_add($ref, $browser, $rand_pid, $uid);
	return; 
    }

    # Choose a random element
    my $rand_input_name = $hours[rand @hours];
    # die Dumper($rand_input_name);

    # Set a random value to form element
    my $rand_value = int(10.0 * rand(8)) / 10;
    #die Dumper($rand_value);
    my $uid_field = $form->find_input($rand_input_name);
    # print "uid_field: ".$rand_input_name." - ".Dumper($uid_field);
    $uid_field->value("".$rand_value);
    # die $form->dump;

    # POST the updated form
    my $request = $form->click;
    $start = gettimeofday();
    $response = $browser->request($request);
    $end = gettimeofday();
    log_time($ref, $base_url."-2", $start, $end);
    print "log_hours($uid): response=".$response->status_line."\n" if ($debug > 3 || !$response->is_success);
}


# Print header
sub print_time_histogram_header {
    print "tid\t";
    print "cnt\t";
    print "avg\t";
    for (my $i = 0; $i < $max_exp; $i++) { 
	my $bucket = 2 ** $i;
	print $bucket."\t";
    }
    print "\n";
}

sub print_time_histogram {
    my ($ref) = @_;
    print "print_time_histogram()\n" if ($debug > 5);
    my %url_time_hash = %{$ref};

    my %hist;
    my $max_value = 2 ** $max_exp;
    my $count = 0;
    my $sum = 0;
    my %slow_hash = ();
    my $slow_count = 0;

    for my $url (keys %url_time_hash) {
	print "$url: @{$url_time_hash{$url}}\n" if ($debug > 5);
	my @entries = @{$url_time_hash{$url}};
	for my $el (@entries) {
	
	    if ($el > $slow_page_ms) { 
		my $max_el = $el;
		if (exists $slow_hash{$url}) { $max_el = $slow_hash{$url}; }
		$slow_hash{$url} = $max_el; 
		$slow_count++; 
	    }
    
	    # Aggregate for average
	    $count++;
	    $sum = $sum + $el;

	    # Sort into buckets for histogram
	    if ($el > $max_value) { $el = $max_value; }
	    my $sqrt = int(0.5 + log($el) / log(2) );
	    $el = 2 ** $sqrt;
	    $hist{$el}++;
	}
    }

    # Print histogram in one line
    print threads->tid()."\t";
    print "$count\t";
    if ($count == 0) { $count = 1; }
    print int(0.5 + $sum / $count)."\t";
    for (my $i = 0; $i < $max_exp; $i++) { 
	my $bucket = 2 ** $i;
	if (exists $hist{$bucket}) { print $hist{$bucket}; }
	print "\t";
    }
    print "\n";

    # Show the slowest queries
    if ($slow_count > 0 && $debug > 0) {
	for my $slow_url (keys %slow_hash) {
	    print "slow_page($slow_url) = ".$slow_hash{$slow_url}."\n";
	}
    }

}

