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

set date_format "YYYY-MM-DD"

# user_id is a bad variable for the object,
# because it is overwritten by SQL queries.
# So first find out which user we are talking
# about...

if {"" == $user_id} { set user_id 0 }
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
set subsite_id [ad_conn subsite_id]

# Check the permissions 
im_user_permissions $current_user_id $user_id_from_search view read write admin

# ToDo: Cleanup component to use $write instead of $edit_user
set edit_user $write

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
    return
}

# ---------------------------------------------------------------
# Get everything about the user
# ---------------------------------------------------------------

set result [db_0or1row users_info_query "
select 
	u.first_names, 
	u.last_name, 
        im_name_from_user_id(u.user_id) as name,
	u.email,
        u.url,
	u.creation_date as registration_date, 
	u.creation_ip as registration_ip,
	to_char(u.last_visit, :date_format) as last_visit,
	u.screen_name,
	u.username,
	u.member_state,
	u.creation_user as creation_user_id,
	im_name_from_user_id(u.creation_user) as creation_user_name
from
	cc_users u
where
	u.user_id = :user_id_from_search
"]

if { $result > 1 } {
    ad_return_complaint "[_ intranet-core.Bad_User]" "
    <li>There is more then one user with the ID $user_id_from_search"
    return
}

if { $result == 0 } {

    set party_id [db_string party "select party_id from parties where party_id=:user_id_from_search" -default 0]
    set person_id [db_string person "select person_id from persons where person_id=:user_id_from_search" -default 0]
    set user_id [db_string user "select user_id from users where user_id=:user_id_from_search" -default 0]
    set object_type [db_string object_type "select object_type from acs_objects where object_id=:user_id_from_search" -default "unknown"]

    ad_return_complaint "[_ intranet-core.Bad_User]" "
    <li>[_ intranet-core.lt_We_couldnt_find_user_]
    <li>You can 
	<a href='/intranet/users/new?user_id=$user_id_from_search'>try to create this user</a>
    now.
    "
    return
}


# Set the title now that the $name is available after the db query
set page_title $name
set context_bar [im_context_bar [list /intranet/users/ "[_ intranet-core.Users]"] $page_title]

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
set user_basic_info_vars [export_form_vars user_id return_url]
set user_basic_info_html "
  <tr> 
    <td colspan=2 class=rowtitle align=center>[_ intranet-core.Basic_Information]</td>
  </tr>
"

set ctr 1
db_foreach column_list_sql $column_sql {
    if {"" == $visible_for || [eval $visible_for]} {

	append user_basic_info_html "<tr $td_class([expr $ctr % 2])><td>"
	set cmd0 "append user_basic_info_html $column_name"
	eval "$cmd0"
	append user_basic_info_html " &nbsp;</td><td>"
	set cmd "append user_basic_info_html $column_render_tcl"
	eval "$cmd"
	append user_basic_info_html "</td></tr>\n"
        incr ctr

    }
}


# ---------------------------------------------------------------
# Profile Management
# ---------------------------------------------------------------

set user_basic_profile_html "
	<tr $td_class([expr $ctr % 2])>
	  <td>[_ intranet-core.Profile]</td>
	  <td>
	    [im_user_profile_component $user_id_from_search "disabled"]
	  </td>
	</tr>
"

set user_basic_edit_html ""
if {$write} {
    set user_basic_edit_html "
	<tr>
	  <td colspan=2 align=center>
	    <form method=POST action=new>
	    $user_basic_info_vars
	    <input type=\"submit\" value=\"[_ intranet-core.Edit]\">
	    </form>
	  </td>
	</tr>
    "
}

# ------------------------------------------------------
# Show extension fields
# ------------------------------------------------------

set object_type "person"
set form_id "person_view"
set action_url "/intranet/users/new"
set form_mode "display"
set user_id $user_id_from_search

set ttt {
ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {user_id return_url}
}

template::form create $form_id \
    -mode "display" \
    -display_buttons { }

im_dynfield::append_attributes_to_form \
    -object_type $object_type \
    -form_id $form_id \
    -object_id $user_id_from_search \
    -form_display_mode "display"


 


# ---------------------------------------------------------------
# Localization Information
# ---------------------------------------------------------------

set site_wide_locale [lang::user::locale]
set use_timezone_p [expr [lang::system::timezone_support_p] && [ad_conn user_id]]

if {"" == $site_wide_locale} { set site_wide_locale "en_US" }

set user_l10n_html "
<form method=POST action=edit-locale>
[export_form_vars user_id]

<table cellpadding=1 cellspacing=1 border=0>
<tr>
  <td colspan=2 class=rowtitle align=center>
    [_ intranet-core.Localization]
  </td>
</tr>
<tr class=rowodd>
  <td>[_ intranet-core.Your_Current_Locale]</td>
  <td>$site_wide_locale</td>
</tr>
"

if { $use_timezone_p } {
    set timezone [lang::user::timezone]

    append user_l10n_html "
<tr class=roweven>
  <td>[_ intranet-core.Your_Current_Timezone]</td>
  <td>$timezone</td>
</tr>
"
}

append user_l10n_html "
<tr>
  <td colspan=99 align=right>
    <input type=submit value='[_ intranet-core.Edit]'>
  </td>
</tr>
</table>
</form>
"

if {!$write} { set user_l10n_html "" }

# ---------------------------------------------------------------
# Contact Information
# ---------------------------------------------------------------

set ha_country_code ""
set wa_country_code ""

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
	c.note
from
	users_contact c
where
	c.user_id = :user_id_from_search
"]

# Get CCs outside of main select to avoid outer joins...
set ha_country_name [db_string ha_country_name "select country_name from country_codes where iso=:ha_country_code" -default ""]
set wa_country_name [db_string wa_country_name "select country_name from country_codes where iso=:wa_country_code" -default ""]


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
    <td colspan=2 class=rowtitle align=center>[_ intranet-core.Contact_Information]</td>
  </tr>"

    set ctr 1
    db_foreach column_list_sql $column_sql {
        if {"" == $visible_for || [eval $visible_for]} {
	    append contact_html "
            <tr $td_class([expr $ctr % 2])>
            <td>"
            set cmd0 "append contact_html $column_name"
            eval "$cmd0"
            append contact_html " &nbsp;</td><td>"
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
    <td colspan=2 class=rowtitle align=center>[_ intranet-core.Contact_Information]</td>
  </tr>
  <tr><td colspan=2>[_ intranet-core.lt_No_contact_informatio]</td></tr>\n"
    if {$write} {
        append contact_html "
  <tr><td></td><td><input type=submit value='[_ intranet-core.Edit]'></td></tr>\n"
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
	and p.parent_id is null
	and p.project_status_id not in ([im_project_status_deleted])
order by p.project_nr desc
"

set projects_html ""
set ctr 1
set max_projects 10
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
    set projects_html "  <li><i>[_ intranet-core.None]</i>\n"
}

if {$ctr > $max_projects} {
    append projects_html "<li><A HREF='/intranet/projects/index?user_id_from_search=$user_id_from_search&status_id=0'>[_ intranet-core.more_projects]</A>\n"
}


if {[im_permission $current_user_id view_projects_all]} {
    set projects_html [im_table_with_title "[_ intranet-core.Past_Projects]" $projects_html]
} else {
    set projects_html ""
}

# ------------------------------------------------------
# User Company List
# ------------------------------------------------------

set companies_sql "
select
	c.company_id,
	c.company_name
from
	im_companies c,
	acs_rels r
where 
	r.object_id_two = :user_id_from_search
	and r.object_id_one = c.company_id
order by c.company_name desc
"

set companies_html ""
set ctr 1
set max_companies 10
db_foreach user_list_companies $companies_sql  {
    append companies_html "<li>
	<a href=../companies/view?company_id=$company_id>$company_name</a>
    "
    incr ctr
    if {$ctr > $max_companies} { break }
}

if { [empty_string_p $companies_html] } {
    set companies_html "  <li><i>[_ intranet-core.None]</i>\n"
}

if {$ctr > $max_companies} {
    set status_id 0
    set type_id 0
    append companies_html "<li><A HREF='/intranet/companies/index?[export_url_vars user_id_from_search status_id type_id]'>[_ intranet-core.more_companies]</A>\n"
}

if {[im_permission $current_user_id view_companies_all]} {
    set companies_html [im_table_with_title "[_ intranet-core.Companies]" $companies_html]
} else {
    set companies_html ""
}


# ---------------------------------------------------------------
# Administration
# ---------------------------------------------------------------

append admin_links "
<table cellpadding=0 cellspacing=2 border=0>
   <tr><td class=rowtitle align=center>[_ intranet-core.User_Administration]</td></tr>
   <tr><td>
          <ul>\n"

if { ![empty_string_p $last_visit] } {
    append admin_links "<li>[_ intranet-core.Last_visit]: $last_visit\n"
}

if { [info exists registration_ip] && ![empty_string_p $registration_ip] } {
    set registration_ip_link "<a href=/intranet/admin/host?ip=[ns_urlencode $registration_ip]>$registration_ip</a>"
    append admin_links "<li>[_ intranet-core.lt_Registered_from_regis] by <a href=/intranet/users/view?user_id=$creation_user_id>$creation_user_name</a>"
}

set user_id $user_id_from_search

# Return a pretty member state (no normal user understands "banned"...)
case $member_state {
	"banned" { set user_state "deleted" }
	"approved" { set user_state "active" }
	default { set user_state $member_state }
}

set activate_link "<a href=/acs-admin/users/member-state-change?member_state=approved&[export_url_vars user_id return_url]>[_ intranet-core.activate]</a>"
set delete_link "<a href=/acs-admin/users/member-state-change?member_state=banned&[export_url_vars user_id return_url]>[_ intranet-core.delete]</a>"


if {$admin} {
    append admin_links "<li>[_ intranet-core.lt_Member_state_user_sta]"
} else {
    append admin_links "<li>[_ intranet-core.User_state]: $user_state"
}

set change_pwd_url "/intranet/users/password-update?[export_url_vars user_id return_url]"
set new_company_from_user_url [export_vars -base "/intranet/companies/new-company-from-user" {{user_id $user_id_from_search}}]

if {$admin || $user_id == $current_user_id} {
    append admin_links "
          <li><a href=$change_pwd_url>[_ intranet-core.lt_Update_this_users_pas]</a>\n"
}

# Check if there is a OTP (one time password) module installed
set otp_installed_p [db_string otp_installed "
        select count(*)
        from apm_enabled_package_versions
        where package_key = 'intranet-otp'
" -default 0]

if {$otp_installed_p} {
    set list_otp_pwd_base_url "/intranet-otp/list-otps"
    set list_otp_pwd_url [export_vars -base $list_otp_pwd_base_url {user_id {return_url $current_url}}]
    append admin_links "
        <li><a href=\"$list_otp_pwd_url\"
	>[lang::message::lookup "" intranet-otp.Print_OTP_list "Manage this user's OTP (one time password) list"]</a>
    "
}

if {$admin && [im_permission $current_user_id add_companies]} {

    append admin_links "
          <li><a href=$new_company_from_user_url>[lang::message::lookup "" intranet-core.Create_New_Company_for_User "Create New Company for this User"]</a>\n"
}

if {$admin} {
    append admin_links "
          <li><a href=become?user_id=$user_id_from_search>[_ intranet-core.Become_this_user]</a>
<!--          <li><a href=nuke?user_id=$user_id_from_search&return_url=[ns_urlencode $return_url]>[_ intranet-core.Nuke_this_user]</a> -->
    "
}


append admin_links "</ul></td></tr>\n"
append admin_links "</table>\n"


# ---------------------------------------------------------------
# Portrait
# ---------------------------------------------------------------

set portrait_html [im_portrait_component $user_id_from_search $return_url $read $write $admin]
set portrait_html [im_table_with_title "[_ intranet-core.Portrait]" $portrait_html]
# set portrait_html ""

# ---------------------------------------------------------------
# User-Navbar
# ---------------------------------------------------------------

set letter "none"
set next_page_url ""
set previous_page_url ""

set user_navbar_html [im_user_navbar $letter "/intranet/users/view" $next_page_url $previous_page_url [list start_idx order_by how_many view_name letter]]


