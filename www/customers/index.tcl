# /www/intranet/customers/index.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Shows all customers. Lots of dimensional sliders

    @param status_id if specified, limits view to those of this status
    @param type_id   if specified, limits view to those of this type
    @param order_by  Specifies order for the table
    @param view_type Specifies which customers to see

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id index.tcl,v 3.20.2.7 2000/09/22 01:38:28 kevin Exp

} {
    { status_id:integer "" }
    { type_id:integer "0" }
    { start_idx:integer "1" }
    { order_by "Client" }
    { how_many "" }
    { view_type "all" }
    { letter:trim "all" }
    { view_name "customer_list" }
}

# ---------------------------------------------------------------
# Customer List Page
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
#	for example hiding customer names to freelancers.
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
set current_user_id $user_id
set page_title "Clients"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url "/intranet/customers/index"

set user_view_page "/intranet/users/view"
set customer_view_page "/intranet/customers/view"
set view_types [list "mine" "Mine" "all" "All" "unassigned" "Unassigned"]
set letter [string toupper $letter]

if {![im_permission $user_id view_customer_contacts]} {
    set err_msg "You don't have permissions to view customers"
    ad_returnredirect "/error?error=$err_msg"
    return
}

if { ![exists_and_not_null status_id] } {
    # Default status is Current - select the id once and memoize it
    set status_id [im_memoize_one select_customer_status_id \
	    "select customer_status_id 
               from im_customer_status
              where upper(customer_status) = 'ACTIVE'"]
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

# status_types will be a list of pairs of (project_status_id, project_status)
set status_types [im_memoize_list select_customer_status_types \
	"select customer_status_id, customer_status
           from im_customer_status
          order by lower(customer_status)"]
set status_types [linsert $status_types 0 0 All]


# customer_types will be a list of pairs of (customer_type_id, customer_type)
set customer_types [im_memoize_list select_customers_types \
	"select customer_type_id, customer_type
           from im_customer_types
          order by lower(customer_type)"]
set customer_types [linsert $customer_types 0 0 All]

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

# Now let's generate the sql query
set criteria [list]

set bind_vars [ns_set create]
if { ![empty_string_p $status_id] && $status_id != 0 } {
    ns_set put $bind_vars status_id $status_id
    lappend criteria "c.customer_status_id=:status_id"
}

if { $type_id > 0 } {
    ns_set put $bind_vars type_id $type_id
    lappend criteria "c.customer_type_id=:type_id"
}

if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(c.customer_name)=:letter"
}

set extra_tables [list]
if { [string compare $view_type "mine"] == 0 } {

    ns_set put $bind_vars user_id $user_id
    lappend criteria "ad_group_member_p ( :user_id, c.customer_id ) = 't'"

} elseif { [string compare $view_type "unassigned"] == 0 } {

    ns_set put $bind_vars user_id $user_id
    lappend criteria "not exists (select 1 from group_member_map m where m.group_id = c.customer_id)"

}

set order_by_clause ""
switch $order_by {
    "Phone" { set order_by_clause "order by upper(phone_work), upper(customer_name)" }
    "Email" { set order_by_clause "order by upper(email), upper(customer_name)" }
    "Type" { set order_by_clause "order by upper(customer_type), upper(customer_name)" }
    "Status" { set order_by_clause "order by upper(customer_status), upper(customer_name)" }
    "Contact Person" { set order_by_clause "order by upper(last_name), upper(first_names), upper(customer_name)" }
    "Client" { set order_by_clause "order by upper(customer_name)" }
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
	c.*,
	c.primary_contact_id as customer_contact_id,
	im_name_from_user_id(c.accounting_contact_id) as accounting_contact_name,
	im_email_from_user_id(c.accounting_contact_id) as accounting_contact_email,
	im_name_from_user_id(c.primary_contact_id) as customer_contact_name,
	im_email_from_user_id(c.primary_contact_id) as customer_contact_email,
        '' as customer_phone,
	status.customer_status,
        im_category_from_id(c.customer_type_id) as customer_type
from 
	im_customers c,
        im_customer_status status, 
	im_customer_types customer_type 
	$extra_table
where
	c.customer_type_id = customer_type.customer_type_id (+)
	and c.customer_status_id=status.customer_status_id(+) 
	$where_clause"

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
		im_customers c
		$extra_table
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
<form method=get action='/intranet/customers/index' name=filter_form>
[export_form_vars start_idx order_by how_many letter view_name]
<table border=0 cellpadding=0 cellspacing=0>
<tr> 
  <td colspan='2' class=rowtitle align=center>
    Filter Clients
  </td>
</tr>
<tr>
  <td valign=top>View: </td>
  <td valign=top>[im_select view_type $view_types ""]</td>
</tr>
<tr>
  <td valign=top>Client Status: </td>
  <td valign=top>[im_select status_id $status_types ""]</td>
</tr>
<tr>
  <td valign=top>Client Type: </td>
  <td valign=top>
    [im_select type_id $customer_types ""]
    <input type=submit value=Go name=submit>
  </td>
</tr>
</table>
</form>"


# ----------------------------------------------------------
# Do we have to show administration links?

set admin_html ""
if {[im_permission $current_user_id "add_customers"]} {
    append admin_html "<li><a href=/intranet/customers/new>Add a new Customer</a>\n"
}

if {[im_permission $user_id admin_customers]} {
    append admin_html "
<li><a href=upload-customers?[export_url_vars return_url]>Upload Clients CSV</a>
<li><a href=upload-contacts?[export_url_vars return_url]>Upload Contact CSV</a>
"
}


set customer_filter_html $filter_html

if {"" != $admin_html} {
    set customer_filter_html "

<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td> <!-- TD for the left hand filter HTML -->
    $filter_html
  </td> <!-- end of left hand filter TD -->
  <td>&nbsp;</td>
  <td valign=top>
    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
        Admin Clients
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

db_release_unused_handles
