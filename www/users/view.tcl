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
    { view_name "" }
    { contact_view_name "user_contact" }
    { freelance_view_name "user_view_freelance" }
    { plugin_id:integer 0 }
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
    ad_script_abort
}
if {$object_id} {set user_id_from_search $object_id}
if {$user_id} {set user_id_from_search $user_id}
if {0 == $user_id} {
    # The "Unregistered Vistior" user does not have valid data
    ad_return_complaint 1 "User 'Unregistered Visitor' is a system user and can not be viewed or modified."
}

set current_user_id [auth::require_login]
set subsite_id [ad_conn subsite_id]

# Check the permissions 
im_user_permissions $current_user_id $user_id_from_search view read write admin

# ToDo: Cleanup component to use $write instead of $edit_user
set edit_user $write

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
    ad_script_abort
}


# ---------------------------------------------------------------
# Get everything about the user
# ---------------------------------------------------------------

set result [db_0or1row users_info_query "
select 
	pe.first_names, 
	pe.last_name, 
        im_name_from_user_id(u.user_id) as name,
	pa.email,
        pa.url,
	o.creation_date as registration_date, 
	o.creation_ip as registration_ip,
	to_char(u.last_visit, :date_format) as last_visit,
	u.screen_name,
	u.username,
	(select member_state from membership_rels where rel_id in (
		select rel_id from acs_rels where object_id_two = u.user_id and object_id_one = -2
	)) as member_state,
	o.creation_user as creation_user_id,
	im_name_from_user_id(o.creation_user) as creation_user_name,
	auth.short_name as authority_short_name,
	auth.pretty_name as authority_pretty_name
from	acs_objects o,
	persons pe,
	parties pa,
	users u
	LEFT OUTER JOIN auth_authorities auth ON (u.authority_id = auth.authority_id)
where	u.user_id = :user_id_from_search and
	u.user_id = pe.person_id and
	u.user_id = pa.party_id and
	u.user_id = o.object_id
"]

if {$result > 1} {
    ad_return_complaint 1 "<b>[_ intranet-core.Bad_User]</b>:<br>
    <li>There is more then one user with the ID $user_id_from_search"
    ad_script_abort
}

if {$result == 0} {
    set party_id [db_string party "select party_id from parties where party_id=:user_id_from_search" -default 0]
    set person_id [db_string person "select person_id from persons where person_id=:user_id_from_search" -default 0]
    set user_id [db_string user "select user_id from users where user_id=:user_id_from_search" -default 0]
    set object_type [db_string object_type "select object_type from acs_objects where object_id=:user_id_from_search" -default "unknown"]

    ad_return_complaint 1 "<b>[_ intranet-core.Bad_User]</b>:<br>[_ intranet-core.lt_We_couldnt_find_user_]"
    ad_script_abort
}


# Set the title now that the $name is available after the db query
set page_title "[_ intranet-core.User] $name"
set context_bar [im_context_bar [list /intranet/users/ "[_ intranet-core.Users]"] $page_title]


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
	and p.project_type_id not in ([im_project_type_task], [im_project_type_ticket])
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

if { ([info exists level] && $level ne "") && $level < $current_level } {
    append projects_html "  </ul>\n"
}	
if { $projects_html eq "" } {
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

if { $companies_html eq "" } {
    set companies_html "  <li><i>[_ intranet-core.None]</i>\n"
}

if {$ctr > $max_companies} {
    set status_id 0
    set type_id 0
    append companies_html "<li><A HREF='/intranet/companies/[export_vars -base index { user_id_from_search status_id type_id}]'>[_ intranet-core.more_companies]</A>\n"
}

if {[im_permission $current_user_id view_companies_all]} {
    set companies_html [im_table_with_title "[_ intranet-core.Companies]" $companies_html]
} else {
    set companies_html ""
}



# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars user_id $user_id
set parent_menu_id [im_menu_id_from_label "user_page"]
set menu_label "user_summary"
set show_context_help_p 1

set user_navbar_html [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url "/intranet/users/view?user_id=$user_id" \
    -plugin_url "/intranet/users/view" \
    $parent_menu_id \
    $bind_vars "" "pagedesriptionbar" $menu_label \
] 

set left_navbar_html ""

