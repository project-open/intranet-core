# /packages/intranet-core/users/index.tcl
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
    Shows all users. Lots of dimensional sliders

    @param order_by  Specifies order for the table
    @param view_type Specifies which users to see
    @param view_name Name of view used to defined the columns
    @param user_group_name Name of the group of users to be shown

    @author unknown@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { user_group_name:trim "Employees" }
    { order_by "Name" }
    { start_idx:integer "1" }
    { how_many:integer "" }
    { letter:trim "all" }
    { view_name "" }
}

# ---------------------------------------------------------------
# User List Page
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
#	for example hiding user names to freelancers.
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
set page_title "[_ intranet-core.Users]"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]
set user_view_page "/intranet/users/view"
set letter [string toupper $letter]
set date_format "YYYY-MM-DD"

# Get the ID of the group of users to show
# Default 0 corresponds to the list of all users.
set user_group_id 0
set menu_select_label ""
switch [string tolower $user_group_name] {
    "all" { 
	set user_group_id 0 
	set menu_select_label "users_all"
    }
    "unregistered" { set user_group_id -1 }
    default {
	set user_group_id [db_string user_group_id "select group_id from groups where group_name like :user_group_name" -default 0]
	set menu_select_label "users_[string tolower $user_group_name]"
    }
}

if {$user_group_id > 0} {

    # We have a group specified to show:
    # Check whether the user can "read" this group:
    set sql "select im_object_permission_p(:user_group_id, :user_id, 'read') from dual"
    set read [db_string user_can_read_user_group_p $sql]
    if {![string equal "t" $read]} {
	ad_return_complaint 1 "[_ intranet-core.lt_You_dont_have_permiss]"
	return
    }

} else {

    # The user requests to see all groups.
    # The most critical groups are company contacts...
    set company_group_id [db_string user_group_id "select group_id from groups where group_name like :user_group_name" -default 0]

    set sql "select im_object_permission_p(:company_group_id, :user_id, 'read') from dual"
    set read [db_string user_can_read_user_group_p $sql]
    if {![string equal "t" $read]} {
	ad_return_complaint 1 "[_ intranet-core.lt_You_dont_have_permiss]"
	return
    }
}

# If no view_name was explicitely specified
# Then check if there is a specific view for 
# the user_group.
if {"" == $view_name} {

    # Check if there is a specific view for this user group:
    set specific_view_name "[string tolower $user_group_name]_list"
    ns_log Notice "/users/index: Checking if view='$specific_view_name' exists:"
    set expcific_view_exists [db_string specific_view_exists "select count(*) from im_views where view_name=:specific_view_name"]
    if {$expcific_view_exists} {
	set view_name $specific_view_name
    }
}

# Check if there was no specific view_name:
# In this case just show the default user_view
if {"" == $view_name} {
    set view_name "user_list"
}


if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage intranet 50]
}
set end_idx [expr $start_idx + $how_many - 1]

# ---------------------------------------------------------------
# 3. Define Table Columns
# ---------------------------------------------------------------

set extra_wheres [list]
set extra_froms [list]
set extra_selects [list]

set extra_order_by ""
set column_headers [list]
set column_vars [list]

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id} { 
    ad_return_complaint 1 "<li>[_ intranet-core.lt_Internal_error_unknow]<br>
    [_ intranet-core.lt_You_are_trying_to_acc]<br>
    [_ intranet-core.lt_Please_notify_your_sy]"
}

set column_sql "
select	c.*
from	im_view_columns c
where	view_id=:view_id
	and group_id is null
order by
	sort_order"

db_foreach column_list_sql $column_sql {
    ns_log Notice "/intranet/users/index: visible_for=$visible_for"

    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"

	if [exists_and_not_null extra_from] { lappend extra_froms $extra_from }
	if [exists_and_not_null extra_select] { lappend extra_selects $extra_select }
	if [exists_and_not_null extra_where] { lappend extra_wheres $extra_where }

	if [exists_and_not_null order_by_clause] { 
	    if {[string equal $order_by $column_name]} {
		# We need to sort the list by this column
		set extra_order_by $order_by_clause
	    }
	}
    }
}
ns_log Notice "/users/index.tcl: column_vars=$column_vars"

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

# Now let's generate the sql query
set bind_vars [ns_set create]

if { $user_group_id > 0 } {
    append page_title " in group \"$user_group_name\""
    lappend extra_wheres "u.user_id = m.member_id"
    lappend extra_wheres "m.group_id = :user_group_id"
    lappend extra_froms "group_distinct_member_map m"
}


if { -1 == $user_group_id} {
    # "Unregistered users
    append page_title " Unregistered"
    lappend extra_wheres "u.user_id not in (select distinct member_id from group_distinct_member_map where group_id >= 0)"
}


if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    set letter [string toupper $letter]
    lappend extra_wheres "im_first_letter_default_to_a(u.last_name)=:letter"
}

# Check for some default order_by fields.
# This switch statement should be eliminated 
# in the future as soon as all im_view_columns
# contain order_by_clauses.
if {"" == $extra_order_by} {
    switch $order_by {
	"Name" { set extra_order_by "order by upper(u.last_name||u.first_names)" }
	"Email" { set extra_order_by "order by upper(email)" }
	"AIM" { set extra_order_by "order by upper(aim_screen_name)" }
	"Cell Phone" { set extra_order_by "order by upper(cell_phone)" }
	"Home Phone" { set extra_order_by "order by upper(home_phone)" }
	"Work Phone" { set extra_order_by "order by upper(work_phone)" }
	"Last Visit" { set extra_order_by "order by last_visit DESC" }
	"Creation" { set extra_order_by "order by creation_date DESC" }
    }
}

# Join the "extra_" SQL pieces 
set extra_from [join $extra_froms ",\n\t"]
set extra_select [join $extra_selects ",\n\t"]
set extra_where [join $extra_wheres "\n\tand "]

if {"" != $extra_from} { set extra_from ",$extra_from" }
if {"" != $extra_select} { set extra_select ",$extra_select" }
if {"" != $extra_where} { set extra_where "and $extra_where" }


set sql "
select
	u.*,
	to_char(o.creation_date,:date_format) as creation_date,
	im_email_from_user_id(u.user_id) as email,
	im_name_from_user_id(u.user_id) as name
	$extra_select
from 
	users_active u, 
	acs_objects o
	$extra_from
where 
	u.user_id = o.object_id
	$extra_where
$extra_order_by
"

# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------


# Limit the search results to N data sets only
# to be able to manage large sites
#
if { [string compare $letter "all"] == 0 } {
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1
    set query $sql
} else {
#    set query [im_select_row_range $sql $start_idx $end_idx]
    set query $sql
    # We can't get around counting in advance if we want to be able to 
    # sort inside the table on the page for only those users in the 
    # query results
    set total_in_limited [db_string advance_count "
select 
	count(1) 
from 
	($sql) t
"]

    ns_log Notice "/users/index.tcl: sql=$sql"
    ns_log Notice "/users/index.tcl: total_in_limited=$total_in_limited"
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
    set cmd "set col_text $col"
    eval "$cmd"
    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>$col_text</td>\n"
    } else {
	append table_header_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col_text</a></td>\n"
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
db_foreach projects_info_query $query {

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

if { $start_idx > 1 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 1 } {
	set previous_start_idx 1
    }
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
# 10. Join all parts together
# ---------------------------------------------------------------

set page_body "
<br>
[im_user_navbar $letter "/intranet/users/index" $next_page_url $previous_page_url [list start_idx order_by how_many view_name user_group_name letter] $menu_select_label]

<table width=100% cellpadding=2 cellspacing=2 border=0>
  $table_header_html
  $table_body_html
  $table_continuation_html
</table>"

if {[im_permission $user_id "add_users"]} {
    append page_body "<p><a href=/intranet/users/new>[_ intranet-core.Add_New_User]</a>\n"
}

db_release_unused_handles

