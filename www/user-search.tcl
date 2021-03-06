# /packages/intranet-core/www/user-search.tcl
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
    
    Reusable page for searching the users table.
    
    Takes email or last_name as search arguments. 
    Can be constrained with the argument limit_to_users_in_group, 
    which accepts a comma-separated list of group_names.

    Generates a list of matching users and prints the names 
    of the groups searched.

    Each user is a link to $return_url, with user_id, email, last_name, 
    and first_names passed as URL vars. By default these values are 
    passed as user_id_from_search, etc. but the variable names can 
    be set by specifying userid_returnas, etc.
    
    @param email     (search string)
    @param last_name (search strings)
    @param return_url    (URL to return to)
    @param passthrough  (form variables to pass along from caller)
    @param custom_title (if you're doing a passthrough, 
           this title can help inform users for what we searched
    @param limit_to_users_in_group_id (optional, limits our search to
           users in the specified group id. can be a comma separated list.)
    @param subgroups_p t/f - optional. If specified along with
           limit_to_users_in_group_id, searches users who are members of a
           subgroup of the specified group_id
    
    @author philg@mit.edu and authors
    @author frank.bergmann@project-open.com
    @author juanjoruizx@yahoo.es
} {    
    { email "" }
    target
    { last_name "" }
    { passthrough {} }
    { limit_to_users_in_group_id "" }
    { subgroups_p "f" }
    { return_url ""}
    { role_id 0 }
    { also_add_to_group_id "" }
    { object_id "" }
    { notify_asignee "" }
}

# --------------------------------------------------
# Defaults & Security
# --------------------------------------------------

set current_user_id [auth::require_login]
set display_title "Member Search"
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

# --------------------------------------------------
# Check input.
# --------------------------------------------------

set errors ""
set exception_count 0

if { $email eq "" && $last_name eq "" } {
    incr exception_count
    append errors "<li>[_ intranet-core.lt_You_must_specify_eith]"
}

if { $email ne "" && $last_name ne "" } {
    incr exception_count
    append errors "<li>[_ intranet-core.lt_You_can_only_specify_]"
}

if { $return_url eq "" } {
    incr exception_count
    set mail_to_administrator_link "<a href=\"mailto:[ad_host_administrator]\">[_ intranet-core.administrator]</a>"
    append errors "<li>[_ intranet-core.lt_Return_Url_was_not_sp]"
}


if { $exception_count} {
    ad_return_complaint $exception_count $errors
    return
}


# --------------------------------------------------
# Calculate the groups that we can search for the user
# --------------------------------------------------

# No specific group set - search for all groups
if {"" == $limit_to_users_in_group_id} {
    set limit_to_users_in_group_id [db_list all_group_ids "select group_id from groups"]
}


set allowed_groups_sql "
select DISTINCT
        g.group_name,
        g.group_id
from
        acs_objects o,
        groups g,
        all_object_party_privilege_map perm
where
        perm.object_id = g.group_id
        and perm.party_id = :current_user_id
        and perm.privilege = 'read'
        and g.group_id = o.object_id
        and o.object_type = 'im_profile'
"

set allowed_groups [list]
db_foreach allowed_groups $allowed_groups_sql {
    if {[lsearch $limit_to_users_in_group_id $group_id] > -1} {
	lappend allowed_groups $group_id
    }
}


# --------------------------------------------------
# Build the query
# --------------------------------------------------

if { $email ne "" } {
    set query_string "%[string tolower $email]%"
    set search_html "email \"$email\""
    set search_clause "lower(email) like :query_string"
} else {
    set query_string "%[string tolower $last_name]%"
    set search_html "last name \"$last_name\""
    set search_clause "lower(last_name) like :query_string"
}

# No groups found
if {0 == [llength $allowed_groups]} {   
    ad_return_complaint 1 "<LI>[_ intranet-core.lt_None_of_the_specified]"
}

set allowed_group_names [db_list allowed_group_names "select group_name from groups where group_id in ([join $allowed_groups ","])"]

set group_html "in group(s) [join $allowed_group_names ", "]"


# ---------------------------------------------------
# Format the results
# ---------------------------------------------------

set query "
select	u.user_id,
	im_name_from_user_id(u.user_id) as user_name,
	u.email,
	g.group_id
from 
	registered_users u,
	group_distinct_member_map gmm,
	groups g,
	im_profiles p
where 
	gmm.member_id = u.user_id and
	gmm.group_id = g.group_id and
        gmm.group_id > 0 and
	g.group_id = p.profile_id and
	$search_clause
"
db_foreach user_search_query $query {
    set user_name_hash($user_id) $user_name
    set user_email_hash($user_id) $email

    set user_groups [list]
    if {[info exists user_group_hash($user_id)]} { set user_groups $user_group_hash($user_id) }
    lappend user_groups $group_id
    set user_group_hash($user_id) $user_groups
}

set page_contents "
<!--<h2>$display_title</h2>-->
for $search_html $group_html
<br>

<form action=\"$target\">
[export_vars -form {passthrough}]
[export_vars -form $passthrough]
<br>
<table class='table_list'>
	<thead>
 	<tr>
	  <td>[_ intranet-core.Name]</td>
	  <td>[_ intranet-core.Email]</td>
	  <td>[_ intranet-core.Select]</td>
	</tr>
        </thead>
        <tbody>
"

set ctr 0
foreach user_id [array names user_group_hash] {
    set user_name $user_name_hash($user_id)
    set email $user_email_hash($user_id)
    set user_groups $user_group_hash($user_id)

    ns_log Notice "user-search.tcl: user_groups=$user_groups, allowed_groups=$allowed_groups"
    set view_p 1
    foreach gid $user_groups {
	if {[lsearch $allowed_groups $gid] < 0} { 
	    ns_log Notice "user-search.tcl: $gid not in allowed_groups"
	    set view_p 0
	}
    }

    if {$view_p} {
	append page_contents "
	<tr$bgcolor([expr {$ctr % 2}])>
	  <td>$user_name</td>
	  <td>$email</td>
	  <td align=center><input type=radio name=user_id_from_search value=$user_id></td>
	</tr>
        "
	incr ctr
    }
}


if {$ctr > 0} {
    # We need a "submit" button:
    append page_contents "
	</tbody>
        <tfoot>
        <tr>
          <td colspan=2></td>
	  <td><input type=submit value=\"[_ intranet-core.Select]\"></td>
	</tr>
	</tfoot>
"
} else {

    # Show a no-member message
    append page_contents "

        <tr$bgcolor([expr {$ctr % 2}])>
          <td colspan=3>[_ intranet-core.No_members_found]</td>
	</tr>
	</tbody>
"
}

append page_contents "</table>\n"

