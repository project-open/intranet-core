# /www/intranet/users/view.tcl
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

ad_page_contract {
    Display information about one user
    (makes heavy use of procedures in /tcl/ad-user-contributions-summary.tcl)

    @author unknown@arsdigita.com
    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com
} {
    user_id:integer,optional,notnull
    user_id_from_search:integer,optional,notnull
    { view_name "user_view" }
    { contact_view_name "user_contact" }
    { freelance_view_name "user_view_freelance" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set return_url [im_url_with_query]
set td_class(0) "class=roweven"
set td_class(1) "class=rowodd"

# -------------- Group Memberships ----------------

# Also accept "user_id_from_search" instead of user_id (the one to edit...)
if [info exists user_id_from_search] { set user_id $user_id_from_search}
set current_user_id [ad_maybe_redirect_for_registration]

set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set current_user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $current_user_id]
set current_user_is_employee_p [im_user_is_employee_p $current_user_id]
set current_user_admin_p [expr $current_user_is_admin_p || $current_user_is_wheel_p]

set user_is_customer_p [ad_user_group_member [im_customer_group_id] $user_id]
set user_is_freelance_p [ad_user_group_member [im_freelance_group_id] $user_id]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_is_employee_p [im_user_is_employee_p $user_id]

# Determine the type of the user to view:
set user_type "none"
if {$user_is_freelance_p} { set user_type "freelance" }
if {$user_is_employee_p} { set user_type "employee" }
if {$user_is_customer_p} { set user_type "customer" }
if {$user_is_wheel_p} { set user_type "wheel" }
if {$user_is_admin_p} { set user_type "admin" }

set yourself_p [expr $user_id == $current_user_id]

# --------------------------------------------------------
# Determine the list of group memberships of this user
# --------------------------------------------------------

set profile_list [list]

if {[im_site_wide_admin_p $user_id]} {
    lappend profile_list "SiteAdmin"
}

foreach group_id [im_profiles_all_group_ids] {
    if {[ad_user_group_member $group_id $user_id]} {
	lappend profile_list [db_string group_name "select group_name from groups where group_id=:group_id"]
    }
}


# --------------------------------------------------------


# Check if "user" belongs to a group that is administered by 
# the current users
set administrated_user_ids [db_list administated_user_ids "
select distinct
	m2.member_id
from
	group_member_map m,
	group_distinct_member_map m2
where
	m.member_id=:current_user_id
	and m.rel_type='admin_rel'
	and m.group_id=m2.group_id
"]

set user_in_administered_project 0
if {[lsearch -exact $administrated_user_ids $user_id] > -1} { 
    set user_in_administered_project 1
}

# -------------- Permission Matrix ----------------

set view_user 0
set edit_user 0
set show_admin_links $current_user_admin_p

switch $user_type {
    freelance {
	# Check the freelance access rights directy from im_permissions
	set view_user [im_permission $current_user_id view_freelancers]
	set edit_user [im_permission $current_user_id edit_freelancers]
	if {$user_in_administered_project} {set view_user 1}

	# Allows freelance administrators to delete/... 
	if {$edit_user} {set show_admin_links 1}
    }

    employee {
	set view_user [expr $current_user_is_employee_p || $current_user_admin_p]
	set edit_user $current_user_admin_p
	if {$user_in_administered_project} {set view_user 1}
    }

    customer {
	set view_user [im_permission $current_user_id view_customer_contacts]
	set edit_user $current_user_admin_p
	if {$user_in_administered_project} {set view_user 1}
    }

    wheel {
	set view_user [expr $current_user_is_employee_p || $current_user_admin_p]
	set edit_user $current_user_is_admin_p
    }

    admin {
	set view_user [expr $current_user_is_employee_p || $current_user_admin_p]
	set edit_user $current_user_is_admin_p
    }

    none {
	# a user who has registered from the web site
	set view_user [expr $current_user_is_employee_p || $current_user_admin_p]
	set edit_user $current_user_admin_p
    }

    default {
	ad_return_complaint 1" "
        <li>Internal Error: Bad user type<br>
	User \#$user_id does not belong to a known group.<br>
	Please notify your system administrator."
	return
    }
}


# Editing a user implies being able to see it.
if {$edit_user} {
    set view_user 1
}

# Everybody is allowed to see and edit him/herself,
# so skip all security checks if it's yourself.
if {$yourself_p} {
    set view_user 1
    set edit_user 1
}


ns_log Notice "users/view: user_type=$user_type"
ns_log Notice "users/view: yourself_p=$yourself_p"
ns_log Notice "users/view: user_in_administered_project=$user_in_administered_project"
ns_log Notice "users/view: view_user=$view_user"
ns_log Notice "users/view: edit_user=$edit_user"


# Create an error if the current_user isn't allowed to see the user
if {!$view_user} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You have insufficient privileges to view this user."
    return
}


# ---------------------------------------------------------------
# Get everything about the user
# ---------------------------------------------------------------

set result [db_0or1row users_info_query "
select 
	pe.first_names, 
	pe.last_name, 
        pe.first_names||' '||pe.last_name as name,
	pa.email,
        pa.url,
	o.creation_date as registration_date, 
	o.creation_ip as registration_ip,
	u.last_visit,
	u.screen_name
from
	users u,
	acs_objects o,
	parties pa,
	persons pe
where
	u.user_id = :user_id
	and u.user_id=o.object_id(+)
	and u.user_id=pa.party_id(+)
	and u.user_id=pe.person_id(+)
"]

if { $result != 1 } {
    ad_return_complaint "Bad User" "
    <li>We couldn't find user #$user_id; perhaps this person was nuked?"
    return
}


# Set the title now that the $name is available after the db query
set page_title $name
set context_bar [ad_context_bar [list /intranet/users/ "Users"] $page_title]

# ---------------------------------------------------------------
# Show Basic User Information (name & email)
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]

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


set user_basic_info_html "
<form method=POST action=\"/user/basic-info-update\">
[export_form_vars user_id return_url]
<input type=\"hidden\" name=\"form:mode\" value=\"display\" />
<input type=\"hidden\" name=\"form:id\" value=\"user_info\" />

<table cellpadding=1 cellspacing=1 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>Basic Information</td>
  </tr>
"

set ctr 1
db_foreach column_list_sql $column_sql {
    if {[eval $visible_for]} {
	append user_basic_info_html "
        <tr $td_class([expr $ctr % 2])>
          <td>$column_name &nbsp;
        </td><td>"
	set cmd "append user_basic_info_html $column_render_tcl"
	eval $cmd
	append user_basic_info_html "</td></tr>\n"
        incr ctr
    }
}

append user_basic_info_html "
</table>
</form>"

# ---------------------------------------------------------------
# Contact Information
# ---------------------------------------------------------------

set result [db_0or1row users_info_query "
select
	home_phone,
	work_phone,
	cell_phone,
	pager,
	fax,
	aim_screen_name,
	icq_number,
	ha_line1,
	ha_line2,
	ha_city,
	ha_state,
	ha_postal_code,
	ha_country_code,
	wa_line1,
	wa_line2,
	wa_city,
	wa_state,
	wa_postal_code,
	wa_country_code,
	note,
	ha_cc.country_name as ha_country_name,
	wa_cc.country_name as wa_country_name
from
	users_contact c,
        country_codes ha_cc,
        country_codes wa_cc
where
	c.user_id = :user_id
	and c.ha_country_code = ha_cc.iso(+)
	and c.wa_country_code = wa_cc.iso(+)
"]

if {$result == 1} {

    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:contact_view_name"]

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

    set contact_html "
<form method=POST action=contact-edit>
[export_form_vars user_id return_url]
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>Contact Information</td>
  </tr>"

    set ctr 1
    db_foreach column_list_sql $column_sql {
        if {[eval $visible_for]} {
	    append contact_html "
            <tr $td_class([expr $ctr % 2])>
            <td>$column_name &nbsp;</td><td>"
	    set cmd "append contact_html $column_render_tcl"
	    eval $cmd
	    append contact_html "</td></tr>\n"
            incr ctr
        }
    }    
    append contact_html "</table>\n</form>\n"

} else {
    # There is no contact information specified
    # => allow the user to set stuff up. "

    set contact_html "
<form method=POST action=contact-edit>
[export_form_vars user_id return_url]
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>Contact Information</td>
  </tr>
  <tr><td colspan=2>No contact information</td></tr>\n"
    if {$edit_user} {
        append contact_html "
  <tr><td></td><td><input type=submit value='Edit'></td></tr>\n"
    }
    append contact_html "</table></form>\n"
}

# ------------------------------------------------------
# User Project List
# ------------------------------------------------------

set sql "
select
	p.project_id,
	p.project_name,
	p.project_nr,
	level
from
	im_projects p,
	group_distinct_member_map m
where 
	m.member_id=:user_id
	and m.group_id = p.project_id
order by p.project_nr desc
"

set projects_html ""
set current_level 1
set ctr 1
set max_projects 15
db_foreach user_list_projects $sql  {
    ns_log Notice "name=$project_name"
    ns_log Notice "level=$level"

    if { $level > $current_level } {
	append projects_html "  <ul>\n"
	incr current_level
    } elseif { $level < $current_level } {
	append projects_html "  </ul>\n"
	set current_level [expr $current_level - 1]
    }	
    append projects_html "<li>
	<a href=../projects/view?project_id=$project_id>$project_nr $project_name</a>
    "
    incr ctr
    if {$ctr > $max_projects} { break }
}

if { [exists_and_not_null level] && $level < $current_level } {
    append projects_html "  </ul>\n"
}	
if { [empty_string_p $projects_html] } {
    set projects_html "  <li><i>None</i>\n"
}

if {$ctr > $max_projects} {
    append projects_html "<li><A HREF='/intranet/projects/index?user_id_from_search=$user_id&status_id=0'>more projects...</A>\n"
}



if {[im_permission $current_user_id view_projects]} {
    set projects_html [im_table_with_title "Past Projects" $projects_html]
} else {
    set projects_html ""
}


# ---------------------------------------------------------------
# Administration
# ---------------------------------------------------------------

append admin_links "
<table cellpadding=0 cellspacing=2 border=0>
   <tr><td class=rowtitle align=center>User Administration</td></tr>
   <tr><td>
          <ul>\n"

if { ![empty_string_p $last_visit] } {
    append admin_links "<li>Last visit: $last_visit\n"
}

if { [info exists registration_ip] && ![empty_string_p $registration_ip] } {
    append admin_links "<li>Registered from <a href=/admin/host?ip=[ns_urlencode $registration_ip]>$registration_ip</a>\n"
}

# append admin_links "<li> User state: $user_state"

append admin_links "
          <li><a href=/user/password-update?[export_url_vars user_id return_url]>Update this user's password</a>
          <li><a href=become?user_id=$user_id>Become this user!</a>
<!--
          <li>
              <form method=POST action=search>
              <input type=hidden name=u1 value=$user_id>
              <input type=hidden name=target value=/admin/users/merge/merge-from-search.tcl>
              <input type=hidden name=passthrough value=u1>
                  Search for an account to merge with this one: 
 	      <input type=text name=keyword size=20>
              </form>
-->
"

append admin_links "</ul></td></tr>\n"
append admin_links "</table>\n"

if {!$show_admin_links} {
    set admin_links ""
}



# ---------------------------------------------------------------
# User-Navbar
# ---------------------------------------------------------------

set letter "none"
set next_page_url ""
set previous_page_url ""

set user_navbar_html "
<br>
[im_user_navbar $letter "/intranet/users/view" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter]]
"


