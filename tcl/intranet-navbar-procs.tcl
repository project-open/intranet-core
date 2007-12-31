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
    Functions related to navigation bar

    @author Frank Bergmann (frank.bergmann@project-open.com)
}


# --------------------------------------------------------
# 
# --------------------------------------------------------

ad_proc -public im_navbar_tree { 
    {-label ""} 
} {
    Creates an <ul> ...</ul> hierarchical list with all major
    objects in the system.
} {
    set html "
      <hr/>
      <div class=filter-block>
	<ul class=mktree>
	<li><a href=/intranet/>Home</a></li>
	[im_menu_li bug_tracker]
	[im_menu_li forum]
	[im_menu_li user]
	<ul>
		<li><a href=/intranet/users/new>New User</a>
		[im_navbar_write_tree -label "user" -maxlevel 0]
	</ul>
	[im_menu_li projects]
	<ul>
		<li><a href=/intranet/projects/new>New Project</a>
		<li><a href=/intranet/projects/index?view_name=project_costs>Projects Profit &amp; Loss</a>
		<li><a href=/intranet/projects/index?filter_advanced_p=1>Projects Advanced Filtering</a>
		<li><a href=/gantt-resources-cube?config=resource_planning_report>Project Resource Planning</a>
		<li><a href=/intranet/projects/index?project_type_id=2500>Translation Projects</a>
		<li><a href=/intranet/projects/index?project_type_id=2501>Consulting Projects</a>
		<li>Projects by Status
		<ul>
		[im_navbar_write_tree -label "projects" -maxlevel 0]
		</ul>
	</ul>
	[im_menu_li workflow]
	[im_menu_li companies]
	<ul>
		<li><a href=/intranet/companies/new>New Company</a>
		<li><a href=/intranet/companies/index?type_id=57>Customers</a>
		<li><a href=/intranet/companies/index?type_id=56>Providers</a>
		<li><a href=/intranet/companies/index?type_id=53>Internal</a>
		<li>Companies by Status
		<ul>
		[im_navbar_write_tree -label "companies" -maxlevel 0]
		</ul>
	</ul>
	[im_menu_li timesheet2_timesheet]
	<ul>
		[im_menu_li timesheet2_absences]
	</ul>
	[im_menu_li timesheet2_absences]
	<ul>
		<li><a href=/intranet-timesheet2/absences/new>New Absence</a>
	</ul>
	[im_menu_li wiki]
	[im_menu_li finance]
	<ul>
	[im_navbar_write_tree -label "finance" -maxlevel 0]
	</ul>
	[im_menu_li freelance_rfqs]
	[im_menu_li reporting]
	<ul>
		[im_navbar_write_tree -label "reporting" -maxlevel 1]
	</ul>
	[im_menu_li dashboard]
	[im_menu_li admin]
		<ul>
		[im_navbar_write_tree -label "admin" -maxlevel 0]
		</ul>
	[im_menu_li openacs]
		<ul>
		[im_navbar_write_tree -label "openacs" -maxlevel 0]
		</ul>
	</ul>
      </div>
    "
}

# --------------------------------------------------------
# 
# --------------------------------------------------------

ad_proc -public im_navbar_tree_automatic { 
    {-label ""} 
} {
    Creates an <ul> ...</ul> hierarchical list with all major
    objects in the system.
} {
    set main_menu_id [db_string main_menu "select menu_id from im_menus where label=:label" -default 0]
    set menu_sql "
	select	m.*
	from	im_menus m
	where	m.parent_menu_id = :main_menu_id
	order by sort_order
    "
    set html ""
    db_foreach menus $menu_sql {
	append html "<li><a href=$url>$name</a>\n"
	append html "<ul>\n"
	append html [im_navbar_write_tree -label $label]
	append html "</ul>\n"
    }

    return "
	<ul class=\"mktree\">
	$html
	</ul>
    "
}


ad_proc -public im_navbar_write_tree {
    {-label "main" }
    {-maxlevel 1}
} {
    Starts writing out the menu tree from a particular location
} {
    set main_menu_id [db_string main_menu "select menu_id from im_menus where label=:label" -default 0]
    set menu_sql "
        select  m.*
        from    im_menus m
        where   m.parent_menu_id = :main_menu_id
        order by sort_order
    "
    set html ""
    db_foreach menus $menu_sql {
        append html "<li><a href=$url>$name</a>\n"
	if {$maxlevel > 0} {
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
