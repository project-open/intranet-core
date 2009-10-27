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

set current_user_id [ad_maybe_redirect_for_registration]
set display_title "Member Search"
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

# --------------------------------------------------
# Check input.
# --------------------------------------------------

set errors ""
set exception_count 0

if { $email == "" && $last_name == "" } {
    incr exception_count
    append errors "<li>[_ intranet-core.lt_You_must_specify_eith]"
}

if { $email != "" && $last_name != "" } {
    incr exception_count
    append errors "<li>[_ intranet-core.lt_You_can_only_specify_]"
}

if { $return_url == "" } {
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

set limit_to_groups [list]

set profile_sql "
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


db_foreach profile_list $profile_sql {
    lappend limit_to_groups $group_id
}
set limit_to_users_in_group_id [join $limit_to_groups ","]
ns_log Notice "limit_to_users_in_group_id=$limit_to_users_in_group_id"


# --------------------------------------------------
# Build the query
# --------------------------------------------------

if { $email != "" } {
    set query_string "%[string tolower $email]%"
    set search_html "email \"$email\""
    set search_clause "lower(email) like :query_string"
} else {
    set query_string "%[string tolower $last_name]%"
    set search_html "last name \"$last_name\""
    set search_clause "lower(last_name) like :query_string"
}


### build the search query
if { ![empty_string_p $limit_to_users_in_group_id] } {    


    ## Retrieve the names of specified groups -MJS 7/28
    set group_list [db_list groups "select group_name from groups where group_id in ($limit_to_users_in_group_id)"]    
    
    if {[empty_string_p [lindex $group_list 0]]} {
	
	## No group names found - return
	set errors "<LI>[_ intranet-core.lt_None_of_the_specified]"
	ad_return_complaint 1 $errors
	return

    } else {

	## Group name/s found
	
	if {[empty_string_p [lindex $group_list 1]] } {

	    ## Only one group found

	    set group_html "in group [lindex $group_list 0]"

	} else {

	    ## Multiple groups found

	    set group_html "in groups [join $group_list ", "]"

	}	

	# Let's build up the groups sql query we need. Only include
	# the user_groups table if we need to include members 
	# of subgroups.
	if { [string compare $subgroups_p "t"] == 0 } {
	    # Include subgroups - set some text to tell the user we are looking in subgroups
	    append group_html " and any of its subgroups"
	    
	    set group_table ", user_groups ug"
	    set group_sql "ug.group_id = ugm.group_id and (ugm.group_id in ($limit_to_users_in_group_id) or ug.parent_group_id in ($limit_to_users_in_group_id))"
	} else {
	    set group_table ""
	    set group_sql "ugm.group_id in ($limit_to_users_in_group_id)"
	}

    }

    
    # Need the distinct for the join with user_group_map
    set query "
select distinct
	u.user_id,
	im_name_from_user_id(user_id) as user_name,
	u.email
from 
	registered_users u,
	group_member_map ugm,
	membership_rels mr
	$group_table
where 
	u.user_id=ugm.member_id
	and ugm.rel_id = mr.rel_id
	and mr.member_state = 'approved'
	and $group_sql
	and $search_clause
"

} else {
    
    ## No groups specified

    set group_html "in all groups"

    set query "
select 
	u.user_id,
	im_name_from_user_id(user_id) as user_name,
	pa.email,
from 
	users u,
	persons p,
	parties pa
where
	u.user_id = p.person_id
	and u.user_id = pa.party_id
	$search_clause"
}


# ---------------------------------------------------
# Format the Selection Table
# ---------------------------------------------------

set ctr 0

set page_contents "
<!--<h2>$display_title</h2>-->
for $search_html $group_html
<br>

<form action=\"$target\">
[export_form_vars passthrough]
"

foreach var $passthrough {
    append page_contents "[export_form_vars $var]\n"
}


append page_contents "

<br><!--<h3>[_ intranet-core.Freelance]</h3>-->
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

db_foreach user_search_query $query {

    append page_contents "

	<tr$bgcolor([expr $ctr % 2])>
	  <td>$user_name</td>
	  <td>$email</td>
	  <td align=center><input type=radio name=user_id_from_search value=$user_id></td>
	</tr>\n"
    incr ctr
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

        <tr$bgcolor([expr $ctr % 2])>
          <td colspan=3>[_ intranet-core.No_members_found]</td>
	</tr>
	</tbody>
"
}

append page_contents "</table>\n"

