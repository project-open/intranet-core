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
    { order_by "Project nr" }
    { include_subprojects_p "f" }
    { mine_p "f" }
    { project_status_id 0 } 
    { project_type_id:integer 0 } 
    { user_id_from_search 0}
    { company_id:integer 0 } 
    { letter:trim "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "project_list" }
    { filter_advanced_p:integer 0 }
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

set user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set subproject_types [list "t" "Yes" "f" "No"]
set page_title "[_ intranet-core.Projects]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set letter [string toupper $letter]

# Determine the default status if not set
if { 0 == $project_status_id } {
    # Default status is open
    set project_status_id [im_project_status_open]
}

# Unprivileged users (clients & freelancers) can only see their 
# own projects and no subprojects.
if {![im_permission $current_user_id "view_projects_all"]} {
    set mine_p "t"
    set include_subprojects_p "f"
    
    # Restrict status to "Open" projects only
    set project_status_id [im_project_status_open]
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage  "" 50]
}
set end_idx [expr $start_idx + $how_many]



# Set the "menu_select_label" for the project navbar:
# projects_open, projects_closed and projects_potential
# depending on type_id and status_id:
#
set menu_select_label ""
switch $project_status_id {
    71 { set menu_select_label "projects_potential" }
    76 { set menu_select_label "projects_open" }
    81 { set menu_select_label "projects_closed" }
    default { set menu_select_label "" }
}


# ---------------------------------------------------------------
# 3. Defined Table Fields
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id } {
    ad_return_complaint 1 "<b>Unknown View Name</b>:<br>
    The view '$view_name' is not defined. <br>
    Maybe you need to upgrade the database. <br>
    Please notify your system administrator."
    return
}

set column_headers [list]
set column_vars [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]

set column_sql "
select
	vc.*
from
	im_view_columns vc
where
	view_id=:view_id
	and group_id is null
order by
	sort_order"

db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
    }
}

# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set dynamic_fields_p 1
set form_id "project_filter"
set object_type "im_project"
set action_url "/intranet/projects/index"
set form_mode "edit"
set mine_p_options [list \
	[list [lang::message::lookup "" intranet-core.All "All"] "f" ] \
	[list [lang::message::lookup "" intranet-core.With_members_of_my_dept "With member of my department"] "dept"] \
	[list [lang::message::lookup "" intranet-core.Mine "Mine"] "t"] \
]

set project_member_options [util_memoize "db_list_of_lists project_members {
        select  distinct
                im_name_from_user_id(object_id_two) as user_name,
                object_id_two as user_id
        from    acs_rels r,
                im_projects p
        where   r.object_id_one = p.project_id
        order by user_name
}" 86400]
set project_member_options [linsert $project_member_options 0 [list [_ intranet-core.All] ""]]


ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name include_subprojects_p letter filter_advanced_p}\
    -form {
    	{mine_p:text(select),optional {label "Mine/All"} {options $mine_p_options }}
    }
    
if {[im_permission $current_user_id "view_projects_all"]} {  
    ad_form -extend -name $form_id -form {
	{project_status_id:text(im_category_tree),optional {label #intranet-core.Project_Status#} {custom {category_type "Intranet Project Status" translate_p 1}} }
	{project_type_id:text(im_category_tree),optional {label #intranet-core.Project_Type#} {custom {category_type "Intranet Project Type" translate_p 1} } }
    }

    template::element::set_value $form_id project_status_id $project_status_id
    template::element::set_value $form_id project_type_id $project_type_id
}

if {$filter_advanced_p && [db_table_exists im_dynfield_attributes]} {

    im_dynfield::append_attributes_to_form \
        -object_type $object_type \
        -form_id $form_id \
        -object_id 0 \
	-advanced_filter_p 1

    # Set the form values from the HTTP form variable frame
    im_dynfield::set_form_values_from_http -form_id $form_id

    im_dynfield::set_local_form_vars_from_http -form_id $form_id

    array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
	-form_id $form_id \
	-object_type $object_type
    ]
}


# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $project_status_id] && $project_status_id > 0 } {
    lappend criteria "p.project_status_id in ([join [im_sub_categories $project_status_id] ","])"
}
if { ![empty_string_p $project_type_id] && $project_type_id != 0 } {
    lappend criteria "p.project_type_id in ([join [im_sub_categories $project_type_id] ","])"
}
if {0 != $user_id_from_search && "" != $user_id_from_search} {
    lappend criteria "p.project_id in (select object_id_one from acs_rels where object_id_two = :user_id_from_search)"
}
if { ![empty_string_p $company_id] && $company_id != 0 } {
    lappend criteria "p.company_id=:company_id"
}

if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(p.project_name)=:letter"
}
if { $include_subprojects_p == "f" } {
    lappend criteria "p.parent_id is null"
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
    "per" { 
	set order_by_clause "order by per_order desc" 
	lappend extra_selects "(case when p.percent_completed is null then 0 else p.percent_completed end) as per_order"

    }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set extra_select [join $extra_selects ",\n\t"]
if { ![empty_string_p $extra_select] } {
    set extra_select ",\n\t$extra_select"
}

set extra_from [join $extra_froms ",\n\t"]
if { ![empty_string_p $extra_from] } {
    set extra_from ",\n\t$extra_from"
}

set extra_where [join $extra_wheres "and\n\t"]
if { ![empty_string_p $extra_where] } {
    set extra_where ",\n\t$extra_where"
}




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
if {$filter_advanced_p && [db_table_exists im_dynfield_attributes]} {

    # Add the DynField variables to $form_vars
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


# No "permissions" - just select all projects
set perm_sql "im_projects"


if {[string equal $mine_p "dept"]} {

    # Select all project with atleast one member that
    # belongs to the department of the current user.
    set perm_sql "
	(select	p.*
	from	im_projects p,
		acs_rels r
	where	r.object_id_one = p.project_id
		and r.object_id_two in (
			
			select	employee_id
			from	im_employees
			where	department_id in (
				select	cc.cost_center_id
				from	im_cost_centers cc,
					(	select	cost_center_code
						from	im_cost_centers
						where	cost_center_id in (
							select	department_id
							from	im_employees
							where	employee_id = :user_id
						    UNION
							select	cost_center_id
							from	im_cost_centers
							where	manager_id = :user_id
						)
					) t
				where	position(t.cost_center_code in cc.cost_center_code) > 0
			)

		)
		$where_clause
	)
    "
}


if {![im_permission $user_id "view_projects_all"] | [string equal $mine_p "t"]} {
    set perm_sql "
	(select	p.*
	from	im_projects p,
		acs_rels r
	where	r.object_id_one = p.project_id
		and r.object_id_two = :user_id
		$where_clause
	)"
}


set sql "
SELECT *
FROM
        ( SELECT
                p.*,
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

ns_log Notice "/intranet/project/index: Before limiting clause"

if {[string equal $letter "ALL"]} {
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
    set selection [im_select_row_range $sql $start_idx $end_idx]
}	

# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options

ns_log Notice "/intranet/project/index: Before formatting filter"

set filter_html "
<form method=get action='/intranet/projects/index'>
[export_form_vars start_idx order_by how_many view_name include_subprojects_p letter]

<table border=0 cellpadding=0 cellspacing=1>
  <tr> 
    <td colspan='2' class=rowtitle align=center>
      [_ intranet-core.Filter_Projects]
    </td>
  </tr>
"

if {[im_permission $current_user_id "view_projects_all"]} { 
    append filter_html "
  <tr>
    <td class=form-label>[lang::message::lookup "" intranet-core.View_Projects "View Projects"]:</td>
    <td class=form-widget>[im_select -translate_p 0 -ad_form_option_list_style_p 1 mine_p $mine_p_options ""]</td>
  </tr>
    "
}

if {[im_permission $current_user_id "view_projects_all"]} {
    append filter_html "
  <tr>
    <td class=form-label>[_ intranet-core.Project_Status]:</td>
    <td class=form-widget>[im_category_select -include_empty_p 1 "Intranet Project Status" project_status_id $project_status_id]</td>
  </tr>
    "
}

append filter_html "
  <tr>
    <td class=form-label>[_ intranet-core.Project_Type]:</td>
    <td class=form-widget>
      [im_category_select -include_empty_p 1 "Intranet Project Type" project_type_id $project_type_id]
    </td>
  </tr>
"

append filter_html "
  <tr>
<td class=form-label valign=top>[lang::message::lookup "" intranet-core.Customer "Customer"]:</td>
<td class=form-widget valign=top>[im_company_select -include_empty_name "All" company_id $company_id "" "CustOrIntl"]</td>
  </tr>
"

append filter_html "
  <tr>
    <td class=form-label valign=top>[lang::message::lookup "" intranet-cust-baselkb.With_Member "With Member"]:</td>
    <td class=form-widget valign=top>[im_select -ad_form_option_list_style_p 1 -translate_p 0 user_id_from_search $project_member_options $user_id_from_search]</td>
  </tr>
"



append filter_html "
  <tr>
    <td class=form-label></td>
    <td class=form-widget>
	  <input type=submit value=Go name=submit>
    </td>
  </tr>
"

append filter_html "</table>\n</form>\n"

# ----------------------------------------------------------
# Do we have to show administration links?

ns_log Notice "/intranet/project/index: Before admin links"
set admin_html ""

if {[im_permission $current_user_id "add_projects"]} {
    append admin_html "<li><a href=\"/intranet/projects/new\">[_ intranet-core.Add_a_new_project]</a>\n"
    set new_from_template_p [ad_parameter -package_id [im_package_core_id] EnableNewFromTemplateLinkP "" 0]
    if {$new_from_template_p} {
        append admin_html "<li><a href=\"/intranet/projects/new-from-template\">[lang::message::lookup "" intranet-core.Add_a_new_project_from_Template "Add a new project from Template"]</a>\n"
    }

    set wf_oid_col_exists_p [util_memoize "db_column_exists wf_workflows object_type"]
    if {$wf_oid_col_exists_p} {
	set wf_sql "
		select	t.pretty_name as wf_name,
			w.*
		from	wf_workflows w,
			acs_object_types t
		where	w.workflow_key = t.object_type
			and w.object_type = 'im_project'
	"
	db_foreach wfs $wf_sql {
	    set new_from_wf_url [export_vars -base "/intranet/projects/new" {workflow_key}]
	    append admin_html "<li><a href=\"$new_from_wf_url\">[lang::message::lookup "" intranet-core.New_workflow "New %wf_name%"]</a>\n"
	}
    }
}

if {[im_permission $current_user_id "view_finance"]} {
    append admin_html "<li><a href=/intranet/projects/index?view_name=project_costs
    >[_ intranet-core.Profit_and_Loss]</a>\n"
}



set parent_menu_sql "select menu_id from im_menus where label= 'projects_admin'"
set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default 0]

set menu_select_sql "
        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
                and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
        order by sort_order"

# Start formatting the menu bar
set ctr 0
db_foreach menu_select $menu_select_sql {
    regsub -all " " $name "_" name_key
    append admin_html "<li><a href=\"$url\">[lang::message::lookup "" $package_name.$name_key $name]</a></li>\n"
}


append admin_html "<li><a href=\"/intranet/projects/index?filter_advanced_p=1\">[_ intranet-core.Advanced_Filtering]</a>"

set project_filter_html $filter_html

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
ns_log Notice "/intranet/project/index: Before format header"
set colspan [expr [llength $column_headers] + 1]

set table_header_html ""
#<tr>
#  <td align=center valign=top colspan=$colspan><font size=-1>
#    [im_groups_alpha_bar [im_project_group_id] $letter "start_idx"]</font>
#  </td>
#</tr>"

# Format the header names with links that modify the
# sort order of the SQL query.
#
set url "index?"
set query_string [export_ns_set_vars url [list order_by]]
if { ![empty_string_p $query_string] } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
foreach col $column_headers {
    regsub -all " " $col "_" col_txt
    set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>$col_txt</td>\n"
    } else {
	#set col [lang::util::suggest_key $col]
	append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col_txt</a></td>\n"
    }
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# 8. Format the Result Data
# ---------------------------------------------------------------

ns_log Notice "/intranet/project/index: Before db_foreach"

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx
db_foreach projects_info_query $selection -bind $form_vars {

#    if {"" == $project_id} { continue }

    set url [im_maybe_prepend_http $url]
    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }

    # Append together a line of data based on the "column_vars" parameter list
    set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append row_html "\t<td valign=top>"
	set cmd "append row_html $column_var"
	eval "$cmd"
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
if { [empty_string_p $table_body_html] } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
        There are currently no projects matching the selected criteria
        </b></ul></td></tr>"
}

if { $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 0]
    set next_page_url "index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set previous_page_url ""
}

# ---------------------------------------------------------------
# 9. Format Table Continuation
# ---------------------------------------------------------------

ns_log Notice "/intranet/project/index: before table continuation"
# Check if there are rows that we decided not to return
# => include a link to go to the next page
#
if {$total_in_limited > 0 && $end_idx < $total_in_limited} {
    set next_start_idx [expr $end_idx + 0]
    set next_page "<a href=index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

# Check if this is the continuation of a table (we didn't start with the
# first row - there is at least 1 previous row.
# => add a previous page link
#
if { $start_idx > 0 } {
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page "<a href=index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
<tr>
  <td align=center colspan=$colspan>
    [im_maybe_insert_link $previous_page $next_page]
  </td>
</tr>"


# ---------------------------------------------------------------
# Navbar
# ---------------------------------------------------------------

set project_navbar_html "
<br>
[im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter project_status_id] $menu_select_label]
"



ns_log Notice "/intranet/project/index: before release handes"
db_release_unused_handles

