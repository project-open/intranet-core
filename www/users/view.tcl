# /packages/intranet-core/www/users/view.tcl
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
    { user_id:integer 0}
    { object_id:integer 0}
    { user_id_from_search 0}
    { view_name "user_view" }
    { contact_view_name "user_contact" }
    { freelance_view_name "user_view_freelance" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set return_url [im_url_with_query]
set current_url $return_url
set td_class(0) "class=roweven"
set td_class(1) "class=rowodd"

# user_id is a bad variable for the object,
# because it is overwritten by SQL queries.
# So first find out which user we are talking
# about...

set vars_set [expr ($user_id > 0) + ($object_id > 0) + ($user_id_from_search > 0)]
if {$vars_set > 1} {
    ad_return_complaint 1 "<li>You have set the user_id in more then one of the following parameters: <br>user_id=$user_id, <br>object_id=$object_id and <br>user_id_from_search=$user_id_from_search."
    return
}
if {$object_id} {set user_id_from_search $object_id}
if {$user_id} {set user_id_from_search $user_id}
if {0 == $user_id} {
    # The "Unregistered Vistior" user
    # Just continue and show his data...
}

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set subsite_id [ad_conn subsite_id]

# Check the permissions 
im_user_permissions $current_user_id $user_id_from_search view read write admin

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
	u.first_names, 
	u.last_name, 
        u.first_names||' '||u.last_name as name,
	u.email,
        u.url,
	u.creation_date as registration_date, 
	u.creation_ip as registration_ip,
	u.last_visit,
	u.screen_name,
	u.member_state
from
	cc_users u
where
	u.user_id = :user_id_from_search
"]

if { $result != 1 } {
    ad_return_complaint "Bad User" "
    <li>We couldn't find user #$user_id_from_search; perhaps this person was nuked?"
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


set user_id $user_id_from_search
set user_basic_info_html "
<form method=POST action=new>
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
    [im_user_profile_component $user_id_from_search "disabled"]
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

set profile_html ""

# ---------------------------------------------------------------
# Contact Information
# ---------------------------------------------------------------

set result [db_0or1row users_info_query "
select
	c.home_phone,
	c.work_phone,
	c.cell_phone,
	c.pager,
	c.fax,
	c.aim_screen_name,
	c.icq_number,
	c.ha_line1,
	c.ha_line2,
	c.ha_city,
	c.ha_state,
	c.ha_postal_code,
	c.ha_country_code,
	c.wa_line1,
	c.wa_line2,
	c.wa_city,
	c.wa_state,
	c.wa_postal_code,
	c.wa_country_code,
	c.note,
	ha_cc.country_name as ha_country_name,
	wa_cc.country_name as wa_country_name
from
	users_contact c,
        country_codes ha_cc,
        country_codes wa_cc
where
	c.user_id = :user_id_from_search
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

    set user_id $user_id_from_search
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

    set user_id $user_id_from_search
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
	p.project_nr
from
	im_projects p,
	acs_rels r
where 
	r.object_id_two = :user_id_from_search
	and r.object_id_one = p.project_id
order by p.project_nr desc
"

set projects_html ""
set ctr 1
set max_projects 15
db_foreach user_list_projects $sql  {
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
    append projects_html "<li><A HREF='/intranet/projects/index?user_id_from_search=$user_id_from_search&status_id=0'>more projects...</A>\n"
}


if {[im_permission $current_user_id view_projects_all]} {
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

set user_id $user_id_from_search
set change_pwd_url "/intranet/users/password-update?[export_url_vars user_id return_url]"

# Return a pretty member state (no normal user understands "banned"...)
case $member_state {
	"banned" { set user_state "inactive" }
	"approved" { set user_state "active" }
	default { set user_state $member_state }
}

append admin_links "
          <li>Member state: $user_state "


if {$current_user_is_admin_p} {
    case $member_state {
	"banned" { 
	    append admin_links "(<a href=/acs-admin/users/member-state-change?member_state=approved&[export_url_vars user_id return_url]>activate</a>)"
	}
	"approved" { 
	    append admin_links "(<a href=/acs-admin/users/member-state-change?member_state=banned&[export_url_vars user_id return_url]>deactivate</a>)"
	}
	default { set user_state $member_state }
    }
}

append admin_links "
          <li><a href=$change_pwd_url>Update this user's password</a>
          <li><a href=become?user_id=$user_id_from_search>Become this user!</a>
<!--
          <li>
              <form method=POST action=search>
              <input type=hidden name=u1 value=$user_id_from_search>
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
# Portrait
# ---------------------------------------------------------------

set subsite_url [subsite::get_element -element url]
set export_vars [export_url_vars user_id return_url]

if {![db_0or1row get_item_id "
select
	live_revision as revision_id, 
	item_id
from 
	acs_rels a, 
	cr_items c
where 
	a.object_id_two = c.item_id
	and a.object_id_one = :user_id_from_search
	and a.rel_type = 'user_portrait_rel'"] 
    || [empty_string_p $revision_id]
} {
    # The user doesn't have a portrait yet
    set portrait_p 0
} else {
    set portrait_p 1
}

if [catch {db_1row get_picture_info "
select 
	i.width, 
	i.height, 
	cr.title, 
	cr.description, 
	cr.publish_date
from 
	images i, 
	cr_revisions cr
where 
	i.image_id = cr.revision_id
	and image_id = :revision_id
"} errmsg] {
    # There was an error obtaining the picture information
    set portrait_p 0
}

# Check if there was a portrait
if {![exists_and_not_null publish_date]} { 
    set portrait_p 0 
}

set portrait_alt "Portrait of $first_names $last_name"

if {$portrait_p} {
    if { ![empty_string_p $width] && ![empty_string_p $height] } {
	set widthheight "width=$width height=$height"
    } else {
	set widthheight ""
    }
    
    set portrait_gif "<img $widthheight src=\"/shared/portrait-bits.tcl?user_id=$user_id_from_search\" alt=\"$portrait_alt\">"

} else {

    set portrait_gif [im_gif anon_portrait $portrait_alt]
    set description "No portrait for <br>\n$first_names $last_name."

    if {$admin} { append description "<br>\nPlease upload a portrait."}
}

set user_id $user_id_from_search
set portrait_admin "
<li><a href=\"/intranet/users/portrait/upload?$export_vars\">Upload portrait</a></li>
<li><a href=\"/intranet/users/portrait/erase?$export_vars\">Delete portrait</a></li>\n"

if {$portrait_p} {
    append portrait_admin "
<li><a href=\"/intranet/users/portrait/comment-edit?$export_vars\">Edit comments about you</a></li>\n"
}


if {!$admin} { set portrait_admin "" }

if {$admin && "" == $description} {
	set description "
No comments about $first_names $last_name.<br>
Please click above to add a short comment.
"
}

set portrait_html "
<table border=0 cellspacing=1 cellpadding=1>
<tr valign=top>
  <td>
    $portrait_gif <br>
  </td>
  <td>
    $portrait_admin <br>
    <blockquote>$description</blockquote>
  </td>
</tr>
</table>
"

set portrait_html [im_table_with_title "Portrait" $portrait_html]


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


