# /packages/intranet-core/tcl/intranet-user-procs.tcl
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

# @author various@arsdigita.com
# @author frank.bergmann@project-open.com


ad_proc -public im_user_permissions { current_user_id user_id view_var read_var write_var admin_var } {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $current_user_id on $user_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 1
    set read 1
    set write 1
    set admin 1

    # Myself - I can do everything with my personal data
    if { $user_id == $current_user_id } { return }

    # Get the list of profiles of user_id (the one to be managed)
    # together with the information if current_user_id can read/write
    # it.
    # m.group_id are all the groups to whom user_id belongs
    set profile_perm_sql "
select
	m.group_id,
	acs_permission.permission_p(m.group_id, :current_user_id, 'view') as view_p,
	acs_permission.permission_p(m.group_id, :current_user_id, 'read') as read_p,
	acs_permission.permission_p(m.group_id, :current_user_id, 'write') as write_p,
	acs_permission.permission_p(m.group_id, :current_user_id, 'admin') as admin_p
from
	acs_objects o,
	group_distinct_member_map m
where
	m.member_id=:user_id
     	and m.group_id = o.object_id
	and o.object_type = 'im_profile'
"
    db_foreach profile_perm_check $profile_perm_sql {
	ns_log Notice "im_user_permissions: $group_id: view=$view_p read=$read_p write=$write_p admin=$admin_p"
	if {[string equal f $view_p]} { set view 0 }
	if {[string equal f $read_p]} { set read 0 }
	if {[string equal f $write_p]} { set write 0 }
	if {[string equal f $admin_p]} { set admin 0 }
    }

    if {$admin} {
	set read 1
	set write 1
    }
    if {$read} { set view 1 }

    ns_log Notice "im_user_permissions: cur=$current_user_id, user=$user_id, view=$view, read=$read, write=$write, admin=$admin"

}

ad_proc im_random_employee_blurb { } "Returns a random employee's photograph and a little bio" {

return ""

    # Get the current user id to not show the current user's portrait
    set current_user_id [ad_get_user_id]

    # How many photos are there?
    set number_photos [db_string number_employees_with_photos {
	select count(emp.user_id)
	  from im_employees_active emp, general_portraits  gp
 	 where emp.user_id <> :current_user_id
	   and emp.user_id = gp.on_what_id
	   and gp.on_which_table = 'USERS'
	   and gp.approved_p = 't'
	   and gp.portrait_primary_p = 't'}]

    if { $number_photos == 0 } {
	return ""
    }

    # get the lucky user
    #  Thanks to Oscar Bonilla <obonilla@fisicc-ufm.edu> who
    #  pointed out that we were previously ignoring the last user
    #  in the list
    set random_num [expr [randomRange $number_photos] + 1]
    # Using im_select_row_range means we actually only will retrieve the
    # 1 row we care about
    set sql "select emp.user_id
	       from im_employees_active emp, general_portraits gp
	      where emp.user_id <> :current_user_id
		and emp.user_id = gp.on_what_id
		and gp.on_which_table = 'USERS'
		and gp.approved_p = 't'
		and gp.portrait_primary_p = 't'"

    set portrait_user_id [db_string random_user_with_photo \
	    [im_select_row_range $sql $random_num $random_num]]
 
    # We use rownum<2 in case the user is mapped to more than one office
    #
    set office_group_id [im_office_group_id]
    if { ![db_0or1row random_employee_get_info \
	    "select u.first_names || ' ' || u.last_name as name, u.bio, u.skills, 
		    NVL(u.msn_email, u.email) as msn_email,
		    ug.group_name as office, ug.group_id as office_id
	       from im_employees_active u, user_groups ug, user_group_map ugm
	      where u.user_id = ugm.user_id(+)
		and ug.group_id = ugm.group_id
		and ug.parent_group_id = :office_group_id
		and u.user_id = :portrait_user_id
		and rownum < 2"] } {
	# No lucky employee :(
	return ""
    }

    # **** this should really be smart and look for the actual thumbnail
    # but it isn't and just has the browser smash it down to a fixed width
 
    append name2 "<div align=center>
<!-- Begin Online Status Indicator code -->
<!-- http://www.onlinestatus.org/ -->
<A HREF=\"http://arkansasmall.tcworks.net:8080/message/msn/$msn_email\">
<IMG SRC=\"http://arkansasmall.tcworks.net:8080/msn/$msn_email\"
border=\"0\" ALT=\"MSN Online Status Indicator\" onerror=\"this.onerror=null;this.src='http://status.inkiboo.com:8080/msn/$msn_email';\"></A>
<!-- End Online Status Indicator code -->
<a class=whitelink href=[im_url_stub]/users/view?user_id=$portrait_user_id><b>$name</b></a></div>"

    append content "
<br><div align=center><a class=blacklink href=\"/shared/portrait?user_id=$portrait_user_id\"><img width=125 src=\"/shared/portrait-bits?user_id=$portrait_user_id\" border=1></a></div>
<br><div align=center>Office: <a class=blacklink href=[im_url_stub]/offices/view?group_id=$office_id>$office</a></div>
[util_decode $bio "" "" "<br>Biography: $bio"]
[util_decode $skills "" "" "<br>Special skills: $skills"]
"
return "
[im_tablex "$name2" "0" "#000000" "5" "0" "150"]
[im_tablex "[im_tablex "$content" "0" "#ECF5E5" "1" "0"]" "0" "#000000" "1" "0" "150"]"

}


# ------------------------------------------------------
# User Community Component
# Show the most recent user registrations.
# This allows to detect duplicat registrations
# of users with multiple emails
# ------------------------------------------------------

ad_proc -public im_user_registration_component { current_user_id { max_rows 4} } {
    Shows the list of the last n registrations

    This allows to detect duplicat registrations
    of users with multiple emails
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set user_view_page "/intranet/users/view"
    
    set user_id [ad_get_user_id]
    
    if {![im_permission $user_id view_user_regs]} { return "" }

    set sql "
select
	u.user_id,
	u.username,
	u.screen_name,
	u.last_visit,
	u.second_to_last_visit,
	u.n_sessions,
	o.creation_date,
	im_email_from_user_id(u.user_id) as email,
	im_name_from_user_id(u.user_id) as name
from
	users u,
	acs_objects o
where
	u.user_id = o.object_id
order by
	o.creation_date DESC"

    set limited_sql "
select
	s.*
from
	(select
		r.*,
		rownum row_num
	from
		($sql) r
	) s
where
	row_num <= :max_rows
"

    set rows_html ""
    set ctr 1
    db_foreach registered_users $limited_sql {
	append rows_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>$creation_date</td>
  <td><A href=$user_view_page?user_id=$user_id>$name</A></td>
  <td><A href=mailto:$email>$email</A></td>
</tr>
"
	incr ctr
    }


    return "
<table border=0 cellspacing=1 cellpadding=1>
<tr class=rowtitle><td class=rowtitle align=center colspan=99>Recent Registrations</td></tr>
<tr class=rowtitle>
  <td align=center class=rowtitle>Date</td>
  <td align=center class=rowtitle>Name</td>
  <td align=center class=rowtitle>Email</td>
</tr>
$rows_html
<tr class=rowblank align=right>
  <td colspan=99>
    <a href=/intranet/users/index?view_name=user_community&order_by=Creation>more...</a>
  </td>
</tr>
</table>
"
}



# ------------------------------------------------------
#
# ------------------------------------------------------

ad_proc im_user_information { user_id } {

    040505 fraber: Obsolete: Not used in P/O anywhere...

    Returns an html string of all the intranet applicable information for one 
    user. This information can be used in the shared community member page, for 
    example, to give intranet users a better understanding of what other people
    are doing in the site.
} {

    set caller_id [ad_get_user_id]
    
    # is this user an employee?
    set user_employee_p [im_user_is_employee_p $user_id]

    set return_url [im_url_with_query]

    # we need a backup copy
    set user_id_copy $user_id

    # If we're looking at our own entry, we can modify some information
    if {$caller_id == $user_id} {
	set looking_at_self_p 1
    } else {
	set looking_at_self_p 0
    }

    # can the user make administrative changes to this page
    set user_admin_p [im_is_user_site_wide_or_intranet_admin $caller_id]

    if { ![db_0or1row employee_info \
	    "select u.*, uc.*, info.*,
		    ((sysdate - info.first_experience)/365) as years_experience
	       from users u, users_contact uc, im_employees info
	      where u.user_id = :user_id 
		and u.user_id = uc.user_id(+)
		and u.user_id = info.user_id(+)"] } {
	# Can't find the user		    
	ad_return_error "Error" "User doesn't exist"
	ad_script_abort
    }
    # get the user portrait
    set portrait_p [db_0or1row portrait_info "
       select portrait_id,
	      portrait_upload_date,
	      portrait_client_file_name
	 from general_portraits
	where on_what_id = :user_id
	  and upper(on_which_table) = 'USERS'
	  and approved_p = 't'
	  and portrait_primary_p = 't'
    "]

    # just in case user_id was set to null in the last query
    set user_id $user_id_copy
    set office_group_id [im_office_group_id]

    set sql "select ug.group_name, ug.group_id
    from user_groups ug, im_offices o
    where ad_group_member_p ( :user_id, ug.group_id ) = 't'
    and o.group_id=ug.group_id
    and ug.parent_group_id=:office_group_id
    order by lower(ug.group_name)"

    set offices ""
    set number_offices 0
    db_foreach offices_user_belongs_to $sql {
	incr number_offices
	if { ![empty_string_p $offices] } {
	    append offices ", "
	}
	append offices "  <a href=[im_url_stub]/offices/view?[export_url_vars group_id]>$group_name</A>"
    }

    set page_content "<ul>\n"

    if [exists_and_not_null job_title] {
	append page_content "<LI>Job title: $job_title\n"
    }

    if { $number_offices > 0 } {
	append page_content "  <li>[util_decode $number_offices 1 Office Offices]: $offices\n"
	if { $looking_at_self_p } {
	    append page_content "(<a href=[im_url_stub]/users/office-update?[export_url_vars user_id]>manage</a>)\n"
	}
    } elseif { $user_employee_p } {
	if { $looking_at_self_p } {
	    append page_content "  <li>Office: <a href=[im_url_stub]/users/add-to-office?[export_url_vars user_id return_url]>Add yourself to an office</a>\n"
	} elseif { $user_admin_p } {
	    append page_content "  <li>Office: <a href=[im_url_stub]/users/add-to-office?[export_url_vars user_id return_url]>Add this user to an office</a>\n"
	}
    }

    if [exists_and_not_null years_experience] {
	append page_content "<LI>Job experience: [format %3.1f $years_experience] years\n"
    }

    if { $user_employee_p } {
	# Let's offer a link to the people this person manages, if s/he manages somebody
	db_1row subordinates_for_user \
		"select decode(count(*),0,0,1) as number_subordinates
		   from im_employees_active 
		  where supervisor_id=:user_id"
	if { $number_subordinates == 0 } {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart>Org chart</a>: This user does not supervise any employees.\n"
	} else {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart>Org chart</a>: <a href=[im_url_stub]/employees/org-chart?starting_user_id=$user_id>View the org chart</a> starting with this employee\n"
	}

	set number_superiors [db_string employee_count_superiors \
		"select max(level)-1 
		   from im_employees
		  start with user_id = :user_id
		connect by user_id = PRIOR supervisor_id"]
	if { [empty_string_p $number_superiors] } {
	    set number_superiors 0
	}

	# Let's also offer a link to see to whom this person reports
	if { $number_superiors > 0 } {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart-chain?[export_url_vars user_id]>View chain of command</a> starting with this employee\n"
	}
    }	

    if { [exists_and_not_null portrait_upload_date] } {
	if { $looking_at_self_p } {
	    append page_content "<p><li><a href=/pvt/portrait/index?[export_url_vars return_url]>Portrait</A>\n"
	} else {
	    append page_content "<p><li><a href=/shared/portrait?[export_url_vars user_id]>Portrait</A>\n"
	}
    } elseif { $looking_at_self_p } {
	append page_content "<p><li>Show everyone else at [ad_system_name] how great looking you are:  <a href=/pvt/portrait/upload?[export_url_vars return_url]>upload a portrait</a>"
    }

    append page_content "<p>"

    if [exists_and_not_null email] {
	append page_content "<LI>Email: <A HREF=mailto:$email>$email</A>\n";
    }
    if [exists_and_not_null url] {
	append page_content "<LI>Homepage: <A HREF=[im_maybe_prepend_http $url]>[im_maybe_prepend_http $url]</A>\n";
    }
    if [exists_and_not_null aim_screen_name] {
	append page_content "<LI>AIM name: $aim_screen_name\n";
    }
    if [exists_and_not_null icq_number] {
	append page_content "<LI>ICQ number: $icq_number\n";
    }
    if [exists_and_not_null work_phone] {
	append page_content "<LI>Work phone: $work_phone\n";
    }
    if [exists_and_not_null home_phone] {
	append page_content "<LI>Home phone: $home_phone\n";
    }
    if [exists_and_not_null cell_phone] {
	append page_content "<LI>Cell phone: $cell_phone\n";
    }

    set address [im_format_address [value_if_exists ha_line1] [value_if_exists ha_line2] [value_if_exists ha_city] [value_if_exists ha_state] [value_if_exists ha_postal_code]]

    if { ![empty_string_p $address] } {
	append page_content "
	<p><table cellpadding=0 border=0 cellspacing=0>
	<tr>
	<td valign=top><em>Home address: </em></td>
	<td>$address</td>
	</tr>
	</table>

	"
    }

    if [exists_and_not_null skills] {
	append page_content "<p><em>Special skills:</em> $skills\n";
    }

    if [exists_and_not_null educational_history] {
	append page_content "<p><em>Degrees/Schools:</em> $educational_history\n";
    }

    if [exists_and_not_null last_degree_completed] {
	append page_content "<p><em>Last Degree Completed:</em> $last_degree_completed\n";
    }

    if [exists_and_not_null bio] {
	append page_content "<p><em>Biography:</em> $bio\n";
    }

    if [exists_and_not_null note] {
	append page_content "<p><em>Other information:</em> $note\n";
    }

    if {$looking_at_self_p} {
	set return_url [im_url_with_query]
	if { $user_employee_p } {
	    append page_content "<p>(<A HREF=[im_url_stub]/users/info-update?[export_url_vars return_url]>edit</A>)\n"
	} else {
	    # Non-employees should just use the public update page
	    append page_content "<p>(<A HREF=/pvt/basic-info-update?[export_url_vars return_url]>edit</A>)\n"
	}
    }

    if { $user_employee_p } {
	append page_content "
    <p><i>Current projects:</i><ul>\n"

	set projects_html ""

	set sql \
	    "select user_group_name_from_id(group_id) as project_name, parent_id,
		    decode(parent_id,null,null,user_group_name_from_id(parent_id)) as parent_project_name,
		    group_id as project_id
	       from im_projects p
	      where p.project_status_id in (select project_status_id
					      from im_project_status 
					     where project_status='Open' 
						or project_status='Future')
		and ad_group_member_p ( :user_id, p.group_id ) = 't'
	    connect by prior group_id=parent_id
	      start with parent_id is null"

	set projects_html ""
	db_foreach current_projects_for_employee $sql {
	    append projects_html "  <li> "
	    if { ![empty_string_p $parent_id] } {
		append projects_html "<a href=[im_url_stub]/projects/view?group_id=$parent_id>$parent_project_name</a> : "
	    }
	    append projects_html "<a href=[im_url_stub]/projects/view?group_id=$project_id>$project_name</a>\n"
	}
	if { [empty_string_p $projects_html] } {
	    set projects_html "  <li><i>None</i>\n"
	}

	append page_content "
	$projects_html
    </ul>
    "

	set sql "select start_date as unformatted_start_date, to_char(start_date, 'Mon DD, YYYY') as start_date, to_char(end_date,'Mon DD, YYYY') as end_date, contact_info, initcap(vacation_type) as vacation_type, vacation_id,
    description from user_vacations where user_id = :user_id 
    and (start_date >= to_date(sysdate,'YYYY-MM-DD') or
    (start_date <= to_date(sysdate,'YYYY-MM-DD') and end_date >= to_date(sysdate,'YYYY-MM-DD')))
    order by unformatted_start_date asc"

	set office_absences ""
	db_foreach vacations_for_employee $sql {
	    if { [empty_string_p $vacation_type] } {
		set vacation_type "Vacation"
	    }
	    append office_absences "  <li><b>$vacation_type</b>: $start_date - $end_date, <br>$description<br>
	    Contact info: $contact_info"
	    
	    if { $looking_at_self_p || $user_admin_p } {
		append office_absences "<br><a href=[im_url]/absences/edit?[export_url_vars vacation_id]>edit</a>"
	    }
	}
	
	if { ![empty_string_p $office_absences] } {
	    append page_content "
	<p>
	<i>Office Absences:</i>
	<ul>
	$office_absences
	</ul>
	"
	}

	if { [ad_parameter TrackHours intranet 0] && [im_user_is_employee_p $user_id] } {
	    append page_content "
	<p><a href=[im_url]/hours/index?on_which_table=im_projects&[export_url_vars user_id]>View this person's work log</a>
	</ul>
	"
	}

    }

    append page_content "</ul>\n"

    # Append a list of all the user's groups
    set sql "select ug.group_id, ug.group_name 
	       from user_groups ug
	      where ad_group_member_p ( :user_id, ug.group_id ) = 't'
	      order by lower(group_name)"
    set groups ""
    db_foreach groups_user_belong_to $sql {
	append groups "  <li> $group_name\n"
    }
    if { ![empty_string_p $groups] } {
	append page_content "<p><b>Groups to which this user belongs</b><ul>\n$groups</ul>\n"
    }

    # don't sign it with the publisher's email address!
    return $page_content
}



# ------------------------------------------------------------------------
# functions for printing the org chart
# ------------------------------------------------------------------------

ad_proc im_print_employee {person rowspan} "print function for org chart" {
    set user_id [fst $person]
    set employee_name [snd $person]
    set currently_employed_p [thd $person]

# Removed job title display
#    set job_title [lindex $person 3]

    if { $currently_employed_p == "t" } {

# Removed job title display
#	if { $rowspan>=2 } {
#	    return "<a href=/intranet/users/view?[export_url_vars user_id]>$employee_name</a><br><i>$job_title</i>\n"
#	} else {
	    return "<a href=/intranet/users/view?[export_url_vars user_id]>$employee_name</a><br>\n"
#	}
    } else {
	return "<i>Position Vacant</i>"
    }
}

ad_proc im_prune_org_chart {tree} "deletes all leaves where currently_employed_p is set to vacant position" {
    set result [list [head $tree]]
    # First, recursively process the sub-trees.
    foreach subtree [tail $tree] {
	set new_subtree [im_prune_org_chart $subtree]
	if { ![null_p $new_subtree] } {
	    lappend result $new_subtree
	}
    }
    # Now, delete vacant leaves.
    # We also delete vacant inner nodes that have only one child.
    # 1. if the tree only consists of one vacant node
    #    -> return an empty tree
    # 2. if the tree has a vacant root and only one child
    #    -> return the child 
    # 3. otherwise
    #    -> return the tree 
    if { [thd [head $result]] == "f" } {
	switch [llength $result] {
	    1       { return [list] }
	    2       { return [snd $result] }
	    default { return $result }
	}
    } else {
	return $result
    }
}




