# /packages/intranet-core/www/intranet/companies/index.tcl
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
    Shows all companies. Lots of dimensional sliders

    @param status_id if specified, limits view to those of this status
    @param type_id   if specified, limits view to those of this type
    @param order_by  Specifies order for the table
    @param view_type Specifies which companies to see

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author Juanjo Ruiz (juanjoruizx@yahoo.es)
} {
    { status_id:integer "" }
    { type_id:integer "[im_company_type_customer]" }
    { start_idx:integer "1" }
    { order_by "Company" }
    { how_many "" }
    { view_type "all" }
    { letter:trim "all" }
    { view_name "company_list" }
}

# ---------------------------------------------------------------
# Company List Page
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

set user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set page_title "[_ intranet-core.Companies]"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url "/intranet/companies/index"

set user_view_page "/intranet/users/view"
set company_view_page "/intranet/companies/view"
set view_types [list "mine" "[_ intranet-core.Mine]" "all" "[_ intranet-core.All]" "[_ intranet-core.unassigned]" "[_ intranet-core.Unassigned]"]
set letter [string toupper $letter]

if { ![exists_and_not_null status_id] } {
    # Default status is Current - select the id once and memoize it
    set status_id [im_memoize_one select_company_status_id \
	    "select company_status_id 
               from im_company_status
              where upper(company_status) = 'ACTIVE'"]
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
set status_types [im_memoize_list select_company_status_types \
	"select company_status_id, company_status
           from im_company_status
          order by lower(company_status)"]
set status_types [linsert $status_types 0 0 All]


# company_types will be a list of pairs of (company_type_id, company_type)
set company_types [im_memoize_list select_companies_types \
	"select company_type_id, company_type
           from im_company_types
          order by lower(company_type)"]
set company_types [linsert $company_types 0 0 All]

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

# Now let's generate the sql query
set criteria [list]

set bind_vars [ns_set create]
if { ![empty_string_p $status_id] && $status_id != 0 } {
    ns_set put $bind_vars status_id $status_id
    lappend criteria "c.company_status_id=:status_id"
}

if { $type_id > 0 } {
    ns_set put $bind_vars type_id $type_id
    lappend criteria "c.company_type_id in (
	select	category_id
	from	im_categories
	where	category_id= :type_id
      UNION
	select distinct
		child_id
	from	im_category_hierarchy
	where	parent_id = :type_id
      )"
}

if { ![empty_string_p $letter] && [string compare $letter "ALL"] != 0 && [string compare $letter "SCROLL"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(c.company_name)=:letter"
}

set extra_tables [list]

set order_by_clause ""
switch $order_by {
    "Phone" { set order_by_clause "order by upper(phone_work), upper(company_name)" }
    "Email" { set order_by_clause "order by upper(email), upper(company_name)" }
    "Type" { set order_by_clause "order by upper(company_type), upper(company_name)" }
    "Status" { set order_by_clause "order by upper(company_status), upper(company_name)" }
    "Contact Person" { set order_by_clause "order by upper(last_name), upper(first_names), upper(company_name)" }
    "Company" { set order_by_clause "order by upper(company_name)" }
}

set extra_table ""
if { [llength $extra_tables] > 0 } {
    set extra_table ", [join $extra_tables ","]"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}



# Performance: There are probably relatively few projects
# that comply to the selection criteria and that include
# the current user. We apply the $where_clause anyway.
set perm_sql "(
		select	
		        c.*
		from
		        im_companies c,
			acs_rels r
		where
		        c.company_id = r.object_id_one
			and r.object_id_two = :user_id
			$where_clause
	) c"

# Show the list of all projects only if the user has the
# "view_companies_all" privilege AND if he explicitely
# requests to see all projects.
if {[im_permission $user_id 'view_companies_all'] && ![string equal $view_type "mine"]} {
    # Just include the list of all customers
    set perm_sql "im_companies c"
}

set sql "
select
	c.*,
	c.primary_contact_id as company_contact_id,
	im_name_from_user_id(c.accounting_contact_id) as accounting_contact_name,
	im_email_from_user_id(c.accounting_contact_id) as accounting_contact_email,
	im_name_from_user_id(c.primary_contact_id) as company_contact_name,
	im_email_from_user_id(c.primary_contact_id) as company_contact_email,
        im_category_from_id(c.company_type_id) as company_type,
        im_category_from_id(c.company_status_id) as company_status
from 
	$perm_sql $extra_table
where
        1=1
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
		im_companies c
		$extra_table
        where 
		1=1
		$where_clause
	"]
    
    set selection "$sql $order_by_clause"

#    set selection "select z.* from ($limited_query) z $order_by_clause"
}	

ns_log Notice $selection


# ----------------------------------------------------------
# Do we have to show administration links?

set admin_html ""
if {[im_permission $current_user_id "add_companies"]} {
    append admin_html "
<li><a href=/intranet/companies/new>[_ intranet-core.Add_a_new_Company]</a>
<li><a href=/intranet/companies/upload-companies?[export_url_vars return_url]>[_ intranet-core.Import_Company_CVS]</a>
<li><a href=/intranet/companies/upload-contacts?[export_url_vars return_url]>[_ intranet-core.lt_Import_Company_Contac]</a>
"
}

if {[im_permission $user_id admin_companies]} {
    append admin_html "
<li><a href=upload-companies?[export_url_vars return_url]>[_ intranet-core.Upload_Company_CSV]</a>
<li><a href=upload-contacts?[export_url_vars return_url]>[_ intranet-core.Upload_Contact_CSV]</a>
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


# ad_return_complaint 1 "<pre>$selection</pre>"

db_foreach projects_info_query $selection {

#    im_company_permissions $user_id $company_id company_view company_read company_write company_admin
#    if {!$company_read} { continue }

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


set table_continuation_html ""

db_release_unused_handles
