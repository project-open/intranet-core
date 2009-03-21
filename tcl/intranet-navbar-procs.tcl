# /packages/intranet-core/tcl/intranet-navbar-procs.tcl
#
# Copyright (C) 1998-2007 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {
    Define the left-hand process oriented navigation bar
    @author Frank Bergmann (frank.bergmann@project-open.com)
}


# --------------------------------------------------------
# 
# --------------------------------------------------------

# from Klaus: "The ]po[ objects are clear from the top menu,
# but the underlying processes are unclear.

# ToDo: Skills for HR
# ToDo: Salaries report in HR
# Accounts Payable as first element in Finance
# Project Sales Pipeline more explicitely
# Setup menu as separate menu under "Processes" in Menu tree
# Quality Management as subprocess of Provider Mgmt?
# Sales Pipeline as separate process?
# Query/Incident Management as subprocess of project managent?
# Risk Mgmt as part of PM?
# Project Portfolio Mgmt as separate Process?
# Integrate indicators per process



ad_proc -public im_navbar_tree { 
    {-user_id 0}
    {-label ""} 
} {
    Creates an <ul> ...</ul> hierarchical list with all major
    objects in the system.
} {
    if {0 == $user_id} { set user_id [ad_get_user_id] }
    return [util_memoize [list im_navbar_tree_helper -user_id $user_id -label $label] 3600]
}

ad_proc -public im_navbar_tree_helper { 
    -user_id:required
    {-label ""} 
} {
    Creates an <ul> ...</ul> hierarchical list with all major
    objects in the system.
} {
    set show_left_functional_menu_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "ShowLeftFunctionalMenupP" -default 0]
    if {!$show_left_functional_menu_p} { return "" }

    set html "
      <hr/>
      	<div class=filter-block>
	<ul class=mktree>
	[im_menu_li home]
	<ul>
		[im_menu_li home]
		[im_menu_li dashboard]
		<li><a href=/register/logout>Logout</a>
	</ul>

	[if {![catch {set ttt [im_navbar_tree_project_management]}]} {set ttt} else {set ttt ""}]

	<li><a href=/intranet/>Human Resources</a>
	<ul>
		[im_menu_li timesheet2_timesheet]
		<li><a href=/intranet-timesheet2/absences/>Absences &amp; Vacations</a>
		<ul>

			<li><a href=/intranet-timesheet2/absences/new>New Absence</a></li>

			<li><a href=/intranet-timesheet2/absences/index?absence_type_id=5000>Vacation Requests</a></li>
			<li><a href=/intranet-timesheet2/absences/index?absence_type_id=5001>Personal Absences</a></li>
			<li><a href=/intranet-timesheet2/absences/index?absence_type_id=5002>Sick Leave Requests</a></li>
			<li><a href=/intranet-timesheet2/absences/index?absence_type_id=5003>Travel Requests</a></li>
			<li><a href=/intranet-timesheet2/absences/index?absence_type_id=5004>Bank Holidays</a></li>
		</ul>
		<li><a href=/intranet-expenses/>Travel Costs & Expenses</a>
		<ul>
			<li><a href=/intranet-expenses/new>New Travel Cost/Expense</a>
		</ul>
		<li><a href=/intranet-reporting/user-contacts>Users &amp; Contacts Report</a>

		<li><a href=/intranet-reporting/>Reporting</a>
                <ul>
                [im_menu_li "reporting-timesheet-productivity"]
		<!-- Additional reports in future HR area? --> 
                [im_navbar_write_tree -label "reporting-hr" -maxlevel 1]
                </ul>
	</ul>

	<li><a href=/intranet/>Sales &amp; Marketing</a>
	<ul>
		<li><a href=/intranet/projects/index>Project Proposals</a>
			<ul>
			<li><a href=/intranet/projects/new>New Project</a></li>
			<li><a href=/intranet/projects/index?project_status_id=71>All Potential Projects</a></li>
			<li><a href=/intranet/projects/index?project_status_id=72>Projects Inquiring</a></li>
			<li><a href=/intranet/projects/index?project_status_id=73>Projects Qualifiying</a></li>
			<li><a href=/intranet/projects/index?project_status_id=79>Projects Quoting</a></li>
			<li><a href=/intranet/projects/index?project_status_id=75>Projects Quote Out</a></li>
			<li><a href=/intranet/projects/index?project_status_id=76>Projects Open</a></li>
			<li><a href=/intranet/projects/index?project_status_id=76>All Open Projects</a></li>
			</ul>
		</li>
		<li><a href=/intranet/projects/index>Customer Prospects</a>
			<ul>
			<li><a href=/intranet/companies/new>New Customer</a></li>
			<li><a href=/intranet/companies/index?type_id=57&status_id=41>All Potential Customers</a></li>
			<li><a href=/intranet/companies/index?type_id=57&status_id=42>Customers Inquiring</a></li>
			<li><a href=/intranet/companies/index?type_id=57&status_id=43>Customers Qualifiying</a></li>
			<li><a href=/intranet/companies/index?type_id=57&status_id=44>Customers Quoting</a></li>
			<li><a href=/intranet/companies/index?type_id=57&status_id=45>Customers Quote Out</a></li>
			<li><a href=/intranet/companies/index?type_id=57&status_id=46>All Active Customers</a></li>
			</ul>
		</li>
		<li><a href=/intranet/projects/index>Quoting</a>
			<ul>
			<li><a href=/intranet-invoices/>New Quote</a></li>
			<li><a href=/intranet-invoices/list?cost_type_id=3702>All Quotes</a></li>
			</ul>
		</li>
		<li><a href=/intranet-reporting/>Reporting</a>
			<ul>
			<li><a href=/intranet-dw-light/companies.csv>Export Customers to CSV/Excel</a></li>
			[im_menu_li dashboard]
			[im_menu_li reporting-cubes-finance]
			</ul>
		</li>
	</ul>

	[if {![catch {set ttt [im_navbar_tree_provider_management]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_helpdesk]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_confdb]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_release_mgmt]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_collaboration]}]} {set ttt} else {set ttt ""}]
        [if {![catch {set ttt [im_navbar_tree_finance]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_master_data_management]}]} {set ttt} else {set ttt ""}]

	[im_navbar_tree_admin]
      </div>
    "
}


# --------------------------------------------------------
#
# --------------------------------------------------------



ad_proc -public im_navbar_tree_admin { 
} { 
    Admin Navbar 
} {
    set admin_p [im_is_user_site_wide_or_intranet_admin [ad_get_user_id]]
    if {!$admin_p} { return "" }
    set html "
	[im_menu_li admin]
		<ul>
		[im_navbar_write_tree -label "admin" -maxlevel 0]
		</ul>
	<li><a href=/acs-admin/>Developer Support</a>
		<ul>
		[im_navbar_write_tree -label "openacs" -maxlevel 0]
		</ul>
	</ul>
    "
    return $html
}


ad_proc -public im_navbar_tree_project_management { 
} { 
    Project Management Navbar 
} {
    set html "
	<li><a href=/intranet/projects/>Project Management</a>
	<ul>
		<li><a href=/intranet/projects/new>Create a New Project</a>
    "

    # Add sub-menu with project types
    append html "
        <li><a href=/intranet/projects/index>[lang::message::lookup "" intranet-core.Project_Types "Project Types"]</a>
        <ul>
    "
    set project_type_sql "
	select * from im_project_types 
	where project_type_id not in (select child_id from im_category_hierarchy)
	order by project_type
    "
    db_foreach project_types $project_type_sql {
        set url [export_vars -base "/intranet/projects/index" {project_type_id}]
        regsub -all " " $project_type "_" project_type_subst
        set name [lang::message::lookup "" intranet-core.Project_type_$project_type_subst "${project_type}s"]
        append html "<li><a href=\"$url\">$name</a></li>\n"
    }
    append html "
        </ul>
        </li>
    "

    # Add sub-menu with project status
    append html "
        <li><a href=/intranet/projects/index>[lang::message::lookup "" intranet-core.Project_Status "Project Status"]</a>
        <ul>
    "
    set project_status_sql "
	select * from im_project_status 
	where project_status_id not in (select child_id from im_category_hierarchy)
	order by project_status
    "
    db_foreach project_status $project_status_sql {
        set url [export_vars -base "/intranet/projects/index" {project_status_id}]
        regsub -all " " $project_status "_" project_status_subst
        set name [lang::message::lookup "" intranet-core.Project_status_$project_status_subst "$project_status"]
        append html "<li><a href=\"$url\">$name</a></li>\n"
    }
    append html "
        </ul>
        </li>
    "

    append html "
		<li><a href=/intranet-dw-light/projects.csv>Export Projects to CSV</a></li>
		<li><a href=/intranet/projects/index?filter_advanced_p=1>Project Advanced Filtering</a>
		<li><a href=/gantt-resources-cube?config=resource_planning_report>Project Resource Planning</a>
		<li><a href=/intranet/projects/index?view_name=project_costs>Projects Profit &amp; Loss</a>
    "

    append html "
	</ul>
    "
    return $html
}

ad_proc -public im_navbar_tree_provider_management { } { Provider Management } {
    return "
	<li><a href=/intranet/>Provider Management</a>
	<ul>
		<li><a href=/intranet-dw-light/companies.csv>Export Providers to CSV/Excel</a></li>
		<li><a href=/intranet/projects/index>Providers</a>
			<ul>
			<li><a href=/intranet/companies/new>New Provider Company</a></li>
			<li><a href=/intranet/users/new>New Provider Contact</a></li>
			<li><a href=/intranet-freelance/index>Search for Providers by Skills</a></li>
			[im_menu_li freelance_rfqs]
			</ul>
		</li>
		<li><a href=/intranet-reporting/>Reporting</a>
			<ul>
			[im_menu_li reporting-cubes-finance]
			<li><a href=/intranet-ganttproject/gantt-resources-cube?config=resource_planning_report>Project Resource Planning</a>
			</ul>
		</li>
	</ul>
    "
}



ad_proc -public im_navbar_tree_collaboration { } { Collaboration NavBar } {
    return "
	<li><a href=/intranet/>Collaboration</a>
	<ul>
		<li><a href=/intranet-search/search?type=all&q=search>[lang::message::lookup "" intranet-search-pg.Search_Engine "Search Engine"]</a>
		<li><a href=/calendar/>[lang::message::lookup "" intranet-calendar.Calendar "Calendar"]</a>
		[im_menu_li -pretty_name [lang::message::lookup "" intranet-core.Bug_Tracker "Bug Tracker"] bug_tracker]
		[im_menu_li forum]
		<ul>
			<li><a href=/intranet-forum/index?forum_topic_type_id=1100>News</a>
			<li><a href=/intranet-forum/index?forum_topic_type_id=1108>Notes</a>
			<li><a href=/intranet-forum/index?forum_topic_type_id=1106>Discussions</a>
			<li><a href=/intranet-forum/index?forum_topic_type_id=1104>Tasks</a>
			<li><a href=/intranet-forum/index?forum_topic_type_id=1102>Incidents</a>
		</ul>
		[im_menu_li -pretty_name Wiki wiki]
		<li><a href=/intranet-filestorage/>[lang::message::lookup "" intranet-core.File_Storage "File Storage"]</a>
		<li><a href=/simple-survey/>Surveys</a>
	</ul>
    "
}


ad_proc -public im_navbar_tree_master_data_management { } { Master Data Management } {
    set admin_p [im_is_user_site_wide_or_intranet_admin [ad_get_user_id]]
    if {!$admin_p} { return "" }

    return "
	<li><a href=/intranet/admin/categories/>Master Data Management</a>
	<ul>
		<li><a href=/intranet/companies/upload-companies>Import Companies from CSV</a>
		<li><a href=/intranet/users/upload-contacts>Import Contacts from CSV</a>
		<li><a href=/intranet/admin/categories/>General</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+UoM>Unit of Measure</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Projects</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Project+Status>Project Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Project+Type>Project Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Companies &amp; Offices</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Company+Customer+Prio>Company Customer Prio</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Company+Status>Company Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Company+Type>Company Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Office+Status>Office Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Office+Type>Office Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Absences &amp; Vacations</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Absence+Status>Absence Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Absence+Type>Absence Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>HR Recruiting</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Recruiting+Status>Recruiting Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Recruiting+Test+Result>Recruiting Test Result</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Employee+Pipeline+State>Employee Pipeline State</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Experience+Level>Experience Level</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Hiring+Source>Hiring Source</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Job+Title>Job Title</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Prior+Experience>Prior Experience</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Qualification+Process>Qualification Process</a>
		</ul>
		<li><a href=/intranet/admin/categories/>HR Skills &amp; Qualifications</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Skill+Type>Skill Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Skill+Weight>Skill Weight</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Operating+System>Operating System</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+LOC+Tool>LOC Tool</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+TM+Tool>TM Tool</a>
		</ul>
		<li><a href=/intranet/admin/categories/>RFQ/RFQ System</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Freelance+RFQ+Status>Freelance RFQ Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Freelance+RFQ+Type>Freelance RFQ Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Freelance+RFQ+Answer+Status>Freelance RFQ Answer Status</a>
	
		</ul>
		<li><a href=/intranet/admin/categories/>Expenses &amp; Travel Costs</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Expense+Type>Expense Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Expense+Payment+Type>Expense Payment Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Finance</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Invoice+Canned+Note>Invoice Canned Note</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Invoice+Payment+Method>Invoice Payment Method</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Invoice+Status>Invoice Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Invoice+Type>Invoice Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Cost+Template>Cost Template</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Payment+Type>Payment Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Materials (Service Types)</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Material+Status>Material Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Material+Type>Material Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Forum</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Topic+Status>Forum Topic Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Topic+Type>Forum Topic Type</a>
	
		</ul>
		<li><a href=/intranet/admin/categories/>Translation Specific</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Quality>Translation Quality</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+File+Type>Translation File Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+Language>Translation Language</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+Quality+Type>Translation Quality Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+Subject+Area>Translation Subject Area</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+Task+Status>Translation Task Status</a>
		</ul>
	</ul>
    "
}

# --------------------------------------------------------
# 
# --------------------------------------------------------

ad_proc -public im_navbar_write_tree {
    {-user_id 0 }
    {-label "main" }
    {-maxlevel 1}
} {
    Starts writing out the menu tree from a particular location
} {
    if {0 == $user_id} { set user_id [ad_get_user_id] }
    return [util_memoize [list im_navbar_write_tree_helper -user_id $user_id -label $label -maxlevel $maxlevel] 3600]
}

ad_proc -public im_navbar_write_tree_helper {
    -user_id:required
    {-label "main" }
    {-maxlevel 1}
} {
    Starts writing out the menu tree from a particular location
} {
    set main_label $label
    set main_menu_id [db_string main_menu "select menu_id from im_menus where label=:label" -default 0]
    set menu_sql "
	select	m.menu_id,
		m.label,
		m.name,
		m.url,
		(select count(*) from im_menus where parent_menu_id = m.menu_id) as sub_count
	from	im_menus m
	where	m.parent_menu_id = :main_menu_id and
		im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
	order by sort_order
    "

    # Execute SQL first and then iterate through the list, in oder to
    # avoid nested SQLs when diving down through multiple recursions
    set html ""
    set menus [db_list_of_lists menus $menu_sql]
    foreach menu_item $menus {

	set menu_id [lindex $menu_item 0]
	set label [lindex $menu_item 1]
	set name [lindex $menu_item 2]
	set url [lindex $menu_item 3]
	set sub_count [lindex $menu_item 4]

	append html "<li><a href=$url>$name</a>\n"
	if {$maxlevel > 0 && $sub_count > 0} {
	    append html "<ul>\n"
	    append html [im_navbar_write_tree -label $label -maxlevel [expr $maxlevel-1]]
	    append html "</ul>\n"
	}
    }
    return $html
}


ad_proc -public im_navbar_sub_tree { 
    {-label "main" }
} {
    Creates an <ul> ...</ul> hierarchical list for
    the admin section
} {
    set user_id [ad_get_user_id]
    set menu_id [db_string main_menu "select menu_id from im_menus where label=:label" -default 0]
    set menu_list_list [util_memoize "im_sub_navbar_menu_helper $user_id $menu_id" 60]

    set navbar ""
    foreach menu_list $menu_list_list {

	set menu_id [lindex $menu_list 0]
	set package_name [lindex $menu_list 1]
	set label [lindex $menu_list 2]
	set name [lindex $menu_list 3]
	set url [lindex $menu_list 4]
	set visible_tcl [lindex $menu_list 5]

	set name_key "intranet-core.[lang::util::suggest_key $name]"
	set name [lang::message::lookup "" $name_key $name]

	append navbar "<li><a href=\"$url\">$name</a><ul></ul>"

    }

    return $navbar
}
