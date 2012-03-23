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
    { status_id:integer "[im_company_status_active]" }
    { type_id:integer "[im_company_type_customer]" }
    { start_idx:integer 0 }
    { order_by "Company" }
    { how_many "" }
    { view_type "all" }
    { letter:trim "all" }
    { view_name "company_list" }
    { user_id_from_search:integer 0}
    { filter_advanced_p:integer 0 }
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
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set page_title "[_ intranet-core.Companies]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url "/intranet/companies/index"

set user_view_page "/intranet/users/view"
set company_view_page "/intranet/companies/view"
set view_types [list "mine" "Mine" "all" "All" "unassigned" "Unassigned"]
set letter [string toupper $letter]

set end_idx [expr $start_idx + $how_many - 1]

set criteria [list]

# Restrict access of unprivileged users to active companies only
set view_companies_all_p [im_permission $user_id view_companies_all]
if {!$view_companies_all_p} {
    set status_id [im_company_status_active]
    set view_type "mine"
}


# Set the "menu_select_label" for the company navbar:
# customers_active, customer_inactive and customers_potential
# depending on type_id and status_id:
#
set menu_select_label ""

# In case a Freelancer logs in show providers, not customers
if { [im_user_is_freelance_p $current_user_id] } {
    set type_id [im_company_type_provider]
}

if {$type_id == [im_company_type_customer]} {
    switch $status_id {
	41 { set menu_select_label "customers_potential" }
	46 { set menu_select_label "customers_active" }
	48 { set menu_select_label "customers_inactive" }
	default { set menu_select_label "" }
    }
}





# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set dynamic_fields_p 1
set form_id "company_filter"
set object_type "im_company"
set action_url "/intranet/companies/index"
set form_mode "edit"
set mine_p_options {{"All" "all"} {"Mine" "mine"}}

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -export {start_idx order_by how_many letter view_name filter_advanced_p} \
    -form {
	{mine_p:text(select),optional {label "Mine/All"} {options $mine_p_options }}
    }


if {$view_companies_all_p} {

    ad_form -extend -name $form_id -form {
        {status_id:text(im_category_tree),optional {label "Status"} {custom {category_type "Intranet Company Status" } } }
        {type_id:text(im_category_tree),optional {label "Type"} {custom {category_type "Intranet Company Type"} } }
    }

}


im_dynfield::append_attributes_to_form \
    -object_type $object_type \
    -form_id $form_id \
    -object_id 0

# Set the form values from the HTTP form variable frame
im_dynfield::set_form_values_from_http -form_id $form_id

array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
			       -form_id $form_id \
			       -object_type "im_company"
			  ]


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
# 5. Generate SQL Query
# ---------------------------------------------------------------

# Now let's generate the sql query
if { $status_id > 0 } {
    lappend criteria "c.company_status_id in ([join [im_sub_categories $status_id] ","])"
}
if { 0 != $user_id_from_search} {
    lappend criteria "c.company_id in (select object_id_one from acs_rels where object_id_two = :user_id_from_search)\n"
}
if { $type_id > 0 } {
    lappend criteria "c.company_type_id in ([join [im_sub_categories $type_id] ","])"
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
    "Contact" { set order_by_clause "order by upper(company_contact_name)" }
    "Contact Email" { set order_by_clause "order by upper(company_contact_email)" }
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
# Add the DynField variables to $form_vars
set dynfield_extra_where $extra_sql_array(where)
set ns_set_vars $extra_sql_array(bind_vars)
set tmp_vars [util_list_to_ns_set $ns_set_vars]
set tmp_var_size [ns_set size $tmp_vars]
for {set i 0} {$i < $tmp_var_size} { incr i } {
    set key [ns_set key $tmp_vars $i]
    set value [ns_set get $tmp_vars $key]
    ns_log Notice "companies/index: $key=$value"
    ns_set put $form_vars $key $value
}

# Add the additional condition to the "where_clause"
if {"" != $dynfield_extra_where} {
    append where_clause "
	    and company_id in $dynfield_extra_where
        "
}


# Performance: There are probably relatively few projects
# that comply to the selection criteria and that include
# the current user. We apply the $where_clause anyway.

# Get the inner "perm_sql" statement
set perm_statement [db_qd_get_fullname "perm_sql" 0]
set perm_sql_uneval [db_qd_replace_sql $perm_statement {}]
set perm_sql [expr "\"$perm_sql_uneval\""]


# Show the list of all projects only if the user has the
# "view_companies_all" privilege AND if he explicitely
# requests to see all projects.
if {$view_companies_all_p && ![string equal $view_type "mine"]} {
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
    set selection "select * from ($sql) s $order_by_clause"

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
	" -bind $form_vars ]
    
    set selection "select * from ($sql) s $order_by_clause"
}	

ns_log Notice $selection


# ----------------------------------------------------------
# Do we have to show administration links?

set admin_html "<ul>"
if {[im_permission $current_user_id "add_companies"]} {

    append admin_html "
	<li><a href=/intranet/companies/new>[_ intranet-core.Add_a_new_Company]</a>\n"
}

if {$user_is_admin_p} {
    append admin_html "
<li><a href=/intranet/companies/upload-companies?[export_url_vars return_url]>[_ intranet-core.Import_Company_CSV]</a>
<!-- <li><a href=/intranet/companies/upload-contacts?[export_url_vars return_url]>[_ intranet-core.lt_Import_Company_Contac]</a> -->
"}

append admin_html "
<li><a href=\"/intranet/companies/index?filter_advanced_p=1\">[_ intranet-core.Advanced_Filtering]</a>
"

# Append user-defined menus
append admin_html [im_menu_ul_list -no_uls 1 "companies_admin" {}]


append admin_html "</ul>"


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

    regsub -all " " $col "_" col_txt
    set col_txt [_ intranet-core.$col_txt]

    if { [string compare $order_by $col] == 0 } {
	append table_header_html "  <td class=rowtitle>$col_txt</td>\n"
    } else {
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
set ctr 0
set idx $start_idx


db_foreach company_info_query $selection -bind $form_vars {

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

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]"
} else {
    set previous_page_url ""
}
set table_continuation_html ""



# ---------------------------------------------------------------
# Format top and left menus
# ---------------------------------------------------------------

set sub_navbar [im_company_navbar "" "/intranet/companies/" $next_page_url $previous_page_url [list order_by how_many view_name view_type status_id type_id] $menu_select_label] 


eval [template::adp_compile -string {<formtemplate style="tiny-plain-po" id="company_filter"></formtemplate>}]
set filter_html $__adp_output

set left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
	    #intranet-core.Filter_Companies#
         </div>
            $filter_html
      </div>
      <hr/>
"

if {!$filter_advanced_p} {
    set left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
	    #intranet-core.Filter_Companies#
         </div>
	            <form method='get' action='/intranet/companies/index' name='filter_form'>
		       [export_form_vars start_idx order_by how_many letter view_name]
		       <table border='0' cellpadding='0' cellspacing='0'>
	               <if @view_companies_all_p@>
		          <tr>
		             <td>#intranet-core.View_1#  &nbsp;</td>
		             <td>[im_select view_type $view_types ""]</td>
		          </tr>
		          <tr>
		             <td>#intranet-core.Company_Status_1#  &nbsp;</td>
		             <td>[im_category_select -include_empty_p 1 "Intranet Company Status" status_id $status_id]</td>
		          </tr>
	               </if>
		       <tr>
		          <td>#intranet-core.Company_Type_1#  &nbsp;</td>
		          <td>
		             [im_category_select -include_empty_p 1 "Intranet Company Type" type_id $type_id]
		             <input type=submit value='[_ intranet-core.Action_Go]' name=submit>
		          </td>
		      </tr>
		      </table>
		    </form>
      </div>
      <hr/>
    "
}

append left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
            #intranet-core.Admin_Companies#
         </div>
         $admin_html
      </div>
"
