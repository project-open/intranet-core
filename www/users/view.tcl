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

set current_user_id [ad_maybe_redirect_for_registration]

set package_id [ad_conn package_id]
set package_id 400

# Check the permissions that the current_user has on user_id
im_user_permissions $current_user_id $user_id read write admin

# ToDo: Cleanup component to use $write instead of $edit_user
set edit_user $write

if {!$read} {
    ad_return_complaint 1 "<li>You have insufficient privileges to view this user."
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


set ttt "
<input type=\"hidden\" name=\"form:mode\" value=\"display\" />
<input type=\"hidden\" name=\"form:id\" value=\"user_info\" />
"

set user_basic_info_html "
<form method=GET action=new>
[export_form_vars user_id return_url]

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
"

# ---------------------------------------------------------------
# Profile Management
# ---------------------------------------------------------------

append user_basic_info_html "
<tr $td_class([expr $ctr % 2])>
  <td>Profile</td>
  <td>
    [im_user_profile_component $user_id "disabled"]
  </td>
</tr>
<tr>
  <td></td>
  <td>\n"
if {$write} {
    append user_basic_info_html "
    <input type=submit value=Edit>\n"
}
append user_basic_info_html "
  </td>
</tr>
</table>
</form>\n"

set ttt "
<form method=POST action=profile-update>
[export_form_vars user_id return_url]

<table cellspacing=1 cellpadding=1>
<tr><td align=center class=rowtitle>Profiles</td></tr>
</table>
</form>
"

set profile_html ""

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
    if {$write} {
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

if {!$admin} {
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


