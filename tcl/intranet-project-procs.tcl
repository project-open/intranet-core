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
}

# -----------------------------------------------------------
# Constant Functions
# -----------------------------------------------------------

ad_proc -public im_project_type_unknown {} { return 85 }
ad_proc -public im_project_type_other {} { return 86 }

ad_proc -public im_project_status_potential {} { return 71 }
ad_proc -public im_project_status_quoting {} { return 74 }
ad_proc -public im_project_status_open {} { return 76 }
ad_proc -public im_project_status_declined {} { return 77 }
ad_proc -public im_project_status_delivered {} { return 78 }
ad_proc -public im_project_status_invoiced {} { return 79 }
ad_proc -public im_project_status_closed {} { return 81 }
ad_proc -public im_project_status_deleted {} { return 82 }
ad_proc -public im_project_status_canceled {} { return 83 }


# -----------------------------------------------------------
# Project ::new, ::del and ::name procedures
# -----------------------------------------------------------

ad_proc -public im_project_has_type { project_id project_type } {
    Returns 1 if the project is of a specific type of subtype.
    Example: A "Trans + Edit + Proof" project is a "Translation Project".
} {
    # Is the projects type_id a sub-category of "Translation Project"?
    # We take two cases: Either the project is of category "project_type"
    # OR it is one of the subcategories of "project_type".

    ns_log Notice "im_project_has_type: project_id=$project_id, project_type=$project_type"
    set sql "
select  count(*)
from
        im_projects p,
	im_categories c,
        im_category_hierarchy h
where
        p.project_id = :project_id
	and c.category = :project_type
	and (
		p.project_type_id = c.category_id
	or
	        p.project_type_id = h.child_id
		and h.parent_id = c.category_id
	)
"
    return [db_string translation_project_query $sql]
}



ad_proc -public im_project_permissions {user_id project_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $project_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 1
    set read 0
    set write 0
    set admin 0

    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
    set user_is_group_member_p [ad_user_group_member $project_id $user_id]
    set user_is_group_admin_p [im_biz_object_admin_p $user_id $project_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]
    set user_in_project_group_p [string compare "t" [db_string user_belongs_to_project "select ad_group_member_p( :user_id, :project_id ) from dual" ] ]

    # Admin permissions to global + intranet admins + group administrators
    set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
    set user_admin_p [expr $user_admin_p || $user_is_wheel_p]

    set write $user_admin_p
    set admin $user_admin_p

    # Let the companies see their projects.
    set query "select company_id, lower(im_category_from_id(project_status_id)) as project_status from im_projects where project_id=:project_id"
    if {![db_0or1row project_company $query] } {
	return
    }

    ns_log Notice "user_is_admin_p=$user_is_admin_p"
    ns_log Notice "user_is_group_member_p=$user_is_group_member_p"
    ns_log Notice "user_is_group_admin_p=$user_is_group_admin_p"
    ns_log Notice "user_is_employee_p=$user_is_employee_p"
    ns_log Notice "user_admin_p=$user_admin_p"
    ns_log Notice "view_projects_history=[im_permission $user_id view_projects_history]"
    ns_log Notice "project_status=$project_status"

    set user_is_project_company_p [ad_user_group_member $company_id $user_id]

    if {$user_admin_p} { set admin 1}
    if {$user_is_project_company_p} { set read 1}
    if {$user_is_group_member_p} { set read 1}
    if {[im_permission $user_id view_projects_all]} { set read 1}

    # companies and freelancers are not allowed to see non-open projects.
    # 76 = open
    if {![im_permission $user_id view_projects_history] && ![string equal $project_status "open"]} {
	# Except their own projects...
	if {!$user_is_project_company_p} {
	    set read 0
	}
    }

    # No read - no write...
    if {!$read} {
	set write 0
	set admin 0
    }
}


namespace eval project {

    ad_proc -public new {
        -project_name
        -project_nr
        -project_path
        -company_id
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
	@param company_id Who is going to pay for this project?
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
	creation_date => :creation_date,
	creation_user => :creation_user,
	creation_ip => :creation_ip,
	context_id => :context_id,

	project_name	=> :project_name,
        project_nr      => :project_nr,
        project_path   => :project_path,
	parent_id => :parent_id,
        company_id => :company_id,
	project_type_id => :project_type_id,
	project_status_id => :project_status_id
    );
end;"

        if { [empty_string_p $creation_date] } {
	    set creation_date [db_string get_sysdate "select sysdate from dual" -default 0]
        }
        if { [empty_string_p $creation_user] } {
            set creation_user [auth::get_user_id]
        }
        if { [empty_string_p $creation_ip] } {
            set creation_ip [ns_conn peeraddr]
        }

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

    set today [db_string sysdate "select to_char(sysdate,'YYYY') from dual"]

    set sql "
select
	'$today' ||'_'|| trim(to_char(1 + cast((max(substr(p.project_nr,6,4))) as integer), '0000')) as project_nr
from
        im_projects p
where
        p.project_nr like '200_/_____' escape '/' and
        substr(p.project_nr, 1,4)='$today' and
        ascii(substr(p.project_nr,6,1)) > 47 and
        ascii(substr(p.project_nr,6,1)) < 58 and
        ascii(substr(p.project_nr,7,1)) > 47 and
        ascii(substr(p.project_nr,7,1)) < 58 and
        ascii(substr(p.project_nr,8,1)) > 47 and
        ascii(substr(p.project_nr,8,1)) < 58 and
        ascii(substr(p.project_nr,9,1)) > 47 and
        ascii(substr(p.project_nr,9,1)) < 58"

    set project_nr [db_string next_project_nr $sql -default ""]
    if {"" == $project_nr} { 
	set project_nr [db_string project_nr_default "select to_char(now(), 'YYYY') ||'_0000' from dual"]
    }

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


ad_proc -public im_project_options { {include_empty 1} } { 
    Cost project options
} {
    set options [db_list_of_lists project_options "
	select project_name, project_id
	from im_projects
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
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

ad_proc -public im_project_select { select_name { default "" } { status "" } {type ""} { exclude_status "" } {member_user_id ""} {company_id ""} } {
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
     set user_id [ad_get_user_id]
     ns_set put $bind_vars user_id $user_id

     if {[im_permission $user_id view_projects_all]} {
	 # The user can see all projects
	 # This is particularly important for sub-projects.
	 set sql "
		select
			p.project_id,
			p.project_name
		from
			im_projects p
		where
			1=1
	"
     } else {
	 # The user should see only his own projects
	 set sql "
		select
			p.project_id,
			p.project_name
		from
			im_projects p,
	                (       select  count(rel_id) as member_p,
	                                object_id_one as object_id
	                        from    acs_rels
	                        where   object_id_two = :user_id
	                        group by object_id_one
	                ) r
		where
			p.project_id = r.object_id
			and r.member_p > 0
	"
     }	


     if { ![empty_string_p $company_id] } {
	 ns_set put $bind_vars company_id $company_id
	 append sql " and p.company_id = :company_id"
     }

     if { ![empty_string_p $status] } {
	 ns_set put $bind_vars status $status
	 append sql " and p.project_status_id = (
	     select project_status_id 
	     from im_project_status 
	     where lower(project_status)=lower(:status))"
    }

    if { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars project_status $exclude_status]
	append sql " and p.project_status_id in (
	    select project_status_id 
            from im_project_status 
            where project_status not in ($exclude_string)) "
    }

    if { ![empty_string_p $type] } {
	ns_set put $bind_vars type $type
	append sql " and p.project_type_id = (
	    select project_type_id 
	    from im_project_types 
	    where project_type=:type)"
    }

     if { ![empty_string_p $member_user_id] } {
	 ns_set put $bind_vars member_user_id $member_user_id
	 append sql "	and p.project_id in (
				select object_id_one
				from acs_rels
				where object_id_two = :member_user_id)
		    "
    }

    append sql " order by lower(p.project_name)"
    return [im_selection_to_select_box -translate_p 0 $bind_vars project_select $sql $select_name $default]
}
