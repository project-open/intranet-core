# /packages/intranet-core/www/intranet/offices/index.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
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
    Shows all offices. Lots of dimensional sliders

    @param status_id if specified, limits view to those of this status
    @param type_id   if specified, limits view to those of this type
    @param order_by  Specifies order for the table

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { status_id:integer 160 }
    { type_id:integer 0 }
    { start_idx:integer 0 }
    { order_by "Office" }
    { how_many "" }
    { letter:trim "all" }
    { view_name "office_list" }
}

# ---------------------------------------------------------------
# Office List Page
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
#	for example hiding office names to freelancers.
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

set user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set page_title "Offices"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url "/intranet/offices/index"

set company_view_page "/intranet/companies/view"
set user_view_page "/intranet/users/view"
set office_view_page "/intranet/offices/view"
set letter [string toupper $letter]

set end_idx [expr $start_idx + $how_many - 1]


# ---------------------------------------------------------------
# 3. Define Table Columns
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
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
# 4. Define Filters
# ---------------------------------------------------------------

# status_types will be a list of pairs of (project_status_id, project_status)
set status_types [im_memoize_list select_office_status_types \
	"select office_status_id, office_status
           from im_office_status
          order by lower(office_status)"]
set status_types [linsert $status_types 0 0 All]


# office_types will be a list of pairs of (office_type_id, office_type)
set office_types [im_memoize_list select_offices_types \
	"select office_type_id, office_type
           from im_office_types
          order by lower(office_type)"]
set office_types [linsert $office_types 0 0 All]

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

# Now let's generate the sql query
set criteria [list]

set bind_vars [ns_set create]
if { ![empty_string_p $status_id] && $status_id != 0 } {
    ns_set put $bind_vars status_id $status_id
    lappend criteria "o.office_status_id=:status_id"
}

if { $type_id > 0 } {
    ns_set put $bind_vars type_id $type_id
    lappend criteria "o.office_type_id=:type_id"
}

if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(c.office_name)=:letter"
}

set order_by_clause ""
switch $order_by {
    "Phone" { set order_by_clause "order by upper(phone), upper(office_name)" }
    "Email" { set order_by_clause "order by upper(email), upper(office_name)" }
    "Type" { set order_by_clause "order by upper(im_category_from_id(o.office_type_id)), upper(office_name)" }
    "Status" { set order_by_clause "order by upper(im_category_from_id(o.office_status_id)), upper(office_name)" }
    "Contact" { set order_by_clause "order by upper(im_name_from_user_id(contact_person_id)), upper(office_name)" }
    "Office" { set order_by_clause "order by upper(office_name)" }
    "City" { set order_by_clause "order by upper(address_city)" }
    "Company" { set order_by_clause "order by upper(company_name)" }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ----------------------------------------------------------------
# Permissions and Performance:
# This SQL shows office depending on the permissions
# of the current user: 
#
#	IF the user is a office member
#	OR if the user has the privilege to see all offices.
#
# The performance problems are due to the number of offices
# (several thousands), the number of users (several thousands)
# and the acs_rels relationship between users and offices.
# Despite all of these, the page should ideally appear in less
# then one second, because it is frequently used.
# 
# In order to get acceptable load times we use an inner "perm"
# SQL that selects office_ids "outer-joined" with the membership 
# information for the current user.
# This information is then filtered in the outer SQL, using an
# OR statement, acting as a filter on the returned office_ids.
# It is important to apply this OR statement outside of the
# main join (offices and membership relation) in order to
# reach a reasonable response time.

# Get the inner "perm_sql" statement
set perm_statement [db_qd_get_fullname "perm_sql" 0]
set perm_sql_uneval [db_qd_replace_sql $perm_statement {}]
set perm_sql [expr "\"$perm_sql_uneval\""]

set sql "
	select
		o.*,
		im_name_from_user_id(o.contact_person_id) as contact_person_name,
		im_email_from_user_id(o.contact_person_id) as contact_person_email,
	        im_category_from_id(o.office_type_id) as office_type,
	        im_category_from_id(o.office_status_id) as office_status,
		c.company_id,
		c.company_name
	from 
		im_offices o
		LEFT OUTER JOIN im_companies c ON (o.company_id = c.company_id),
		($perm_sql) perm
	where
		perm.office_id = o.office_id
	        and (
			perm.permission_member > 0
	        or
			perm.permission_all > 0
	        )
		$where_clause
"

# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

# Limit the search results to N data sets only
# to be able to manage large sites
#
if {[string compare $letter "ALL"]} {

    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1
    set selection "$sql $order_by_clause"

} else {

    set limited_query [im_select_row_range $sql $start_idx $end_idx]
    # We can't get around counting in advance if we want to be able to 
    # sort inside the table on the page for only those users in the 
    # query results
    set total_in_limited [db_string projects_total_in_limited "
	select count(*) 
        from
		im_offices o
        where 
		1=1
		$where_clause
	"]
    
    set selection "$sql $order_by_clause"

#    set selection "select z.* from ($limited_query) z $order_by_clause"
}	

ns_log Notice $selection

# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

set filter_html "
<form method=get action='/intranet/offices/index' name=filter_form>
[export_form_vars start_idx order_by how_many letter view_name]
<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td valign=top>[_ intranet-core.Office_Status]: </td>
  <td valign=top>[im_select status_id $status_types $status_id]</td>
</tr>
<tr>
  <td valign=top>[_ intranet-core.Office_Type]: </td>
  <td valign=top>
    [im_select type_id $office_types ""]
    <input type=submit value=Go name=submit>
  </td>
</tr>
</table>
</form>"


# ----------------------------------------------------------
# Do we have to show administration links?

set admin_html ""
if {[im_permission $current_user_id "add_offices"]} {
    append admin_html "<li><a href=/intranet/offices/new>[_ intranet-core.Add_a_new_Office]</a>\n"
}

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

# Format the header names with links that modify the
# sort order of the SQL query.
#
set table_header_html ""
set url "index?"
set query_string [export_ns_set_vars url [list order_by]]
if { ![empty_string_p $query_string] } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
foreach col $column_headers {
    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>$col</td>\n"
    } else {
	append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></td>\n"
    }
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
db_foreach projects_info_query $selection {

    # Append together a line of data based on the "column_vars" parameter list
    append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append table_body_html "\t<td valign=top>"
	set cmd "append table_body_html $column_var"
	eval "$cmd"
	append table_body_html "</td>\n"
    }
    append table_body_html "</tr>\n"

    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
    incr idx
}

ns_log Notice "offices/index: subsite_id=$subsite_id"

# Show a reasonable message when there are no result rows:
if { [empty_string_p $table_body_html] } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
        [_ intranet-core.lt_There_are_currently_n]
        </b></ul></td></tr>"
}

if { $ctr == $how_many && $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 1]
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

# nothing to do here ... (?)
set table_continuation_html ""

# ---------------------------------------------------------------
# Office-Navbar
# ---------------------------------------------------------------

set letter "none"
set next_page_url ""
set previous_page_url ""

set office_navbar_html [im_office_navbar $letter "/intranet/offices/view" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter]]

set left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
            #intranet-core.Filter_Offices#
         </div>
         $filter_html
      </div>
"

if {"" != $admin_html} {
    append left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
            #intranet-core.Admin_Offices#
         </div>
         <ul>
            $admin_html
         </ul>
      </div>
    "
}
