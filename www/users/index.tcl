# /www/intranet/users/index.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Shows all users. Lots of dimensional sliders

    @param order_by  Specifies order for the table
    @param view_type Specifies which users to see
    @param view_name Name of view used to defined the columns
    @param user_group_name Name of the group of users to be shown

    @author Frank Bergmann (frabe@fraber.de)
    @creation-date Jan 2004
} {
    { user_group_name:trim "Employees" }
    { order_by "Name" }
    { start_idx:integer "1" }
    { how_many:integer "" }
    { letter:trim "all" }
    { view_name "user_list" }
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
set page_title "Users"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]
set user_view_page "/intranet/users/view"
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]


# Get the ID of the group of users to show:
set user_group_id [db_string user_group_id "select group_id from groups where group_name like :user_group_name" -default 0]

set letter [string toupper $letter]
set user_is_group_member_p [ad_user_group_member $user_group_id $user_id]
set user_is_group_admin_p [im_can_user_administer_group $user_group_id $user_id]

if {![im_permission $user_id view_users]} {
    set err_msg "You don't have permissions to view users"
    ad_returnredirect "/error?error=$err_msg"
    return
}

# redirect unprivileged users of "all users" to "employees".
if {$user_group_id==0 || [string equal "" $user_group_id]} {
    if {![im_permission $user_id view_customer_contacts]} {
	set user_group_id [im_employee_group_id]
    }
}

if {$user_group_id==[im_customer_group_id] && ![im_permission $user_id view_customer_contacts]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You have insufficient privileges to view group# $user_group_id."
}

if {$user_group_id==[im_freelance_group_id] && ![im_permission $user_id view_freelancers]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You have insufficient privileges to view group# $user_group_id."
}


if {$user_group_id != [im_freelance_group_id] && $user_group_id != [im_employee_group_id] && $user_group_id != [im_customer_group_id] && $user_group_id != 0} {
   if {!$user_is_group_member_p && !$user_is_group_admin_p && !$user_admin_p} {
	ad_return_complaint "Insufficient Privileges" "
	<li>You have insufficient privileges to view group# $user_group_id."
    }
}

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [ad_parameter NumberResultsPerPage intranet 50]
}
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
    if {[eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
    }
}

# ---------------------------------------------------------------
# 4. Define Filter Categories
# ---------------------------------------------------------------

# No filters...

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

# Now let's generate the sql query
set criteria [list]
set extra_tables [list]
set bind_vars [ns_set create]

if { ![empty_string_p $user_group_id] && $user_group_id>0 } {
    append page_title " in group \"$user_group_name\""
    lappend criteria "ad_group_member_p(u.user_id, :user_group_id) = 't'"
}

if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    set letter [string toupper $letter]
    lappend criteria "im_first_letter_default_to_a(p.last_name)=:letter"
}

if { [llength $criteria] > 0 } {
    set where_clause [join $criteria "\n         and "]
} else {
    set where_clause "1=1"
}

set order_by_clause ""
switch $order_by {
    "Name" { set order_by_clause "order by upper(p.last_name||p.first_names)" }
    "Email" { set order_by_clause "order by upper(email)" }
    "AIM" { set order_by_clause "order by upper(aim_screen_name)" }
    "Cell Phone" { set order_by_clause "order by upper(cell_phone)" }
    "Home Phone" { set order_by_clause "order by upper(home_phone)" }
    "Work Phone" { set order_by_clause "order by upper(work_phone)" }
}

set extra_table ""
if { [llength $extra_tables] > 0 } {
    set extra_table ", [join $extra_tables ","]"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set sql "
select 
	u.user_id,
	im_email_from_user_id(u.user_id) as email,
	im_name_from_user_id(u.user_id) as name,
	p.first_names,
	p.last_name,
	c.msn_screen_name as msn_email, 
	c.home_phone, 
	c.work_phone, 
	c.cell_phone
from 
	users u, 
	users_contact c,
	persons p
where 
	u.user_id=p.person_id
	and u.user_id=c.user_id(+)
	$where_clause
        $order_by_clause"


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
    set query [im_select_row_range $sql $start_idx $end_idx]
    # We can't get around counting in advance if we want to be able to 
    # sort inside the table on the page for only those users in the 
    # query results
    set total_in_limited [db_string advance_count "
select 
	count(1) 
from 
	users u,
	persons p
where 
	u.user_id = p.person_id
	$where_clause
"]

}

# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# No filter except for the alpha-bar
set filter_html ""


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
db_foreach projects_info_query $query {

    # Append together a line of data based on the "column_vars" parameter list
    append table_body_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append table_body_html "\t<td valign=top>"
	set cmd "append table_body_html $column_var"
	eval $cmd
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
        There are currently no entries matching the selected criteria
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

set group_id $user_group_id

set page_body "
<BR>
$filter_html
[im_user_navbar $letter "/intranet/users/index" $next_page_url $previous_page_url [list group_id start_idx order_by how_many view_name letter]]

<table width=100% cellpadding=2 cellspacing=2 border=0>
  $table_header_html
  $table_body_html
  $table_continuation_html
</table>"

if {[im_permission $user_id "add_users"]} {
    append page_body "<p><a href=/intranet/users/new>Add New User</a>\n"
}

db_release_unused_handles

doc_return  200 text/html [im_return_template]
