# /tcl/intranet-project-components.tcl
#
# Copyright (C) 2004 Project/Open
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
    Bring together all procedures and components (=HTML + SQL code)
    related to Projects.

    Sections of this library:
    <ul>
    <li>Project OO new, del and name methods
    <li>Project Business Logic
    <li>Project Components

    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
    @creation-date  27 June 2003
}


# -----------------------------------------------------------
# Project ::new, ::del and ::name procedures
# -----------------------------------------------------------

namespace eval project {

    ad_proc new {
        -project_name
        -project_nr
        -project_path
        -customer_id
        { -parent_id "" }
	{ -project_type_id "" }
	{ -project_status_id "" }
	{ -creation_date "" }
	{ -creation_user "" }
	{ -creation_ip "" }
	{ -context_id "" }

    } {
	Creates a new project including the projects  "Main Office".
	@author frank.bergmann@project-open.com

	@return <code>project_id</code> of the newly created project

	@param project_name Pretty name for the project
	@param project_nr Current project Nr, such as: "2004_0001".
	@param project_path Path for project files in the filestorage
	@param customer_id Who is going to pay for this project?
	@param parent_id Which is the parent (for subprojects)
	@param project_type_id Default: "Other": Configurable project
	       type used for reporting only
	@param project_status_id Default: "Active": Allows to follow-
	       up through the project acquistion process
	@param others The default optional parameters for OpenACS
	       objects
    } {
	# -----------------------------------------------------------
	# Check for duplicated unique fields (name & path)
	# We asume the application page knows how to deal with
	# the uniqueness constraint, so we won't generate an error
	# but just return the duplicated item. 
	set dup_sql "
select	project_id 
from	im_projects 
where	upper(trim(project_name)) = upper(trim(:project_name))
	or upper(trim(project_nr)) = upper(trim(:project_nr))
	or upper(trim(project_path)) = upper(trim(:project_path))"
	set pid 0
	db_foreach dup_projects $dup_sql { set pid $project_id }
	if {0 != $pid} { return $pid }

	set sql "
begin
    :1 := im_project.new(
	object_type	=> 'im_project',
	project_name	=> '$project_name',
        project_nr      => '$project_nr',
        project_path   => '$project_path'
"
	if {"" != $customer_id} { append sql "\t, customer_id => $customer_id\n" }
	if {"" != $parent_id} { append sql "\t, parent_id => $parent_id\n" }
	if {"" != $project_type_id} { append sql "\t, project_type_id => $project_type_id\n" }
	if {"" != $project_status_id} { append sql "\t, project_status_id => $project_status_id\n" }
	
	if {"" != $creation_date} { append sql "\t, creation_date => '$creation_date'\n" }
	if {"" != $creation_user} { append sql "\t, creation_user => '$creation_user'\n" }
	if {"" != $creation_ip} { append sql "\t, creation_ip => '$creation_ip'\n" }
	if {"" != $context_id} { append sql "\t, context_id => $context_id\n" }

	append sql "        );
    end;"
        set project_id [db_exec_plsql create_new_project $sql]
        return $project_id
    }
}



# -----------------------------------------------------------
# Projects Business Logic
# -----------------------------------------------------------


ad_proc -public im_next_project_nr { } {
    Returns the next free project number

    Returns "" if there was an error calculating the number.
    Project_nr's look like: 2003_0123 with the first 4 digits being
    the current year and the last 4 digits as the current number
    within the year.
    <p>
    The SQL query works by building the maximum of all numeric (the 8 
    substr comparisons of the last 4 digits) project numbers
    of the current year (comparing the first 4 digits to the current year),
    adding "+1", and contatenating again with the current year.
} {
    set sql "
select
	to_char(sysdate, 'YYYY')||'_'||
	trim(to_char(1+max(substr(p.project_nr,6,4)),'0000')) as project_nr
from
        im_projects p
where
        p.project_nr like '200_/_____' escape '/' and
        substr(p.project_nr, 1,4)=to_char(sysdate, 'YYYY') and
        ascii(substr(p.project_nr,6,1)) > 47 and
        ascii(substr(p.project_nr,6,1)) < 58 and
        ascii(substr(p.project_nr,7,1)) > 47 and
        ascii(substr(p.project_nr,7,1)) < 58 and
        ascii(substr(p.project_nr,8,1)) > 47 and
        ascii(substr(p.project_nr,8,1)) < 58 and
        ascii(substr(p.project_nr,9,1)) > 47 and
        ascii(substr(p.project_nr,9,1)) < 58
"
    set project_nr [db_string next_project_nr $sql -default ""]
    return $project_nr
}



# -----------------------------------------------------------
# Project Components
# -----------------------------------------------------------

ad_proc -public im_new_project_html { user_id } {
    Return a piece of HTML allowing a user to start a new project
} {
    if {![im_permission $user_id add_projects]} { return "" }
    return "<a href='/intranet/projects/new'>
           [im_gif new "Create a new Project"]
           </a>"
}



ad_proc -public im_format_project_duration { words {lines ""} {hours ""} {days ""} {units ""} } {
    Write out the shortest possible string describing the 
    length of a project
} {
    set result $words
    set pending ""
    if {![string equal $words ""]} {
	set pending "W, "
    }

    if {![string equal $lines ""]} {
	append result "${pending}${lines}L"
	set pending ", "
    }
    if {![string equal $hours ""]} {
	append result "${pending}${hours}H"
	set pending ", "
    }
    if {![string equal $days ""]} {
	append result "${pending}${days}D"
	set pending ", "
    }
    if {![string equal $units ""]} {
	append result "${pending}${units}U"
	set pending ""
    }
    return $result
}


ad_proc -public im_project_members_select { select_name project_id { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all members of $project_id. If status is
    specified, we limit the select box to invoices that match that
    status. If exclude status is provided, we limit to states that do not
    match exclude_status (list of statuses to exclude).
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id

    set sql "
select
	u.user_id,
	u.first_names||' '||u.last_name as user_name
from
	user_group_map m,
	users u
where
	m.group_id=:project_id
	and m.user_id=u.user_id
order by 
	lower(first_names)"

    return [im_selection_to_select_box $bind_vars "project_member_select" $sql $select_name $default]
}


ad_proc -public im_project_type_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the project_types in the system
} {
    return [im_category_select "Intranet Project Type" $select_name $default]
}

ad_proc -public im_project_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the project_types in the system
} {
    return [im_category_select "Intranet Project Status" $select_name $default]
}

ad_proc -public im_project_parent_select { select_name { default "" } {current_group_id ""} { status "" } { exclude_status "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the eligible projects for parents
} {
    set bind_vars [ns_set create]
    if { [empty_string_p $current_group_id] } {
	set limit_group_sql ""
    } else {
	ns_set put $bind_vars current_group_id $current_group_id
	set limit_group_sql " and p.group_id != :current_group_id"
    }
    set status_sql ""
    if { ![empty_string_p $status] } {
	ns_set put $bind_vars status $status
	set status_sql "and p.project_status_id=(select project_status_id from im_project_status where project_status=:status)"
    } elseif { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars project_status $exclude_status] 
	set status_sql " and p.project_status_id in (
	    select project_status_id 
            from im_project_status
	    where project_status not in ($exclude_string)) "
    }

    set sql "select g.group_id, g.group_name
               from user_groups g, im_projects p 
              where p.parent_id is null 
                and g.group_id=p.group_id(+) $limit_group_sql $status_sql
              order by lower(g.group_name)"
    return [im_selection_to_select_box $bind_vars parent_project_select $sql $select_name $default]
}



ad_proc -public im_project_select { select_name { default "" } { status "" } {type ""} { exclude_status "" } {member_user_id ""} } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the projects in the system. If status is
    specified, we limit the select box to projects matching that
    status. If type is specified, we limit the select box to project
    matching that type. If exclude_status is provided as a list, we
    limit to states that do not match any states in exclude_status.
    If member_user_id is specified, we limit the select box to projects
    where member_user_id participate in some role.
 } {
     set bind_vars [ns_set create]

     set sql "
	select
		p.project_id,
		p.project_name
	from
		im_projects p
	where
		1=1
	"
	
     if { ![empty_string_p $status] } {
	 ns_set put $bind_vars status $status
	 append sql " and project_status_id=(
	     select project_status_id 
	     from im_project_status 
	     where project_status=:status)"
    }

    if { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars project_status $exclude_status]
	append sql " and project_status_id in (
	    select project_status_id 
            from im_project_status 
            where project_status not in ($exclude_string)) "
    }

    if { ![empty_string_p $type] } {
	ns_set put $bind_vars type $type
	append sql " and project_type_id=(
	    select project_type_id 
	    from im_project_types 
	    where project_type=:type)"
    }

     if { ![empty_string_p $member_user_id] } {
	 ns_set put $bind_vars member_user_id $member_user_id
	 append sql "	and p.project_id in (
				select project_id
				from im_projects
				where project_id=:member_user_id)
		    "
    }
# and ug.group_id in (
	#     select group_id
	 #    from user_group_map
	  #   where user_id=:member_user_id)

    append sql " order by lower(project_name)"
    return [im_selection_to_select_box $bind_vars project_select $sql $select_name $default]
}

