# /packages/intranet-core/tcl/intranet-permissions-procs.tcl
#
# Copyright (C) 2004 various authors
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

ad_library {
    Project/Open specific permissions routines.
    The P/O permission model is based on the OpenACS model,
    extending it by several concepts:

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
}


ad_proc -public im_biz_object_member_p { user_id object_id } {
    Returns >0 if the user has some type of relationship with
    the specified object.
} {
    set sql "
	select count(*)
	from acs_rels
	where	object_id_one=:object_id
		and object_id_two=:user_id
"
    set result [db_string im_biz_object_member_p $sql]
    return $result
}

ad_proc -public im_biz_object_admin_p { user_id object_id } {
    Returns >0 if the user is a PM of a project or a Key
    Account of a customer
    the specified object.
} {
    set sql "
select	count(*)
from 
	acs_rels r,
	im_biz_object_members m
where
	r.object_id_one=:object_id
	and r.object_id_two=:user_id
	and r.rel_id = m.rel_id
	and m.object_role_id in (1301,1302,1303)
"
    # 1301=PM, 1302=Key Account, 1303=Office Man.

    set result [db_string im_biz_object_member_p $sql]
    return $result
}

ad_proc -public im_biz_object_admin_ids { object_id } {
    Returns the list of administrators of the specified object_id
} {
    set sql "
select	object_id_two
from 
	acs_rels r,
	im_biz_object_members m
where
	r.object_id_one=:object_id
	and r.rel_id = m.rel_id
	and m.object_role_id in (1301,1302,1303)
"
    # 1301=PM, 1302=Key Account, 1303=Office Man.

    set result [db_list im_biz_object_admin_ids $sql]
    return $result
}

ad_proc -public im_biz_object_member_ids { object_id } {
    Returns the list of members of the specified object_id
} {
    set sql "
select	object_id_two
from 
	acs_rels r,
where
	r.object_id_one=:object_id
"
    set result [db_list im_biz_object_member_ids $sql]
    return $result
}

ad_proc -public im_biz_object_member_ids { user_id object_id } {
    Returns the list of acs_rel_ids that the user has 
    with the specified object.
} {
    set sql "
	select rel_id
	from acs_rels
	where	object_id_one=:object_id
		and object_id_two=:user_id
"
    set result [db_list im_biz_object_member_ids $sql]
    return $result
}

ad_proc -public im_biz_object_role_ids { user_id object_id } {
    Returns the list of "biz-object"-role IDs that the user has 
    with the specified object.<br>
} {
    set sql "
	select distinct
		m.object_role_id
	from
		acs_rels r,
		im_biz_object_members m
	where
		r.object_id_one=:object_id
		and r.object_id_two=:user_id
		and r.rel_id = m.rel_id
"
    set result [db_list im_biz_object_roles $sql]
    return $result
}

ad_proc -public im_biz_object_roles { user_id object_id } {
    Returns the list of "biz-object"-roles that the user has 
    with the specified object.<br>
    For example, this procedure could return {Developer PM}
    as the roles(!) of a specific user in a project or
    {Key Account} for the roles in a customer.
} {
    set sql "
	select distinct
		im_category_from_id(m.object_role_id)
	from
		acs_rels r,
		im_biz_object_members m
	where
		r.object_id_one=:object_id
		and r.object_id_two=:user_id
		and r.rel_id = m.rel_id
"
    set result [db_list im_biz_object_roles $sql]
    return $result
}

ad_proc -public im_biz_object_add_role { user_id object_id role_id } {
    Adds a user in a role to a Business Object.
} {
    # Remove all previous member_rels between user ans object
    set sql "
    begin
	for row in (
        	select
			object_id_one as object_id,
			object_id_two as user_id
        	from 
			acs_rels r
        	where	r.object_id_one=:object_id 
			and r.object_id_two=:user_id
	) loop
		im_biz_object_member.del(row.object_id, row.user_id);
   	end loop;
    end;
"    
    db_exec_plsql del_users $sql

    # Add the user
    set sql "
	begin
	    :1 := im_biz_object_member.new(
		object_id	=> :object_id,
		user_id 	=> :user_id,
		object_role_id	=> :role_id
	    );
	end; "
    db_exec_plsql add_user $sql
}


ad_proc -public im_biz_object_roles_select { select_name object_id { default "" } } {
    A common drop-down box to select the available roles for 
    users to be assigned to the object.<br>
    Returns an html select box named $select_name and defaulted to
    $default with a list of all available roles for this object.
} {
    set bind_vars [ns_set create]
    set acs_object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
    ns_set put $bind_vars acs_object_type $acs_object_type

    set sql "
select distinct
	r.object_role_id,
        im_category_from_id(r.object_role_id)
from
        im_biz_object_role_map r
where
        r.acs_object_type = :acs_object_type
"
    
#    set role_options_extra_sql "and r.object_type_id = im_biz_object.type(:object_id)"


    return [im_selection_to_select_box $bind_vars "project_member_select" $sql $select_name $default]
}

# --------------------------------------------------------------
# Show the members of the Admin Group of the current Business Object.
# --------------------------------------------------------------
#
# set company_members [im_group_member_component $customer_id $user_id $user_admin_p $return_url [im_employee_group_id]]


ad_proc -public im_group_member_component { object_id current_user_id { add_admin_links 0 } { return_url "" } { limit_to_users_in_group_id "" } { dont_allow_users_in_group_id "" } {also_add_to_group_id "" } } {

    Returns an html formatted list of all the users in the specified
    group. 

    Required Arguments:
    -------------------
    - object_id: Group we're interested in.
    - current_user_id: The user_id of the person viewing the page that
      called this function. 

    Optional Arguments:
    -------------------
    - description: A description of the group. We use pass this to the
      spam function for UI
    - add_admin_links: Boolean. If 1, we add links to add/email
      people. Current user must be member of the specified object_id to add
      him/herself
    - return_url: Where to go after we do something like add a user
    - limit_to_users_in_group_id: Only shows users who belong to
      group_id and who are also members of the group specified in
      limit_to_users_in_group_id. For example, if object_id is an intranet
      project, and limit_to_users_group_id is the object_id of the employees
      group, we only display users who are members of both the employees and
      this project groups
    - dont_allow_users_in_group_id: Similar to
      limit_to_users_in_group_id, but says that if a user belongs to the
      object_id specified by dont_allow_users_in_group_id, then don't display
      that user.  
    - also_add_to_group_id: If we're adding users to a group, we might
      also want to add them to another group at the same time. If you set
      also _add_to_group_id to a object_id, the user will be added first to
      object_id, then to also_add_to_group_id. Note that adding the person to
      both groups is NOT atomic.

    Notes:
    -------------------
    This function has quickly become complicated. Any proposals to simplify
    are welcome...

} {

    # ------------------ limit_to_users_in_group_id ---------------------
    if { [empty_string_p $limit_to_users_in_group_id] } {
	set limit_to_group_id_sql ""
    } else {
	set limit_to_group_id_sql "
and exists (select 1 
	from 
		group_member_map map2,
		groups ug
	where 
		map2.group_id = ug.group_id
		and map2.member_id = u.user_id 
		and map2.group_id = :limit_to_users_in_group_id
	)
"
    } 

    # ------------------ dont_allow_users_in_group_id ---------------------
    if { [empty_string_p $dont_allow_users_in_group_id] } {
	set dont_allow_sql ""
    } else {
	set dont_allow_sql "
and not exists (
	select 1 
	from 
		group_member_map map2, 
		groups ug
	where 
		map2.group_id = ug.group_id
		and map2.member_id = u.user_id 
		and map2.group_id = :dont_allow_users_in_group_id
	)
"
    } 

    # ------------------ Main SQL ----------------------------------------
    # fraber: Abolished the "distinct" because the role assignment page 
    # now takes care that a user is assigned only once to a group.
    # We neeed this if we want to show the role of the user.
    #
    set sql_query "
select
	u.user_id, 
	im_email_from_user_id(u.user_id) as email,
	im_name_from_user_id(u.user_id) as name,
	im_category_from_id(c.category_id) as member_role,
	c.category_gif as role_gif,
	c.category_description as role_description
from
	users u,
	acs_rels rels,
	im_biz_object_members bo_rels,
	im_categories c
where
	rels.object_id_one = :object_id
	and rels.object_id_two = u.user_id
	and rels.rel_id = bo_rels.rel_id
	and bo_rels.object_role_id = c.category_id
	$limit_to_group_id_sql 
	$dont_allow_sql
order by lower(name)"


    # ------------------ Format the table header ------------------------
    set colspan 1
    set header_html "
      <tr> 
	<td class=rowtitle align=middle>Name</td>"
if {$add_admin_links} {
    incr colspan
    append header_html "
	<td class=rowtitle align=middle>[im_gif delete]</td>"
}
    append header_html "
      </tr>"

    # ------------------ Format the table body ----------------
    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"
    set found 0
    set count 0
    set body_html ""
    db_foreach users_in_group $sql_query {

	# Make up a GIF with ALT text to explain the role (Member, Key 
	# Account, ...
	set descr $role_description
	if {"" == $descr} { set descr $member_role }
	set profile_gif [im_gif $role_gif $descr]

	incr count
	if { $current_user_id == $user_id } { set found 1 }

	# determine how to show the user: 
	# -1: Show name only, 0: don't show, 1:Show link
	set show_user [im_show_user_style $user_id $current_user_id $object_id]
	ns_log Notice "im_group_member_component: user_id=$user_id, show_user=$show_user"

	if {$show_user == 0} { continue }

	append body_html "
<tr $td_class([expr $count % 2])>
  <input type=hidden name=member_id value=$user_id>
  <td>"
	if {$show_user > 0} {
append body_html "<A HREF=/intranet/users/view?user_id=$user_id>$name</A>"
	} else {
append body_html $name
	}

	append body_html "$profile_gif</td>"
	if {$add_admin_links} {
	    append body_html "
  <td align=middle>
    <input type=checkbox name=delete_user value=$user_id>
  </td>"
	}
	append body_html "</tr>"
    }

    if { [empty_string_p $body_html] } {
	set body_html "<tr><td colspan=$colspan><i>none</i></td></tr>\n"
    }


    # ------------------ Format the table footer with buttons ------------
    set footer_html ""
    if {$add_admin_links} {
	append footer_html "
    <tr>
      <td align=right>
	<A HREF=/intranet/member-add?[export_url_vars object_id also_add_to_group_id return_url]>
	  Add member</A>&nbsp;
      </td>"
	append footer_html "
      <td><input type=submit value=Del name=submit></td>
      </td>
    </tr>"
}

    # ------------------ Join table header, body and footer ----------------
    set html "
<form method=POST action=/intranet/member-update>
[export_form_vars object_id return_url]
    <table bgcolor=white cellpadding=1 cellspacing=1 border=0>
      $header_html
      $body_html
      $footer_html
    </table>
</form>
"
    return $html
}


ad_proc -public im_project_add_member { object_id user_id role} {
    Make a specified user a member of a (project) group
} {
    
    db_transaction {
	db_exec_plsql insert_user_group_map "
begin
  user_group_member_add(:object_id, :user_id, :role);
end;
"
    }
    
    # Second, add an empty "estimations" field that is necessary
    # for every project group member.
#    set sql "
#	insert into user_group_member_field_map values
#	(:object_id, :user_id, 'estimation_days', '')"	
#    db_transaction {
#	db_dml insert_user_member_field_map $sql
#    }

    db_release_unused_handles
}




