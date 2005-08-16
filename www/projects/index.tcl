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
    @param mine_p show my projects or all projects
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
    { project_type_id:integer "0" } 
    { user_id_from_search "0"}
    { company_id:integer "0" } 
    { letter:trim "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "project_list" }
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
set view_types [list "t" "Mine" "f" "All"]
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

set column_sql "
select
	column_name,
	column_render_tcl,
	visible_for
from
	im_view_columns
where
	view_id=:view_id
	and group_id is null
order by
	sort_order"

db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
    }
}

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $project_status_id] && $project_status_id > 0 } {
    lappend criteria "p.project_status_id in (
	select :project_status_id from dual
	UNION
	select child_id
	from im_category_hierarchy
	where parent_id = :project_status_id
    )"
}

if { ![empty_string_p $project_type_id] && $project_type_id != 0 } {
    # Select the specified project type and its subtypes
    lappend criteria "p.project_type_id in (
	select :project_type_id from dual
	UNION
	select child_id 
	from im_category_hierarchy
	where parent_id = :project_type_id
    )
"
}




if { 0 != $user_id_from_search} {
    lappend criteria "p.project_id in (select object_id_one from acs_rels where object_id_two = :user_id_from_search)"
}
if { ![empty_string_p $company_id] && $company_id != 0 } {
    lappend criteria "p.company_id=:company_id"
}

if {[string equal $mine_p "t"]} {
    set mine_restriction ""
} else {
    set mine_restriction "or perm.permission_all > 0"
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
    "delivery date" { set order_by_clause "order by end_date DESC" }
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
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
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

set perm_sql "
	(select
	        p.*
	from
	        im_projects p,
		acs_rels r
	where
		r.object_id_one = p.project_id
		and r.object_id_two = :user_id
		$where_clause
	)"

if {[im_permission $user_id "view_projects_all"]} {
	set perm_sql "im_projects"
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
	FROM
		$perm_sql p,
		im_companies c
	WHERE
		p.company_id = c.company_id
		$where_clause
	) projects
$order_by_clause
"

# ---------------------------------------------------------------
# Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------


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
        from ($sql) sql
    "]
    set selection [im_select_row_range $sql $start_idx $end_idx]
}


# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options

set filter_html "
<form method=get action='/intranet/projects/index'>
[export_form_vars start_idx order_by how_many view_name include_subprojects_p letter]

<table border=0 cellpadding=0 cellspacing=0>
  <tr> 
    <td colspan='2' class=rowtitle align=center>
      [_ intranet-core.Filter_Projects]
    </td>
  </tr>
"

if {[im_permission $current_user_id "view_projects_all"]} { 
    append filter_html "
  <tr>
    <td valign=top>[_ intranet-core.View]:</td>
    <td valign=top>[im_select mine_p $view_types ""]</td>
  </tr>
"
}

if {[im_permission $current_user_id "view_projects_all"]} {
    append filter_html "
  <tr>
    <td valign=top>[_ intranet-core.Project_Status]:</td>
    <td valign=top>[im_category_select -include_empty_p 1 "Intranet Project Status" project_status_id $project_status_id]</td>
  </tr>\n"
}

append filter_html "
  <tr>
    <td valign=top>[_ intranet-core.Project_Type]:</td>
    <td valign=top>
      [im_category_select -include_empty_p 1 "Intranet Project Type" project_type_id $project_type_id]
	  <input type=submit value=Go name=submit>
    </td>
  </tr>
</table>
</form>
"

# ----------------------------------------------------------
# Do we have to show administration links?

ns_log Notice "/intranet/project/index: Before admin links"
set admin_html ""
set action_html ""

if {[im_permission $current_user_id "add_projects"]} {
    set text [_ intranet-core.Add_a_new_project]
    append action_html "<a title=\"$text\" class=button href=/intranet/projects/new>$text</a>\n"
}

if {[im_permission $current_user_id "view_finance"]} {
    set text [_ intranet-core.Profit_and_Loss]
    append admin_html "<li><a title=\"text\" href=/intranet/projects/index?view_name=project_costs>$text</a>\n"
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
    set text [_ $package_name.$name_key]
    append action_html "<a title=\"$text\" class=button href=\"$url\">$text</a>\n"
}


set project_filter_html $filter_html

if {"" != $admin_html} {
    set project_filter_html "

<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td> <!-- TD for the left hand filter HTML -->
    $filter_html
  </td> <!-- end of left hand filter TD -->
  <td>&nbsp;</td>
  <td valign=top width='30%'>
    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
        [_ intranet-core.Admin_Projects]
      </td>
    </tr>
    <tr>
      <td>
        $admin_html
      </td>
    </tr>
    </table>
  </td>
</tr>
</table>
"
}


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
    set col_txt [_ intranet-core.$col_txt]
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

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 1
set idx $start_idx
db_foreach projects_info_query $selection {

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
[im_project_navbar $letter "/intranet/projects/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter] $menu_select_label]
"



ns_log Notice "/intranet/project/index: before release handes"
db_release_unused_handles

