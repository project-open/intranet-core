# /packages/intranet-core/www/projects/index.tcl
#
# Copyright (C) 1998-2004 various parties
# The software is based on ArsDigita ACS 3.4
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

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all projects with dimensional sliders.

    @param order_by project display order 
    @param include_subprojects_p whether to include sub projects
    @param mine_p:
	"t": Show only mine
	"f": Show all projects
	"dept": Show projects of my department(s)

    @param status_id criteria for project status
    @param project_type_id criteria for project_type_id
    @param letter criteria for im_first_letter_default_to_a(project_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    { order_by:allhtml "Project nr" }
    { include_subprojects_p "" }
    { include_subproject_level "" }
    { mine_p "f" }
    { project_status_id:integer 0 } 
    { project_type_id:integer 0 } 
    { exclude_project_type_id:integer 0 } 
    { user_id_from_search 0}
    { company_id:integer 0 } 
    { letter:trim "" }
    { start_date "" }
    { end_date "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "project_list" }
    { filter_advanced_p:integer 0 }
    { plugin_id:integer 0 }
}


# ---------------------------------------------------------------
# Project List Page
#
# This is a "classical" List-Page. It consists of the sections:
#    1. Page Contract: 
#	Receive the filter values defined as parameters to this page.
#    2. Defaults & Security:
#	Initialize variables, set default values for filters 
#	(categories) and limit filter values for unprivileged users
#    3. Define Table Columns:
#	Define the table columns that the user can see.
#	Again, restrictions may apply for unprivileged users,
#	for example hiding company names to freelancers.
#    4. Define Filter Categories:
#	Extract from the database the filter categories that
#	are available for a specific user.
#	For example "potential", "invoiced" and "partially paid" 
#	projects are not available for unprivileged users.
#    5. Generate SQL Query
#	Compose the SQL query based on filter criteria.
#	All possible columns are selected from the DB, leaving
#	the selection of the visible columns to the table columns,
#	defined in section 3.
#    6. Format Filter
#    7. Format the List Table Header
#    8. Format Result Data
#    9. Format Table Continuation
#   10. Join Everything Together

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters

set show_context_help_p 0

set user_id [auth::require_login]
set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set subproject_types [list "t" "Yes" "f" "No"]
set page_title "[_ intranet-core.Projects]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set upper_letter [string toupper $letter]
set return_url [im_url_with_query]

set org_start_date $start_date
set org_end_date $end_date
set org_project_status_id $project_status_id
set org_project_type_id $project_type_id

# Create an action select at the bottom if the "view" has been designed for it...
set show_bulk_actions_p [string equal "project_timeline" $view_name]

# Determine the default status if not set
if { 0 == $project_status_id } {
    # Default status is open
    set project_status_id [im_project_status_open]
}

set show_filter_with_member_p [im_parameter -package_id [im_package_core_id] ProjectListPageShowFilterWithMemberP "" 1]
set left_menu_p [parameter::get_from_package_key -package_key "intranet-core" -parameter ShowLeftFunctionalMenupP -default 0]

if {"" == $include_subproject_level} { set include_subproject_level [im_parameter -package_id [im_package_core_id] ProjectListPageDefaultSubprojectLevel "" ""] }
if {"" == $include_subprojects_p} { set include_subprojects_p [im_parameter -package_id [im_package_core_id] ProjectListPageDefaultSubprojectsP "" "f"] }
if {![im_permission $current_user_id "view_projects_all"]} {
    # Unprivileged users (clients & freelancers) can't see subprojects.
    set include_subprojects_p "f"
    set include_subproject_level ""
}

# Restrict status to "Open" projects for unprivileged users
if {![im_permission $current_user_id "view_projects_history"]} {
    set project_status_id [im_project_status_open]
}

if { $how_many eq "" || $how_many < 1 } {
    set how_many [im_parameter -package_id [im_package_core_id] NumberResultsPerPage  "" 50]
}
set end_idx [expr {$start_idx + $how_many}]


# Set the "menu_select_label" for the project navbar:
set menu_select_label "projects_filter_advanced"
if {"project_costs" == $view_name} { set menu_select_label "projects_profit_loss" }
# Check if a menu exists with the same name as the view_name. That way we can highlight custom views in the menu.
set view_menu_id [db_string check_view_menu "select menu_id from im_menus where lower(label) = lower(:view_name)" -default 0]
if {$view_menu_id} { set menu_select_label $view_name }


if {"" == $start_date} { set start_date [parameter::get_from_package_key -package_key "intranet-cost" -parameter DefaultStartDate -default "2000-01-01"] }
if {"" == $end_date} { set end_date [parameter::get_from_package_key -package_key "intranet-cost" -parameter DefaultEndDate -default "2100-01-01"] }


set min_all_l10n [lang::message::lookup "" intranet-core.Mine_All "Mine/All"]
set all_l10n [lang::message::lookup "" intranet-core.All "All"]

# Check that Start & End-Date have correct format
if { "" != $start_date } {
    if {[catch {
        if { $start_date != [clock format [clock scan $start_date] -format %Y-%m-%d] } {
            ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
            [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$start_date'<br>"
        }
    } err_msg]} {
        ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$start_date'<br>
        [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
    }
}

if { "" != $end_date } {
    if {[catch {
        if { $end_date != [clock format [clock scan $end_date] -format %Y-%m-%d] } {
            ad_return_complaint 1 "<strong>[_ intranet-core.End_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
            [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$end_date'<br>"
        }
    } err_msg]} {
        ad_return_complaint 1 "<strong>[_ intranet-core.End_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$end_date'<br>
        [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
    }
}


# ---------------------------------------------------------------
# 3. Defined Table Fields
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#

switch $view_name {
    "component" { set view_id 0 }
    default {

	set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
	if {!$view_id } {
	    ad_return_complaint 1 "<b>Unknown View Name</b>:<br>
    The view '$view_name' is not defined. <br>
    Maybe you need to upgrade the database. <br>
    Please notify your system administrator."
    return
	}
	
    }
}


set column_headers [list]
set column_vars [list]
set column_headers_admin [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]
set view_order_by_clause ""

set column_sql "
	select	vc.*
	from	im_view_columns vc
	where	view_id=:view_id
		and group_id is null
	order by sort_order
"
db_foreach column_list_sql $column_sql {

    set admin_html ""
    if {$admin_p} { 
	set url [export_vars -base "/intranet/admin/views/new-column" {column_id return_url}]
	set admin_html "<a href='$url'>[im_gif wrench ""]</a>" 
    }

    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
	lappend column_headers_admin $admin_html
	if {"" != $extra_select} { lappend extra_selects [eval "set a \"$extra_select\""] }
	if {"" != $extra_from} { lappend extra_froms [eval "set a \"$extra_from\""] }
	if {"" != $extra_where} { lappend extra_wheres [eval "set a \"$extra_where\""] }
	if {"" != $order_by_clause &&
	    $order_by==$column_name} {
	    set view_order_by_clause $order_by_clause
	}
    }
}

# ad_return_complaint 1 $view_order_by_clause

# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set form_id "project_filter"
set object_type "im_project"
set action_url "/intranet/projects/index"
set form_mode "edit"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name include_subprojects_p include_subproject_level letter filter_advanced_p}\
    -form {}

if {[im_permission $current_user_id "view_projects_all"]} { 
    set mine_p_options [list \
			    [list $all_l10n "f" ] \
			    [list [lang::message::lookup "" intranet-core.With_members_of_my_dept "With member of my department"] "dept"] \
			    [list [lang::message::lookup "" intranet-core.Mine "Mine"] "t"] \
			   ]
    ad_form -extend -name $form_id -form {
        {mine_p:text(select),optional {label "$min_all_l10n"} {options $mine_p_options }}
    } 

    template::element::set_value $form_id mine_p $mine_p
}

if { [im_permission $current_user_id "view_projects_history"] || [im_permission $current_user_id "view_projects_all"] } {
    ad_form -extend -name $form_id -form {
        {project_status_id:text(im_category_tree),optional {label #intranet-core.Project_Status#} {value $project_status_id} {custom {category_type "Intranet Project Status" translate_p 1 include_empty_name $all_l10n}} }
    } 
}

if { $company_id eq "" } {
    set company_id 0
}

# Company Options - only select companies that are customers for projects
# in order to deal with performance isues
# set company_options [im_company_options -include_empty_p 1 -include_empty_name $all_l10n -status "CustOrIntl"]

# Permission SQL: Normal users can see only "their" companies
set company_perm_sql "
		(       select	c.*
			from	im_companies c,
				acs_rels r
			where	c.company_id = r.object_id_one
				and r.object_id_two = $current_user_id
		)
"
if {[im_permission $user_id "view_companies_all"]} { set company_perm_sql "im_companies" }
set company_sql "
		select	c.company_name,
			c.company_id
		from	$company_perm_sql c
		where	c.company_id in (select distinct company_id from im_projects)
		order by lower(trim(c.company_name))
"

set company_options [util_memoize [list db_list_of_lists company_options $company_sql] 60]
set company_options [linsert $company_options 0 [list $all_l10n ""]]


# Get the list of profiles readable for current_user_id
set managable_profiles [im_profile::profile_options_managable_for_user -privilege "read" $current_user_id]
# Extract only the profile_ids from the managable profiles
set user_select_groups {}
foreach g $managable_profiles {
    lappend user_select_groups [lindex $g 1]
}

ad_form -extend -name $form_id -form {
    {project_type_id:text(im_category_tree),optional {label #intranet-core.Project_Type#} {value $project_type_id} {custom {category_type "Intranet Project Type" translate_p 1 include_empty_name $all_l10n} } }
}

# The "company_id" field can become very slow if there are
# many customers in the system.
if {!$filter_advanced_p} {
    ad_form -extend -name $form_id -form {
	{company_id:text(select),optional {label #intranet-core.Customer#} {options $company_options}}
    }
}


# Does user have VIEW permissions on company's employees?  
set employee_group_id [im_employee_group_id]
if { "t" == [db_string get_view_perm "select im_object_permission_p(:employee_group_id, :user_id, 'read') from dual"]} {
    if {$show_filter_with_member_p} {

	set user_options [im_profile::user_options -profile_ids $user_select_groups]
	set user_options [linsert $user_options 0 [list $all_l10n ""]]

	ad_form -extend -name $form_id -form {
	    {user_id_from_search:text(select),optional {label #intranet-core.With_Member#} {options $user_options}}
	}
    }
}

ad_form -extend -name $form_id -form {
    {start_date:text(text) {label "[_ intranet-timesheet2.Start_Date]"} {value "$start_date"} {html {size 10}} {after_html {<input type="button" id=start_date_calendar style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" >}}}
    {end_date:text(text) {label "[_ intranet-timesheet2.End_Date]"} {value "$end_date"} {html {size 10}} {after_html {<input type="button" id=end_date_calendar style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');">}}}
}

set filter_admin_html ""
if {$filter_advanced_p} {
    im_dynfield::append_attributes_to_form \
        -object_type $object_type \
        -form_id $form_id \
        -object_id 0 \
        -advanced_filter_p 1 \
	-include_also_hard_coded_p 1 \
	-page_url "/intranet/projects/index"

    # Set the form values from the HTTP form variable frame
    im_dynfield::set_form_values_from_http -form_id $form_id
    im_dynfield::set_local_form_vars_from_http -form_id $form_id

    array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
				   -form_id $form_id \
				   -object_type $object_type
			      ]
    # Show an admin wrench for setting up the filter design
    if {$admin_p} {
	set filter_admin_url [export_vars -base "/intranet-dynfield/layout-position" {{object_type im_project} {page_url "/intranet/projects/index"}}]
	set filter_admin_html "<a href='$filter_admin_url'>[im_gif wrench]</a>"
    }
}

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
switch $mine_p {
    "f" {
	# The user wants to see all projects.
	# The "perm_sql" already handles permissions, so we don't have to do anything here.
    }
    "dept" {
	# The user want to see only the projects in his or her department
	set user_cc_code [db_string cc "select im_cost_center_code_from_id((select department_id from im_employees where employee_id = :current_user_id))" -default ""]
	if {"" eq $user_cc_code} {
	     set user_name [acs_object_name $current_user_id]
	     ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-core.Error "Error"]</b>:<br>[lang::message::lookup "" intranet-core.User_has_no_cc "User '%user_name%' has no department assigned, <br>so we can't show the projects in the user's department."]"
	}


	lappend criteria "(
	p.project_cost_center_id in (
		select	cc.cost_center_id
		from	im_cost_centers cc
		where	substring(cc.cost_center_code for (length(:user_cc_code))) = :user_cc_code
	) 
	OR
	p.project_lead_id in (
		select	pe.person_id
		from	im_cost_centers cc,
			im_employees e,
			persons pe
		where	substring(cc.cost_center_code for (length(:user_cc_code))) = :user_cc_code and
			e.department_id = cc.cost_center_id and
			e.employee_id = pe.person_id
	)
	)"

    }
    default {
        # This should cover the case: mine_p="t"
	# The user explicitly want to see his or her projects only
	lappend criteria "p.project_id in (
	select	p.project_id
	from	im_projects p,
		acs_rels r
	where	r.object_id_one = p.project_id and 
		r.object_id_two = :user_id
	)"
    }
}


if { $project_status_id ne "" && $project_status_id > 0 } {
    lappend criteria "p.project_status_id in ([join [im_sub_categories -include_disabled_p 1 $project_status_id] ","])"
}
if { $project_type_id ne "" && $project_type_id != 0 } {
    lappend criteria "p.project_type_id in ([join [im_sub_categories -include_disabled_p 1 $project_type_id] ","])"
}
if { $exclude_project_type_id ne "" && $exclude_project_type_id != 0 } {
    lappend criteria "p.project_type_id not in ([join [im_sub_categories -include_disabled_p 1 $exclude_project_type_id] ","])"
}
if {0 != $user_id_from_search && "" != $user_id_from_search} {
    lappend criteria "p.project_id in (select object_id_one from acs_rels where object_id_two = :user_id_from_search)"
}
if { $company_id ne "" && $company_id != 0 } {
    lappend criteria "p.company_id=:company_id"
}
if {"" != $start_date} {
    lappend criteria "p.end_date >= :start_date::timestamptz"
}
if {"" != $end_date} {
    lappend criteria "p.start_date < :end_date::timestamptz"
}
if { $upper_letter ne "" && $upper_letter ne "ALL"  && $upper_letter ne "SCROLL"  } {
    lappend criteria "im_first_letter_default_to_a(p.project_name)=:upper_letter"
}
if { $include_subprojects_p == "f" } {
    lappend criteria "p.parent_id is null"
}
if { $include_subproject_level ne "" } {
    lappend criteria "tree_level(p.tree_sortkey) <= $include_subproject_level"
}



set order_by_clause "order by lower(project_nr) DESC"
switch [string tolower $order_by] {
    "ok" { set order_by_clause "order by on_track_status_id DESC" }
    "spend days" { set order_by_clause "order by spend_days" }
    "estim. days" { set order_by_clause "order by estim_days" }
    "start date" { set order_by_clause "order by start_date DESC" }
    "delivery date" { set order_by_clause "order by end_date" }
    "create" { set order_by_clause "order by create_date" }
    "quote" { set order_by_clause "order by quote_date" }
    "open" { set order_by_clause "order by open_date" }
    "deliver" { set order_by_clause "order by deliver_date" }
    "close" { set order_by_clause "order by close_date" }
    "type" { set order_by_clause "order by project_type" }
    "status" { set order_by_clause "order by project_status_id" }
    "client" { set order_by_clause "order by lower(company_name)" }
    "words" { set order_by_clause "order by task_words" }
    "project nr" { set order_by_clause "order by project_nr desc" }
    "project manager" { set order_by_clause "order by lower(lead_name)" }
    "url" { set order_by_clause "order by upper(url)" }
    "project name" { set order_by_clause "order by lower(project_name)" }
    "budget" { set order_by_clause "order by coalesce(project_budget,0) DESC" }
    "per" { 
	set order_by_clause "order by per_order desc" 
	lappend extra_selects "(case when p.percent_completed is null then 0 else p.percent_completed end) as per_order"
    }
    default {
	if {$view_order_by_clause ne ""} {
	    set order_by_clause "order by $view_order_by_clause"
	}
    }
}

set where_clause [join $criteria " and\n            "]
if { $where_clause ne "" } { set where_clause " and $where_clause" }
set extra_select [join $extra_selects ",\n\t"]
if { $extra_select ne "" } { set extra_select ",\n\t$extra_select" }
set extra_from [join $extra_froms ",\n\t"]
if { $extra_from ne "" } { set extra_from ",\n\t$extra_from" }
set extra_where [join $extra_wheres "and\n\t"]
if { $extra_where ne "" } { set extra_where " and\n\t$extra_where" }


# Create a ns_set with all local variables in order
# to pass it to the SQL query
set form_vars [ns_set create]
foreach varname [info locals] {

    # Don't consider variables that start with a "_", that
    # contain a ":" or that are array variables:
    if {"_" == [string range $varname 0 0]} { continue }
    if {[regexp {:} $varname]} { continue }
    if {[array exists $varname]} { continue }

    # Get the value of the variable and add to the form_vars set
    set value [expr "\$$varname"]
    ns_set put $form_vars $varname $value
}


# Deal with DynField Vars and add constraint to SQL
#


if {$filter_advanced_p} {
    
    set dynfield_extra_where $extra_sql_array(where)
    set ns_set_vars $extra_sql_array(bind_vars)
    set tmp_vars [util_list_to_ns_set $ns_set_vars]
    set tmp_var_size [ns_set size $tmp_vars]
    for {set i 0} {$i < $tmp_var_size} { incr i } {
	set key [ns_set key $tmp_vars $i]
	set value [ns_set get $tmp_vars $key]
	ns_set put $form_vars $key $value
    }

    # Add the additional condition to the "where_clause"
    if {"" != $dynfield_extra_where} {
	append where_clause "
	    and project_id in $dynfield_extra_where
        "
    }
}




set create_date ""
set open_date ""
set quote_date ""
set deliver_date ""
set invoice_date ""
set close_date ""


set status_from "
	(select project_id, min(audit_date) as when from im_projects_status_audit
	group by project_id) s_create,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=[im_project_status_quoting] group by project_id) s_quote,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=[im_project_status_open] group by project_id) s_open,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=[im_project_status_delivered] group by project_id) s_deliver,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id=[im_project_status_invoiced] group by project_id) s_invoice,
	(select min(audit_date) as when, project_id from im_projects_status_audit
	where project_status_id in (
		[im_project_status_closed],[im_project_status_canceled],[im_project_status_declined]
	) group by project_id) s_close,
"

set status_select "
	s_create.when as create_date,
	s_open.when as open_date,
	s_quote.when as quote_date,
	s_deliver.when as deliver_date,
	s_invoice.when as invoice_date,
	s_close.when as close_date,
"

set status_where "
	and p.project_id=s_create.project_id(+)
	and p.project_id=s_quote.project_id(+)
	and p.project_id=s_open.project_id(+)
	and p.project_id=s_deliver.project_id(+)
	and p.project_id=s_invoice.project_id(+)
	and p.project_id=s_close.project_id(+)
"


# Permissions and Performance:
# This SQL shows project depending on the permissions
# of the current user: 
#
#	IF the user is a project member
#	OR if the user has the privilege to see all projects.
#
# The performance problems are due to the number of projects
# (several thousands), the number of users (several thousands)
# and the acs_rels relationship between users and projects.
# Despite all of these, the page should ideally appear in less
# then one second, because it is frequently used.
# 
# In order to get acceptable load times we use an inner "perm"
# SQL that selects project_ids "outer-joined" with the membership 
# information for the current user.
# This information is then filtered in the outer SQL, using an
# OR statement, acting as a filter on the returned project_ids.
# It is important to apply this OR statement outside of the
# main join (projects and membership relation) in order to
# reach a reasonable response time.


# The user does NOT have the view_projects_all privilege.
# Only show member projects or projects in his dept.

set dept_perm_sql ""
if {[im_permission $current_user_id "view_projects_dept"] && [im_table_exists im_cost_centers]} {
   set dept_perm_sql "
	UNION
	-- projects of the user department
	select	p.*
	from	im_projects p
	where	p.project_cost_center_id in (select * from im_user_cost_centers(:user_id))
		$where_clause
   "
}

set perm_sql "
	(
	-- member projects
	select	p.*
	from	im_projects p,
		acs_rels r
	where	r.object_id_one = p.project_id
		and r.object_id_two in (select :user_id from dual UNION select group_id from group_element_index where element_id = :user_id)
		$where_clause
	$dept_perm_sql
	)
"

# User can see all projects - no permissions
if {[im_permission $user_id "view_projects_all"]} {
   set perm_sql "im_projects"
}

set sql "
SELECT *
FROM
        ( SELECT
                p.*,
		round(p.percent_completed * 10.0) / 10.0 as percent_completed,
                c.company_name,
                im_name_from_user_id(project_lead_id) as lead_name,
                im_category_from_id(p.project_type_id) as project_type,
                im_category_from_id(p.project_status_id) as project_status,
                to_char(p.start_date, 'YYYY-MM-DD') as start_date_formatted,
                to_char(p.end_date, 'YYYY-MM-DD') as end_date_formatted,
                to_char(p.end_date, 'HH24:MI') as end_date_time
		$extra_select
        FROM
                $perm_sql p,
                im_companies c
		$extra_from
        WHERE
                p.company_id = c.company_id
		and p.project_type_id not in ([im_project_type_task], [im_project_type_ticket])
                $where_clause
		$extra_where
        ) projects
$order_by_clause
"


# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

# Limit the search results to N data sets only
# to be able to manage large sites
#
if {$upper_letter eq "ALL"} {
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1
    set selection $sql
} else {
    # We can't get around counting in advance if we want to be able to
    # sort inside the table on the page for only those users in the
    # query results
    set total_in_limited [db_string total_in_limited "
        select count(*)
        from ($sql) s
    "]

    # Special case: FIRST the users selected the 2nd page of the results
    # and THEN added a filter. Let's reset the results for this case:
    while {$start_idx > 0 && $total_in_limited < $start_idx} {
	set start_idx [expr {$start_idx - $how_many}]
	set end_idx [expr {$end_idx - $how_many}]
    }

    set selection [im_select_row_range $sql $start_idx $end_idx]
}	

# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options
set mine_p_options [list \
	[list $all_l10n "f" ] \
	[list [lang::message::lookup "" intranet-core.With_members_of_my_dept "With member of my department"] "dept"] \
	[list [lang::message::lookup "" intranet-core.Mine "Mine"] "t"] \
]

set letter $upper_letter

# ----------------------------------------------------------
# Do we have to show administration links?

set skip_labels {projects_admin 1 projects_open 1 projects_closed 1 projects_potential 1}
set menu_id [db_string company_menu "select menu_id from im_menus where label = 'projects'" -default 0]
set action_html [im_navbar_main_submenu_recursive -no_outer_ul_p 1 -locale locale -user_id $current_user_id -menu_id $menu_id -skip_labels $skip_labels]
if {"" ne $action_html} {
    set action_html "
      <div class='filter-block'>
         <div class='filter-title'>[lang::message::lookup "" intranet-core.Projects_Actions "Projects Actions"]</div>
         <ul>
         $action_html
         </ul>
      </div>
    "
}


set admin_html ""
set links [im_menu_projects_admin_links]
foreach link_entry $links {
    set html ""
    for {set i 0} {$i < [llength $link_entry]} {incr i 2} {
	set name [lindex $link_entry $i]
	set url [lindex $link_entry $i+1]
	append html "<a href='$url'>$name</a>"
    }
    append admin_html "<li>$html</li>\n"
}
if {"" ne $admin_html} {
    set admin_html "
      	<div class='filter-block'>
        <div class='filter-title'>[_ intranet-core.Admin_Projects]</div>
        <ul>$admin_html</ul>
      	</div>"
}

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr {[llength $column_headers] + 1}]
set table_header_html ""

# Format the header names with links that modify the
# sort order of the SQL query.
#
set url "index?"
set query_string [export_ns_set_vars url [list order_by]]
if { $query_string ne "" } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
set ctr 0
foreach col $column_headers {

    set wrench_html [lindex $column_headers_admin $ctr]
    regsub -all " " $col "_" col_txt
    set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
    if {$ctr == 0 && $show_bulk_actions_p} {
	append table_header_html "<td class=rowtitle>$col_txt$wrench_html</td>\n"
    } else {
	#set col [lang::util::suggest_key $col]
	append table_header_html "<td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col_txt</a>$wrench_html</td>\n"
    }
    incr ctr
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# 8. Format the Result Data
# ---------------------------------------------------------------

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx

db_1row timeline "
	select	 max(end_date) as timeline_end_date,
		 min(start_date) as timeline_start_date
	from	 ($sql) t
"

db_foreach projects_info_query $selection -bind $form_vars {

#    if {"" == $project_id} { continue }

    set project_type [im_category_from_id $project_type_id]
    set project_status [im_category_from_id $project_status_id]

    # Multi-Select
    set select_project_checkbox "<input type=checkbox name=select_project_id value=$project_id id=select_project_id,$project_id>"

    set timeline_html [im_project_gantt_main_project \
			   -timeline_start_date $timeline_start_date \
			   -timeline_end_date $timeline_end_date \
			   -timeline_width 400 \
			   -project_id $project_id \
			   -start_date $start_date \
			   -end_date $end_date \
			   -percent_completed $percent_completed \
    ]

    # Gif for collapsable tree?
    set gif_html ""

    set url [im_maybe_prepend_http $url]
    if { $url eq "" } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }

    # Append together a line of data based on the "column_vars" parameter list
    set row_html "<tr$bgcolor([expr {$ctr % 2}])>\n"
    foreach column_var $column_vars {
	append row_html "\t<td valign=top>"
	set cmd "append row_html $column_var"
	if {[catch {
	    eval "$cmd"
	} errmsg]} {
            # TODO: warn user
	    append row_html "<font color=red><pre>$errmsg</pre></font>"
	}
	append row_html "</td>\n"
    }
    append row_html "</tr>\n"
    append table_body_html $row_html

    incr ctr
    if { $how_many > 0 && $ctr > $how_many } {
	break
    }
    incr idx
}

# Show a reasonable message when there are no result rows:
if { $table_body_html eq "" } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
	[lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
        </b></ul></td></tr>"
}

if { $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr {$end_idx + 0}]
    set next_page_url "index?start_idx=$next_start_idx&amp;[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr {$start_idx - $how_many}]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "index?start_idx=$previous_start_idx&amp;[export_ns_set_vars url [list start_idx]]"
} else {
    set previous_page_url ""
}

# ---------------------------------------------------------------
# 9. Format Table Continuation
# ---------------------------------------------------------------

# Check if there are rows that we decided not to return
# => include a link to go to the next page
#
if {$total_in_limited > 0 && $end_idx < $total_in_limited} {
    set next_start_idx [expr {$end_idx + 0}]
    set next_page "<a href=index?start_idx=$next_start_idx&amp;[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

# Check if this is the continuation of a table (we didn't start with the
# first row - there is at least 1 previous row.
# => add a previous page link
#
if { $start_idx > 0 } {
    set previous_start_idx [expr {$start_idx - $how_many}]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page "<a href=index?start_idx=$previous_start_idx&amp;[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
<tr>
  <td align=center colspan=$colspan>
    [im_maybe_insert_link $previous_page $next_page]
  </td>
</tr>"

if {$show_bulk_actions_p} {
    set table_continuation_html "
	<tr>
	<td colspan=99>[im_project_action_select]</td>
	</tr>
$table_continuation_html
    "
}


# ---------------------------------------------------------------
# Dashboard column
# ---------------------------------------------------------------

set dashboard_column_html [string trim [im_component_bay "right"]]
if {"" == $dashboard_column_html} {
    set dashboard_column_width "0"
} else {
    set dashboard_column_width "250"
}


# ---------------------------------------------------------------
# Navbars
# ---------------------------------------------------------------

# Get the URL variables for pass-though
set query_pieces [split [ns_conn query] "&"]
set pass_through_vars [list]
foreach query_piece $query_pieces {
    if {[regexp {^([^=]+)=(.+)$} $query_piece match var val]} {
	# exclude "form:...", "__varname" and "letter" variables
	if {[regexp {^form} $var match]} {continue}
	if {[regexp {^__} $var match]} {continue}
	if {[regexp {^letter$} $var match]} {continue}
	set var [ns_urldecode $var]
	lappend pass_through_vars $var
    }
}


set start_date $org_start_date
set end_date $org_end_date
set project_status_id $org_project_status_id
set project_type_id $org_project_type_id
# !!! ad_return_complaint 1 "pass=$pass_through_vars, start_date=$start_date, end_date=$end_date"

# Project Navbar goes to the top
#
set letter $upper_letter
set project_navbar_html [\
			     im_project_navbar \
			     -current_plugin_id $plugin_id \
			     $letter \
			     "/intranet/projects/index" \
			     $next_page_url \
			     $previous_page_url \
			     $pass_through_vars \
			     $menu_select_label \
			    ]

# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate id="project_filter" style="tiny-plain-po"></formtemplate>}]
set filter_html $__adp_output


# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	           [_ intranet-core.Filter_Projects] $filter_admin_html
        	</div>
            	$filter_html
      	</div>
"


#ad_return_complaint 1 "$action_html - $admin_html - $left_menu_p"
if {"" ne $action_html || "" ne $admin_html || $left_menu_p} {append left_navbar_html "<hr/>" }

append left_navbar_html "
	$action_html
	$admin_html
"


# Show "Portfolio" menu highlighted when showing the list of portfolios...
set main_navbar_label "projects"
if {"project_portfolio_list" eq $view_name} {
    set main_navbar_label "portfolio"
}

