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
    @param user_group_name Name of the group of users to be shown

    @author unknown@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { user_group_name:trim "Employees" }
    { include_deleted_users_p "" }
    { order_by "Name" }
    { start_idx:integer 0 }
    { how_many:integer "" }
    { letter:trim "all" }
    { filter_advanced_p:integer 0 }
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
# 2. Defaults 
# ---------------------------------------------------------------

set user_id [auth::require_login]
set current_user_id $user_id
set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set page_title "[_ intranet-core.Users]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]
set user_view_page "/intranet/users/view"
set letter [string toupper $letter]
set date_format "YYYY-MM-DD"
set debug_html ""
set email ""
set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]
set show_context_help_p 1

# ---------------------------------------------------------------
# 2a. Security
# ---------------------------------------------------------------

switch $user_group_name {
    "Employees" {
	set menu_label "users_employees"
    }
    "Customers" {
	set menu_label "users_companies"
    }
    "Unregistered" {
	set menu_label "users_unassigned"
    }
    "All" {
	set menu_label "users_all"
    }
    "po_admins" {
	set menu_label "users_admin"
    }
    default {
	set menu_label "user"	
    }
}

set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']

if {"t" ne $read_p } {
    ad_return_complaint 1 "
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

set extra_wheres [list]
set extra_froms [list]
set extra_left_joins [list]
set extra_selects [list]

set extra_order_by ""
set column_headers [list]
set column_headers_admin [list]
set column_vars [list]

set freelancers_exist_p [db_table_exists im_freelancers]

# Get the ID of the group of users to show
# Default 0 corresponds to the list of all users.
# Use a normalized group_name in lowercase and with
# all special characters replaced by "_".
set user_group_name [im_mangle_user_group_name $user_group_name]
set user_group_id 0
set menu_select_label ""
set group_pretty_name ""
switch [string tolower $user_group_name] {
    "all" { 
	set user_group_id 0 
	set menu_select_label "users_all"
    }
    "unregistered" { 
    	set user_group_id -1 
	set menu_select_label "users_unassigned"
    }
    "freelancers" {
        set user_group_id [im_profile_freelancers]
        set menu_select_label "users_freelancers"
	lappend extra_wheres "u.user_id in (select object_id_two from acs_rels where rel_type = 'membership_rel' and  object_id_one = $user_group_id)"
    }
    default {
    	# Search for the right group name.
    	# It's an ugly TCL loop instead of a single SQL statement,
    	# because we use the "mangele_user_group_name" function.
	set user_group_id 0
	db_foreach search_user_group "select group_id, group_name from groups" {
		if {$user_group_name eq [im_mangle_user_group_name $group_name]} {
		    set user_group_id $group_id
		    set group_pretty_name "$group_name"
		}
	}
	set menu_select_label "users_[string tolower $user_group_name]"

	if { $menu_select_label=="users_customers" } {
	    set menu_select_label "users_companies"
	}
    }
}
 

if {$user_group_id > 0} {

#   ad_return_complaint 1 $user_group_id
    # We have a group specified to show:
    # Check whether the user can "read" this group:
    set sql "select im_object_permission_p(:user_group_id, :user_id, 'read') from dual"
    set read [db_string user_can_read_user_group_p $sql]
    if {"t" ne $read } {
	ad_return_complaint 1 "[_ intranet-core.lt_You_dont_have_permiss]"
	return
    }

} else {

    # The user requests to see all groups.
    # The most critical groups are company contacts...
    set read_p 1
    db_foreach groups "select group_id from groups, im_profiles where group_id = profile_id" {
        if {"t" != [db_string read "select im_object_permission_p(:group_id, :user_id, 'read')"]} { 
	    set read_p 0 
	}
    }
    if {!$read_p} {
        ad_return_complaint 1 "[_ intranet-core.lt_You_dont_have_permiss]"
        return
    }

}

# #####
# Setting view - if there is no specific view for the user_group, default to 'user_list' 

set specific_view_name "[string tolower $user_group_name]_list"
# ns_log Notice "/users/index: Checking if view='$specific_view_name' exists:"

set expcific_view_exists [util_memoize [list db_string specific_view_exists "select count(*) from im_views where view_name = '$specific_view_name'"]]
if {$expcific_view_exists} {
    set view_name $specific_view_name
} else {
    set view_name "user_list"
}

# #####
# How many records do we show? 

if { $how_many eq "" || $how_many < 1 } {
    set how_many [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NumberResultsPerPage" -default 50]
}
set end_idx [expr $start_idx + $how_many]



# ---------------------------------------------------------------
# 3. Define Table Columns
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#

set view_id [im_view_id_from_name $view_name]
if {!$view_id} { 
   ad_return_complaint 1 "<li>[_ intranet-core.lt_Internal_error_unknow]<br>
   [_ intranet-core.lt_You_are_trying_to_acc]<br>
   [_ intranet-core.lt_Please_notify_your_sy]"
}

set column_sql "
	select	c.*
	from	im_view_columns c
	where	view_id = :view_id
		and group_id is null
	order by sort_order
"

db_foreach column_list_sql $column_sql {
    # ns_log Notice "/intranet/users/index: visible_for=$visible_for"

    set visible_p 0
    if {"" == $visible_for} { set visible_p 1 }
    if {"" != $visible_for} {
	if {[catch {
	    set visible_p [eval $visible_for]
	} err_msg]} {
	    append debug_html "<li>Error evaluating column visible_for field:<br><pre>$err_msg</pre></li>\n"
	    util_user_message -replace -message "Configuration Error DynViews - Error evaluating 'visible_for': $err_msg. Please notify your System Administrator"
	}
    }

    if {$visible_p} {
	lappend column_headers $column_name
	lappend column_vars "$column_render_tcl"

        if {([info exists extra_from] && $extra_from ne "")} { lappend extra_froms $extra_from }
        if {([info exists extra_select] && $extra_select ne "")} { lappend extra_selects $extra_select }
        if {([info exists extra_where] && $extra_where ne "")} { lappend extra_wheres $extra_where }

	if {([info exists order_by_clause] && $order_by_clause ne "")} { 
	    if {$order_by eq $column_name} {
		# We need to sort the list by this column
		set extra_order_by $order_by_clause
	    }
	}

	set admin_html ""
	if {$admin_p} { 
	    set url [export_vars -base "/intranet/admin/views/new-column" {column_id return_url}]
	    set admin_html "<a href='$url'>[im_gif wrench ""]</a>" 
	}
	lappend column_headers_admin $admin_html
    }
}

# ---------------------------------------------------------------
# 4. Define Filter Categories
# ---------------------------------------------------------------

# status_types will be a list of pairs of (project_status_id, project_status)
set user_status_types [im_memoize_list select_user_status_types \
	"select company_status_id, company_status
           from im_company_status
          order by lower(company_status)"]
set user_status_types [linsert $user_status_types 0 0 All]

set user_types [list [list [_ intranet-core.All] 0]]
db_foreach select_user_types "
	select	group_id,
		group_name
	from	groups,
		im_profiles
	where	group_id = profile_id
" {
    lappend user_types [list $group_name [im_mangle_user_group_name $group_name]]
}


# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set form_id "user_filter"
set object_type "person"
set action_url "/intranet/users/index"
set form_mode "edit"
ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -export {start_idx order_by how_many letter filter_advanced_p} \
    -form {
        {user_group_name:text(select),optional {label #intranet-core.User_Types#} {options $user_types} {value $user_group_name}}
    }

if {$admin_p} {
    set options_list [list [list "" "1"]]
    ad_form -extend -name $form_id -form {
	{include_deleted_users_p:integer(checkbox),optional {label "[lang::message::lookup {} intranet-core.Include_Deleted_Users { }]"} {options $options_list} }
    }
    template::element::set_value $form_id include_deleted_users_p $include_deleted_users_p
}


if {$filter_advanced_p} {

    im_dynfield::append_attributes_to_form \
        -object_type $object_type \
        -form_id $form_id \
        -advanced_filter_p 1 \
        -page_url "/intranet/users/index" \
        -object_id 0

    # Set the form values from the HTTP form variable frame
    im_dynfield::set_form_values_from_http -form_id $form_id

    array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
        -form_id $form_id \
        -object_type $object_type
    ]
}


# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

if { $user_group_id > 0 } {
    append page_title " in group \"$group_pretty_name\""
    set context_bar [im_context_bar $page_title]

    lappend extra_froms "(select member_id from group_distinct_member_map m where group_id = :user_group_id) m"

    lappend extra_wheres "u.user_id = m.member_id"
}

# Don't show deleted users unless specified (in the future)
if {1 != $include_deleted_users_p || !$admin_p} {
    lappend extra_wheres "u.member_state = 'approved'"
}



if { -1 == $user_group_id} {
    # "Unregistered users
    append page_title " Unregistered"
    lappend extra_wheres "u.user_id not in (select distinct member_id from group_distinct_member_map where group_id >= 0)"
}


if { $letter ne "" && $letter ne "ALL"  && $letter ne "SCROLL"  } {
    set letter [string toupper $letter]
    lappend extra_wheres "im_first_letter_default_to_a(u.last_name)=:letter"
}

# Check for some default order_by fields.
# This switch statement should be eliminated 
# in the future as soon as all im_view_columns
# contain order_by_clauses.
if {"" == $extra_order_by} {
    switch $order_by {
	"Name" { set extra_order_by "order by name" }
	"Email" { set extra_order_by "order by upper(u.email), name" }
	"Department" { set extra_order_by "order by upper(acs_object__name(e.department_id)), name" }
	"AIM" { set extra_order_by "order by upper(aim_screen_name), name" }
	"Cell Phone" { set extra_order_by "order by upper(cell_phone), name" }
	"Home Phone" { set extra_order_by "order by upper(home_phone), name" }
	"Work Phone" { set extra_order_by "order by upper(work_phone), name" }
	"Last Visit" { set extra_order_by "order by last_visit DESC, name" }
	"Creation" { set extra_order_by "order by u.creation_date DESC, name" }
	"Supervisor" { set extra_order_by "order by e.supervisor_id, name" }
    }
}

if {$freelancers_exist_p} {
    lappend extra_selects "fl.*"
    lappend extra_left_joins "LEFT OUTER JOIN im_freelancers fl ON (fl.user_id = u.user_id)"
}

# Join the "extra_" SQL pieces 
set extra_from [join $extra_froms ",\n\t"]
set extra_left_join [join $extra_left_joins "\n\t"]
set extra_select [join $extra_selects ",\n\t"]
set extra_where [join $extra_wheres "\n\tand "]

if {"" != $extra_from} { set extra_from ",$extra_from" }
if {"" != $extra_select} { set extra_select ",$extra_select" }
if {"" != $extra_where} { set extra_where "and $extra_where" }


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
if {$filter_advanced_p && [im_table_exists im_dynfield_attributes]} {

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
	    append extra_where "
                and p.person_id in $dynfield_extra_where
            "
    }
}

set sql "
select
	e.*,
	p.*,
	u.*,
	c.home_phone, c.work_phone, c.cell_phone, c.pager,
	c.fax, c.aim_screen_name, c.msn_screen_name,
	c.icq_number, c.m_address,
	c.ha_line1, c.ha_line2, c.ha_city, c.ha_state, c.ha_postal_code, c.ha_country_code,
	c.wa_line1, c.wa_line2, c.wa_city, c.wa_state, c.wa_postal_code, c.wa_country_code,
	c.note, c.current_information,
        to_char(u.last_visit, 'YYYY-MM-DD HH:SS') as last_visit_formatted,
	to_char(u.creation_date,:date_format) as creation_date,
	im_name_from_user_id(u.user_id, $name_order) as name
	$extra_select
from 
	persons p,
	cc_users u
	LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
	LEFT OUTER JOIN users_contact c ON (u.user_id = c.user_id)
	$extra_left_join
	$extra_from
where
	p.person_id = u.user_id
	$extra_where
$extra_order_by
"

# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------


# Limit the search results to N data sets only
# to be able to manage large sites
#
if { $letter eq "all"  } {
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
		($sql) t
    " -bind $form_vars]
}

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr {[llength $column_headers] + 1}]

# Format the header names with links that modify the
# sort order of the SQL query.
#
set table_header_html ""
set url "index?"
set query_string [export_ns_set_vars url [list order_by]]
if { $query_string ne "" } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
set ctr 0
foreach col $column_headers {

    set admin_html [lindex $column_headers_admin $ctr]
    regsub -all " " $col "_" col_text
    if {$order_by eq $col } {
	append table_header_html "<td class=rowtitle>[_ intranet-core.$col_text]$admin_html</td>\n"
    } else {
	append table_header_html "<td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">[_ intranet-core.$col_text]</a>$admin_html</td>\n"
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

db_foreach users $query -bind $form_vars {

    # fraber 160324: "user_id" in the query may be overwritten by users_contact.user_id somehow:
    set user_id $person_id

    # Append together a line of data based on the "column_vars" parameter list
    append table_body_html "<tr$bgcolor([expr {$ctr % 2}])>\n"
    foreach column_var $column_vars {
	append table_body_html "\t<td valign=top>"
	set cmd "append table_body_html $column_var"
        if {[catch {
            eval "$cmd"
        } errmsg]} {
	    global errorInfo
	    ns_log Error "/intranet/users/index: Error evaluating column_var ($column_var): $errorInfo"
	    util_user_message -replace -message "Configuration Error in DynViews - Error evaluating 'column_var', please notify your System Administrator"
        }
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
if { $table_body_html eq "" } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
        [_ intranet-core.lt_There_are_currently_n]
        </b></ul></td></tr>"
}

if { $ctr == $how_many && $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx]
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




# ----------------------------------------------------------
# Do we have to show administration links?
# ---------------------------------------------------------------

ns_log Notice "/intranet/project/index: Before admin links"
set admin_html "<ul>"
set links [im_menu_users_admin_links]
foreach link_entry $links {
    set html ""
    for {set i 0} {$i < [llength $link_entry]} {incr i 2} {
        set name [lindex $link_entry $i]
        set url [lindex $link_entry $i+1]
        append html "<a href='$url'>$name</a>"
    }
    append admin_html "<li>$html</li>\n"
}

append admin_html "</ul>"


# ---------------------------------------------------------------
# 10. Join all parts together
# ---------------------------------------------------------------

set sub_navbar [im_user_navbar $letter "/intranet/users/index" $next_page_url $previous_page_url [list user_group_name] $menu_select_label]


# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate style=tiny-plain-po id="$form_id"></formtemplate>}]
set filter_html $__adp_output


set left_navbar_html "
    <div class=\"filter-block\">
        <div class='filter-title'>
            [_ intranet-core.Filter_Users]
        </div>
        $filter_html
        </div>
"

if {"" ne $admin_html } {
    append left_navbar_html "
              <div class='filter-block'>
                 <div class='filter-title'>
                    [_ intranet-core.Admin_Users]
                 </div>
                 <ul>
                        $admin_html
                 </ul>
              </div>
    "
}

db_release_unused_handles
