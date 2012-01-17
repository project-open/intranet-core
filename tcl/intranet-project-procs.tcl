# /intranet-core/tcl/intranet-project-procs.tcl
#
# Copyright (C) 2004 ]project-open[
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
ad_proc -public im_project_type_task {} { return 100 }
ad_proc -public im_project_type_ticket {} { return 101 }
ad_proc -public im_project_type_consulting {} { return 2501 }
ad_proc -public im_project_type_sla {} { return 2502 }
ad_proc -public im_project_type_milestone {} { return 2504 }
ad_proc -public im_project_type_program {} { return 2510 }

ad_proc -public im_project_type_software_release {} { return 4599 }
ad_proc -public im_project_type_software_release_item {} { return 4597 }

ad_proc -public im_project_type_bt_container { } { return 4300 }
ad_proc -public im_project_type_bt_task { } { return 4305 }


ad_proc -public im_project_status_potential {} { return 71 }
ad_proc -public im_project_status_quoting {} { return 74 }
ad_proc -public im_project_status_open {} { return 76 }
ad_proc -public im_project_status_declined {} { return 77 }
ad_proc -public im_project_status_delivered {} { return 78 }
ad_proc -public im_project_status_invoiced {} { return 79 }
ad_proc -public im_project_status_closed {} { return 81 }
ad_proc -public im_project_status_deleted {} { return 82 }
ad_proc -public im_project_status_canceled {} { return 83 }


ad_proc -public im_project_on_track_status_green {} { return 66 }
ad_proc -public im_project_on_track_status_yellow {} { return 67 }
ad_proc -public im_project_on_track_status_red {} { return 68 }


# -----------------------------------------------------------
# Project ::new, ::del and ::name procedures
# -----------------------------------------------------------

ad_proc -public im_project_has_type { project_id project_type } {
    Returns 1 if the project is of a specific type of subtype.
    Example: A "Trans + Edit + Proof" project is a "Translation Project".
} {
    return [util_memoize [list im_project_has_type_helper $project_id $project_type] 120]
}

ad_proc -public im_project_has_type_helper { project_id project_type } {
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
    return [db_string project_has_type $sql]
}



ad_proc -public im_project_permissions {
    {-debug 0}
    user_id 
    project_id
    view_var
    read_var
    write_var
    admin_var
} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $project_id
} {
    ns_log Notice "im_project_permissions: user_id=$user_id project_id=$project_id"
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 1
    set read 0
    set write 0
    set admin 0

    ns_log Notice "im_project_permissions: before user_is_admin_p"
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [im_profile::member_p -profile_id [im_wheel_group_id] -user_id $user_id]
    set user_is_group_member_p [im_biz_object_member_p $user_id $project_id]
    set user_is_group_admin_p [im_biz_object_admin_p $user_id $project_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]

    # empty project_id would give errors below
    if {"" == $project_id} { set project_id 0 }
    ns_log Notice "im_project_permissions: before im_security_alert_check_integer"
    im_security_alert_check_integer -location "im_project_permissions" -value $project_id


    # Treat the project mangers_fields
    # A user man for some reason not be the group PM
    ns_log Notice "im_project_permissions: before project_manager"
    if {!$user_is_group_admin_p} {
	set project_manager_id [db_string project_manager "select project_lead_id from im_projects where project_id = :project_id" -default 0]
	if {$user_id == $project_manager_id} {
	    set user_is_group_admin_p 1
	}
    }
    
    # Admin permissions to global + intranet admins + group administrators
    ns_log Notice "im_project_permissions: user_admin_p"
    set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
    set user_admin_p [expr $user_admin_p || $user_is_wheel_p]

    set write $user_admin_p
    set admin $user_admin_p

    # Get the projects's company and the project status
    # Use caching because this procedure is queried very frequently!
    ns_log Notice "im_project_permissions: company info"
    set query "
	select	company_id, 
		lower(im_category_from_id(project_status_id)) as project_status 
	from	im_projects
	where	project_id = $project_id
    "
    set company_infos [util_memoize [list db_list_of_lists company_info $query]]
    set company_info [lindex $company_infos 0]
    set company_id [lindex $company_info 0]
    set project_status [lindex $company_info 1]

    if {$debug} {
	ns_log Notice "user_is_admin_p=$user_is_admin_p"
	ns_log Notice "user_is_group_member_p=$user_is_group_member_p"
	ns_log Notice "user_is_group_admin_p=$user_is_group_admin_p"
	ns_log Notice "user_is_employee_p=$user_is_employee_p"
	ns_log Notice "user_admin_p=$user_admin_p"
	ns_log Notice "view_projects_history=[im_permission $user_id view_projects_history]"
	ns_log Notice "project_status=$project_status"
    }

    set user_is_company_member_p [im_biz_object_member_p $user_id $company_id]
    set user_is_company_admin_p [im_biz_object_admin_p $user_id $company_id]

    if {$user_admin_p} { 
	set admin 1
	set write 1
	set read 1
	set view 1
    }

# 20050729 fraber: Don't let customer's contacts see their project
# without exlicit permission...
#    if {$user_is_company_member_p} { set read 1}


    # Allow customer' Members to see their customer's projects
    ns_log Notice "im_project_permissions: customer members"
    if {$user_is_company_member_p && $user_is_employee_p} { 
	set view 1
	set read 1
    }
    
    # Allow Key Account Managers to see their customer's projects
    ns_log Notice "im_project_permissions: company_admin"
    if {$user_is_company_admin_p && $user_is_employee_p} { 
	set read 1
	set write 1
	set admin 1
    }

    # The user is member of the project
    if {$user_is_group_member_p} { 
	set read 1
    }

    ns_log Notice "im_project_permissions: view_projects_all"
    if {[im_permission $user_id view_projects_all]} { 
	set read 1
    }

    ns_log Notice "im_project_permissions: edit_projects_all"
    if {[im_permission $user_id edit_projects_all]} { 
	set read 1
	set write 1
	set admin 1
    }

    # companies and freelancers are not allowed to see non-open projects.
    # 76 = open
    ns_log Notice "im_project_permissions: view_projects_history"
    if {![im_permission $user_id view_projects_history] && ![string equal $project_status "open"]} {
	# Except their own projects...
	if {!$user_is_company_member_p && !$user_is_group_member_p} {
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
	Creates a new project.

	@author frank.bergmann@project-open.com
	@return <code>project_id</code> of the newly created project
	        or 0 in case of an error.
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

	set parent_sql "parent_id = :parent_id"
	if {"" == $parent_id} { set parent_sql "parent_id is NULL" }

	set dup_sql "
		select	count(*)
		from	im_projects 
		where	$parent_sql and
			(	upper(trim(project_name)) = upper(trim(:project_name)) OR
				upper(trim(project_nr)) = upper(trim(:project_nr)) OR
				upper(trim(project_path)) = upper(trim(:project_path))
			)
	"
	if {[db_string duplicates $dup_sql]} { 
	    ad_return_complaint 1 "<b>Duplicate project</b>:<br>
	    	Your project name or project path already exists"
	    return 0
	}

	set sql "
		begin
		    :1 := im_project.new(
			object_type	=> 'im_project',
			creation_date	=> :creation_date,
			creation_user	=> :creation_user,
			creation_ip	=> :creation_ip,
			context_id	=> :context_id,
		
			project_name	=> :project_name,
		        project_nr      => :project_nr,
		        project_path	=> :project_path,
			parent_id	=> :parent_id,
		        company_id	=> :company_id,
			project_type_id	=> :project_type_id,
			project_status_id => :project_status_id
		    );
		end;
	"

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

	# Write Audit Trail
	# im_project_audit -action after_create -project_id $project_id

        return $project_id
    }
}

# -----------------------------------------------------------
# Projects Business Logic
# -----------------------------------------------------------


ad_proc -public im_next_project_nr { 
    {-customer_id 0 }
    {-parent_id "" }
    {-nr_digits}
    {-date_format}
} {
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
    # Set default values from parameters
    if {![info exists nr_digits]} {
	set nr_digits [parameter::get -package_id [im_package_core_id] -parameter "ProjectNrDigits" -default "4"]
    }
    if {![info exists date_format]} {
	set date_format [parameter::get -package_id [im_package_core_id] -parameter "ProjectNrDateFormat" -default "YYYY_"]
    }

    # Check for a custom project_nr generator
    set project_nr_generator [parameter::get -package_id [im_package_core_id] -parameter "CustomProjectNrGenerator" -default ""]

    if {"" != $project_nr_generator} {
	return [eval $project_nr_generator -customer_id $customer_id -nr_digits $nr_digits -date_format $date_format]
    }
    
    # Should we create hierarchial project numbers for sub-projects?
    set project_nr_hierarchical_digits [parameter::get -package_id [im_package_core_id] -parameter "ProjectNrHierarchicalDigits" -default 0]
    
    # ----------------------------------------------------
    # Calculate the next invoice Nr by finding out the last
    # one +1

    set todate [db_string today "select to_char(now(), :date_format)"]
    if {"none" == $date_format} { set date_format "" }

    # Adjust the position of the start of date and nr in the invoice_nr
    set date_format_len [string length $date_format]
    set nr_start_idx [expr 1+$date_format_len]
    set date_start_idx 1

    set num_check_sql ""
    set zeros ""
    for {set i 0} {$i < $nr_digits} {incr i} {
	set digit_idx [expr 1 + $i]
	append num_check_sql "
		and ascii(substr(p.nr,$digit_idx,1)) > 47 
		and ascii(substr(p.nr,$digit_idx,1)) < 58
	"
	append zeros "0"
    }


    # ----------------------------------------------------
    # Check if we create a sub-project or even sub-sub-project etc.
    # Then we just replace the variables above.
    if {"" != $parent_id && $project_nr_hierarchical_digits > 0} {
	set parent_project_nr ""
	db_0or1row parent_project_info "
		select	project_nr as parent_project_nr
		from	im_projects
		where	project_id = :parent_id
	"

	set nr_digits $project_nr_hierarchical_digits
	set date_format "${parent_project_nr}_"
	set todate $date_format
	set date_format_len [string length $date_format]
	set nr_start_idx [expr 1+$date_format_len]
	set date_start_idx 1
	set zeros ""
	set num_check_sql ""
	for {set i 0} {$i < $nr_digits} {incr i} {
	    set digit_idx [expr 1 + $i]
	    append num_check_sql "
		and ascii(substr(p.nr,$digit_idx,1)) > 47 
		and ascii(substr(p.nr,$digit_idx,1)) < 58
	    "
	    append zeros "0"
	}
    }

    # ----------------------------------------------------
    # Pull out the largest number that fits the PPPPPPPP_xxxx format

    set sql "
	select
		trim(max(p.nr)) as last_project_nr
	from (
		 select substr(project_nr, :nr_start_idx, :nr_digits) as nr
		 from   im_projects
		 where	substr(project_nr, :date_start_idx, :date_format_len) = '$todate'
	     ) p
	where	1=1
		$num_check_sql
    "

    set last_project_nr [db_string max_project_nr $sql -default $zeros]
    set last_project_nr [string trimleft $last_project_nr "0"]
    if {[empty_string_p $last_project_nr]} { set last_project_nr 0 }
    set next_number [expr $last_project_nr + 1]

    # ----------------------------------------------------
    # Put together the new project_nr
    set nr_sql "select '$todate' || trim(to_char($next_number,:zeros)) as project_nr"
    set project_nr [db_string next_project_nr $nr_sql -default ""]
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







ad_proc -public im_project_subproject_ids {
    {-type "project"}
        -exclude_self:boolean
        -project_id
        -sql:boolean
    {-exclude_status_ids ""}
    {-project_type_ids ""}
    {-exclude_type_ids ""}
} {
    Get a list of subproject ids. This can be used both as a filter proc (e.g. to filter our certain types of projects from a list of projects) or to get a list of subprojects or even tasks.
    
    @param type can be project or task.
    @param sql Return a sql list
} {
    set exclude_clauses [list]
    
    if {$project_type_ids ne ""} {
	lappend exclude_clauses "and children.project_type_id in ([template::util::tcl_to_sql_list $project_type_ids])"
	
	# It doesn't make sense to exclude when we include ....
	set exclude_type_ids ""
	
    }
    
    if {"" == $exclude_status_ids} { set exclude_status_ids [im_project_status_deleted] }
    
    lappend exclude_type_ids [im_project_type_task]
    lappend exclude_clauses "and children.project_status_id not in ([template::util::tcl_to_sql_list $exclude_status_ids])"
    lappend exclude_clauses "and children.project_type_id not in ([template::util::tcl_to_sql_list $exclude_type_ids])"
    
    # Make sure we don't by accident end up with a circular loop
    if {$exclude_self_p} {
	lappend exclude_clauses "and children.project_id != :project_id"
	set union_clause ""
    } else {
	set union_clause "UNION select :project_id as project_id from dual"
    }
    
    set project_ids [db_list projects "
                select  children.project_id
                from    im_projects parent,
                        im_projects children
                where
                        children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
                and parent.project_id = :project_id
                [join $exclude_clauses " \n"]
                $union_clause
    "]

    if {$type eq "task"} {
	# Make sure that we get the tasks, even if we exclude the project itself
	if {$exclude_self_p} {
	    lappend project_ids $project_id
	}
	
	if {$project_ids ne ""} {
	    set project_ids [db_list tasks "
		select	project_id
		from	im_projects
		where	project_type_id = [im_project_type_task] and parent_id in ([template::util::tcl_to_sql_list $project_ids])
	    "]
	}
    }

    if {$sql_p} {
	# Make sure it works even if we don't have anything to return
	if {$project_ids ne ""} {
	    return [template::util::tcl_to_sql_list $project_ids]
	} else {
	    return 0
	}
    } else {
	return $project_ids
    }
}






ad_proc -public im_project_options { 
    {-include_empty 1}
    {-include_empty_name ""}
    {-include_project_ids {} }
    {-exclude_subprojects_p 1}
    {-exclude_tasks_p 1}
    {-exclude_status_id ""}
    {-exclude_type_id ""}
    {-project_status_id 0}
    {-project_type_id 0}
    {-member_user_id 0}
    {-company_id 0}
    {-project_id 0}
} { 
    Get a list of projects
} {
    # Default: Exclude tasks and deleted projects
    if {"" == $exclude_status_id} { set exclude_status_id [im_project_status_deleted] }
    if {"" == $exclude_type_id} { set exclude_type_id [list [im_project_type_task] [im_project_type_ticket]] }
    if {!$exclude_tasks_p} { set exclude_subprojects_p 0 }

    set current_project_id $project_id
    set super_project_id $project_id
    set current_user_id [ad_get_user_id]
    set max_project_name_len 50

    # Make sure we don't get a syntax error in the query
    lappend include_project_ids 0

    set list_sort_order [parameter::get_from_package_key -package_key "intranet-timesheet2" -parameter TimesheetAddHoursSortOrder -default "name"]

    # Exclude subprojects does not work with subprojects,
    # if we are showing this box for a sub-sub-project.
    set subsubproject_sql ""
    set subprojects [list 0]
    if {0 != $current_project_id} {

	# Determine the topmost project in the hierarchy
	set super_project_id $current_project_id
	set loop 1
	set ctr 0
	while {$loop && $ctr < 100} {
	    set loop 0
	    set parent_id [db_string parent_id "
		select parent_id 
		from im_projects
		where project_id = :super_project_id
	    " -default ""]
	    if {"" != $parent_id} {
		set super_project_id $parent_id
		set loop 1
	    }
	    incr ctr
	}

	# Check permissions for showing subprojects
	set perm_sql "
		(select p.*
		from    im_projects p,
			acs_rels r
		where   r.object_id_one = p.project_id
			and r.object_id_two = :current_user_id
		)
	"
	if {[im_permission $current_user_id "view_projects_all"]} {
	    set perm_sql "im_projects" 
	}


	set subprojects [db_list subprojects "
		select	children.project_id
		from	im_projects parent,
			$perm_sql children
		where
			children.tree_sortkey 
				between parent.tree_sortkey 
				and tree_right(parent.tree_sortkey)
			and children.project_type_id not in (
				84, [im_project_type_task]
			)
			and parent.project_id = :super_project_id

			-- exclude the projects own subprojects
			-- to avoid circular loops
			and children.project_id not in (
				select	subchild.project_id
				from	im_projects subparent,
					im_projects subchild
				where
					subchild.tree_sortkey 
						between subparent.tree_sortkey 
						and tree_right(subparent.tree_sortkey)
					and subparent.project_id = :current_project_id
			)
	"]

	# Add an invalid project in order to avoid an empty list of subprojects
	# and a resulting SQL syntax error in "parent_id in ()"
	lappend subprojects 0

    }

    # ---------------------------------------------------------
    # Compile "criteria"

    set p_criteria [list]
    set main_p_criteria [list]
    if {$exclude_subprojects_p} { 
	lappend p_criteria "p.parent_id is null" 
    }
   
    if {0 != $company_id && "" != $company_id} { 
	lappend p_criteria "p.company_id = :company_id" 
	# Main project should have same customer, but don't enforce it!
    }

    if {0 != $exclude_status_id && "" != $exclude_status_id} {
	lappend p_criteria "p.project_status_id not in ([join [im_sub_categories -include_disabled_p 1 $exclude_status_id] ","])"
	lappend main_p_criteria "p.project_status_id not in ([join [im_sub_categories $exclude_status_id] ","])"
    }

    if {0 != $exclude_type_id && "" != $exclude_type_id} {
	lappend p_criteria "p.project_type_id not in ([join [im_sub_categories -include_disabled_p 1 $exclude_type_id] ","])"
	# No restriction of type on parent project!
    }

    if {$exclude_tasks_p} {
	lappend p_criteria "p.project_type_id not in ([join [im_sub_categories -include_disabled_p 1 [im_project_type_task]] ","])"
	# Main project is never of type task...
    }

    if {0 != $project_status_id && "" != $project_status_id} {
	lappend p_criteria "p.project_status_id in ([join [im_sub_categories $project_status_id] ","])"
	# No restriction on parent's status id
    }

    if {0 != $project_type_id && "" != $project_type_id} {
	lappend p_criteria "p.project_type_id in ([join [im_sub_categories -include_disabled_p 1 $project_type_id] ","])"
	# No restriction on parent's project type!
    }

    # Disable the restriction to "my projects" if the user can see all projects.
    if {[im_permission $current_user_id "view_projects_all"]} { 
	set member_user_id 0
    }

    if {0 != $member_user_id && "" != $member_user_id} {
	lappend p_criteria "p.project_id in (
					select	object_id_one
					from	acs_rels
					where	object_id_two = :member_user_id
	)"
	# No restriction on parent project membership, because parent
	# projects always have the same members as sub-projects.
    }

    # Unprivileged members can only see the projects they're participating
    if {![im_permission $current_user_id view_projects_all]} {
	lappend p_criteria "p.project_id in (
					select	object_id_one
					from	acs_rels
					where	object_id_two = :current_user_id
	)"
	# No restriction on parent project membership, because parent
	# projects always have the same members as sub-projects.
    }

    # -----------------------------------------------------------------
    # Compose the SQL

    set p_where_clause [join $p_criteria " and\n\t\t\t\t\t"]
    if { ![empty_string_p $p_where_clause] } {
	set p_where_clause " and $p_where_clause"
    }

    set main_p_where_clause [join $p_criteria " and\n\t\t\t\t\t"]
    if { ![empty_string_p $main_p_where_clause] } {
	set main_p_where_clause " and $main_p_where_clause"
    }

    switch $list_sort_order {
	name { set sort_order "lower(p.project_name)" }
	order { set sort_order "p.sort_order" }
	legacy { set sort_order "p.tree_sortkey" }
	default { set sort_order "lower(p.project_nr)" }
    }

    set sql "
		select
			p.project_id,
			p.parent_id,
			tree_level(p.tree_sortkey) as tree_level,
			substring(p.project_name for :max_project_name_len) as project_name_shortened,
			$sort_order as sort_order
		from
			im_projects p,
			im_projects main_p,
			(	select	p.project_name,
					p.project_id
				from	im_projects p
				where	1=1
					$p_where_clause
			    UNION
				select	p.project_name,
					p.project_id
				from	im_projects p
				where	p.project_id in ([join $subprojects ", "])
			    UNION
				select	p.project_name,
					p.project_id
				from	im_projects p
				where	p.project_id = :current_project_id
			    UNION
				select	p.project_name,
					p.project_id
				from	im_projects p
				where	p.project_id in ([join $include_project_ids ","])
			) p_cond,
			(	select	p.project_id
				from	im_projects p
				where	1=1
					$p_where_clause
			    UNION
				select	p.project_id
				from	im_projects p
				where	p.project_id = :super_project_id
			) main_p_cond
		where
			p.project_id = p_cond.project_id and
			main_p.project_id = main_p_cond.project_id and
			main_p.parent_id is null and
			tree_ancestor_key(p.tree_sortkey, 1) = main_p.tree_sortkey and
			main_p.project_status_id not in ([im_project_status_deleted]) and
			p.project_status_id not in ([im_project_status_deleted])
		order by 
			lower(main_p.project_name),
			p.tree_sortkey
    "

    db_multirow multirow hours_timesheet $sql
#   multirow_sort_tree multirow project_id parent_id sort_order
    multirow_sort_tree -nosort multirow project_id parent_id sort_order
    set options [list]
    template::multirow foreach multirow {

	set indent ""
	for {set i 0} {$i < $tree_level} { incr i} { append indent "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" }
	lappend options [list "$indent$project_name_shortened" $project_id]

    }

    if {$include_empty} { set options [linsert $options 0 [list $include_empty_name ""]] }
    return $options
}




ad_proc -public im_project_template_options { {include_empty 1} } {
    Get a list of template projects
} {
    set options [db_list_of_lists project_options "
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}




ad_proc -public im_project_template_select { 
    select_name 
    { default "" } 
} {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all projects that qualify as templates.
} {
    set bind_vars [ns_set create]
#    ns_set put $bind_vars project_id $project_id

    # Include the "template_p" field of im_projects IF its defined
    set template_p_sql ""
    if {[im_column_exists im_projects template_p]} {
	set template_p_sql "or template_p='t'"
    }

    set sql "
	select	project_id,
		project_name
	from	im_projects
	where	parent_id is null and
		project_type_id not in ([im_project_type_task], [im_project_type_ticket]) and
		(lower(project_name) like '%template%' $template_p_sql)
	order by
		lower(project_name)
    "

    return [im_selection_to_select_box -translate_p 0 $bind_vars "project_member_select" $sql $select_name $default]
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



ad_proc -public im_project_select { 
    { -exclude_subprojects_p 1 }
    { -exclude_status_id "" }
    { -exclude_type_id "" }
    { -project_status_id "" }
    { -project_type_id "" }
    { -include_empty_p 0 } 
    { -include_empty_name "" }
    select_name 
    { project_id "" } 
    { default "" } 
    { status "" } 
    { type ""} 
    { exclude_status "" } 
    { member_user_id ""} 
    { company_id ""} 
    { main_projects_maxdepth 0}


} {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the projects in the system. If status is
    specified, we limit the select box to projects matching that
    status. If type is specified, we limit the select box to project
    matching that type. If exclude_status is provided as a list, we
    limit to states that do not match any states in exclude_status.
    If member_user_id is specified, we limit the select box to projects
    where member_user_id participate in some role.
    @param main_projects_maxdepth: Determine the maxdepth if exclude_subprojects_p=1
} {

    if { ![empty_string_p $status] } {
	if {"" != $project_status_id} { ad_return_complaint 1 "im_project_select: duplicate 'status' parameter" }
	set project_status_id [db_string stat "
		select	category_id 
		from	im_categories
		where	category_type = 'Intranet Project Status' and
			lower(category) = lower(:status);
	" -default ""]
    }
    
    if { ![empty_string_p $exclude_status] } {
	if {"" != $exclude_status_id} { ad_return_complaint 1 "im_project_select: duplicate 'exclude_status' parameter" }
	set exclude_status_id [db_string stat "
		select	category_id 
		from	im_categories
		where	category_type = 'Intranet Project Status' and
			lower(category) = lower(:exclude_status);
	" -default ""]
    }
	
    if { ![empty_string_p $type] } {
	set project_type_id [db_string typ "
		select	category_id 
		from	im_categories
		where	category_type = 'Intranet Project Type' and
			lower(category) = lower(:type);
	" -default ""]
    }

    set project_options [im_project_options \
			     -include_empty $include_empty_p \
			     -include_empty_name $include_empty_name \
			     -exclude_subprojects_p $exclude_subprojects_p \
			     -exclude_status_id $exclude_status_id \
			     -exclude_type_id $exclude_type_id \
			     -project_status_id $project_status_id \
			     -project_type_id $project_type_id \
			     -member_user_id $member_user_id \
			     -company_id $company_id \
    ]

    set options_html ""
    foreach option $project_options {
        set value [lindex $option 0]
        set id [lindex $option 1]

	if { [string equal $id $project_id] } {
	    append options_html "\t\t<option selected=\"selected\" value=\"$id\">$value</option>\n"
	} else {
	    append options_html "\t\t<option value=\"$id\">$value</option>\n"	
	}
    }

    return "
	<select name=\"$select_name\">
	$options_html
	</select>
    "
}


ad_proc -public im_project_personal_active_projects_component {
    {-show_empty_project_list_p 1}
    {-view_name "project_personal_list" }
    {-order_by_clause ""}
    {-project_type_id 0}
    {-project_status_id 0}
} {
    Returns a HTML table with the list of projects of the
    current user. Don't do any fancy with sorting and
    pagination, because a single user won't be a member of
    many active projects.

    @param show_empty_project_list_p Should we show an empty project list?
           Setting this parameter to 0 the component will just disappear
           if there are no projects.
} {
    set user_id [ad_get_user_id]

    if {"" == $order_by_clause} {
	set order_by_clause  [parameter::get_from_package_key -package_key "intranet-core" -parameter "HomeProjectListSortClause" -default "project_nr DESC"]
    }

    # ---------------------------------------------------------------
    # Columns to show:

    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
    set column_headers [list]
    set column_vars [list]
    set extra_selects [list]
    set extra_froms [list]
    set extra_wheres [list]

    set column_sql "
	select
		column_name,
		column_render_tcl,
		visible_for,
	        extra_where,
	        extra_select,
	        extra_from
	from
		im_view_columns
	where
		view_id=:view_id
		and group_id is null
	order by
		sort_order
    "
    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
    }

    # ---------------------------------------------------------------
    # Generate SQL Query

    set extra_select [join $extra_selects ",\n\t"]
    if { ![empty_string_p $extra_select] } {
	set extra_select ",\n\t$extra_select"
    }

    set extra_from [join $extra_froms ",\n\t"]
    if { ![empty_string_p $extra_from] } {
	set extra_from ",\n\t$extra_from"
    }

    set extra_where [join $extra_wheres "and\n\t"]
    if { ![empty_string_p $extra_where] } {
	set extra_where "and\n\t$extra_where"
    }


    if {0 == $project_status_id} { set project_status_id [im_project_status_open] }

    # Project Status restriction
    set project_status_restriction ""
    if {0 != $project_status_id} {
	set project_status_restriction "and p.project_status_id in ([join [im_sub_categories $project_status_id] ","])"
    }

    # Project Type restriction
    set project_type_restriction ""
    if {0 != $project_type_id} {
	set project_type_restriction "and p.project_type_id in ([join [im_sub_categories $project_type_id] ","])"
    }

    set perm_sql "
	(select
	        p.*
	from
	        im_projects p,
		acs_rels r
	where
		r.object_id_one = p.project_id and
		r.object_id_two = :user_id and
		p.parent_id is null and
		p.project_type_id not in ([im_project_type_task], [im_project_type_ticket]) and
		p.project_status_id not in ([im_project_status_deleted], [im_project_status_closed])
		$project_status_restriction
		$project_type_restriction
	)"

    set personal_project_query "
	SELECT
		p.*,
		to_char(p.end_date, 'YYYY-MM-DD HH24:MI') as end_date_formatted,
	        c.company_name,
	        im_name_from_user_id(project_lead_id) as lead_name,
	        im_category_from_id(p.project_type_id) as project_type,
	        im_category_from_id(p.project_status_id) as project_status,
	        to_char(end_date, 'HH24:MI') as end_date_time
                $extra_select
	FROM
		$perm_sql p,
		im_companies c
                $extra_from
	WHERE
		p.company_id = c.company_id
		$project_status_restriction
		$project_type_restriction
                $extra_where
	order by $order_by_clause
    "

    
    # ---------------------------------------------------------------
    # Format the List Table Header

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    set table_header_html "<tr>\n"
    foreach col $column_headers {
	regsub -all " " $col "_" col_txt
	set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
	append table_header_html "  <td class=rowtitle>$col_txt</td>\n"
    }
    append table_header_html "</tr>\n"


    # ---------------------------------------------------------------
    # Format the Result Data

    set url "index?"
    set table_body_html ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set ctr 0
    db_foreach personal_project_query $personal_project_query {

	set url [im_maybe_prepend_http $url]
	if { [empty_string_p $url] } {
	    set url_string "&nbsp;"
	} else {
	    set url_string "<a href=\"$url\">$url</a>"
	}
	
	# Append together a line of data based on the "column_vars" parameter list
	set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
	foreach column_var $column_vars {
	    append row_html "\t<td valign=top>"
	    set cmd "append row_html $column_var"
	    eval "$cmd"
	    append row_html "</td>\n"
	}
	append row_html "</tr>\n"
	append table_body_html $row_html
	
	incr ctr
    }

    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {

	# Let the component disappear if there are no projects...
	if {!$show_empty_project_list_p} { return "" }

	set table_body_html "
	    <tr><td colspan=\"$colspan\"><ul><li><b> 
	    [lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
	    </b></ul></td></tr>
	"
    }
    return "
	<table class=\"table_component\" width=\"100%\">
	<thead>$table_header_html</thead>
	<tbody>$table_body_html</tbody>
	</table>
    "
}




ad_proc -public im_project_hierarchy_component {
    -project_id
    {-return_url "" }
    {-subproject_status_id "none"}
    {-view_name "project_hierarchy" }
} {
    Returns a HTML table with a hierarchical view to the
    specified project. Allows the user to open/close the
    sub-projects.
} {
    if {"" == $return_url} { set return_url [im_url_with_query] }
    set params [list  [list base_url "/intranet-core/"]  [list project_id $project_id] [list subproject_status_id "none"] [list view_name "project_hierarchy"] [list return_url $return_url]]

    set result [ad_parse_template -params $params "/packages/intranet-core/lib/project-hierarchy"]
    return [string trim $result]
}


# ---------------------------------------------------------------------
# Cloning Procs
# ---------------------------------------------------------------------

ad_proc im_project_clone {
    {-clone_costs_p "" }
    {-clone_files_p "" }
    {-clone_folders_p "" }
    {-clone_subprojects_p "" }
    {-clone_forum_topics_p "" }
    {-clone_members_p "" }
    {-clone_timesheet_tasks_p "" }
    {-clone_target_languages_p "" }
    {-clone_trans_tasks_p "" }
    {-company_id 0}
    {-debug_p 1}
    parent_project_id 
    project_name 
    project_nr 
    clone_postfix
} {
    Recursively clone projects.
    ToDo: Start working with Service Contracts to allow other modules
    to include their clone routines.
} {

    if {"" == $clone_members_p} { set clone_members_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectMembersP" -default 1] }
    if {"" == $clone_costs_p} { set clone_costs_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectCostsP" -default 0] }
    if {"" == $clone_trans_tasks_p} { set clone_trans_tasks_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTransTasksP" -default 0] }
    if {"" == $clone_timesheet_tasks_p} { set clone_timesheet_tasks_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTimesheetTasksP" -default 1] }
    if {"" == $clone_target_languages_p} { set clone_target_languages_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTargetLanguagesP" -default 1] }
    if {"" == $clone_forum_topics_p} { set clone_forum_topics_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectForumTopicsP" -default 1] }
    if {"" == $clone_files_p} { set clone_files_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectFsFilesP" -default 1] }
    if {"" == $clone_folders_p} { set clone_folders_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectFsFoldersP" -default 1] }
    if {"" == $clone_subprojects_p} { set clone_subprojects_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectSubprojectsP" -default 1] }

    set errors "<p>&nbsp;<li><b>Starting to clone project \#$parent_project_id => $project_nr / $project_name</b><p>\n"

    # --------------------------------------------
    # Clone the project & dynfields
    #
    append errors "<li>Starting to clone base data\n"
    set cloned_project_id [im_project_clone_base $parent_project_id $project_name $project_nr $company_id $clone_postfix]
    append errors "<li>Finished to clone base data\n"

    # --------------------------------------------
    # Clone the project

    append errors [im_project_clone_base2 $parent_project_id $cloned_project_id]
    append errors [im_project_clone_url_map $parent_project_id $cloned_project_id]

    if {$clone_members_p} {
	append errors [im_project_clone_members $parent_project_id $cloned_project_id]
    }

    if {$clone_files_p} {
	append errors [im_project_clone_files $parent_project_id $cloned_project_id]
    }
    if {$clone_files_p} {
	append errors [im_project_clone_folders $parent_project_id $cloned_project_id]
    }
    if {$clone_trans_tasks_p && [im_table_exists "im_trans_tasks"]} {
	append errors [im_project_clone_trans_tasks $parent_project_id $cloned_project_id]
    }
    if {$clone_target_languages_p && [im_table_exists "im_target_languages"]} {
	append errors [im_project_clone_target_languages $parent_project_id $cloned_project_id]
    }
    if {$clone_forum_topics_p && [im_table_exists "im_forum_topics"]} {
        append errors [im_project_clone_forum_topics $parent_project_id $cloned_project_id]
    }
    if {$clone_costs_p && [im_table_exists "im_costs"]} {
        append errors [im_project_clone_costs $parent_project_id $cloned_project_id]
    }

    if {$debug_p} { ns_write "$errors\n" }

    if {$clone_subprojects_p} {

	if {$debug_p} { ns_write "<li>im_project_clone: subprojects parent_project_id=$parent_project_id cloned_project_id=$cloned_project_id\n" }
	# Use a list of subprojects and then "foreach" in order to avoid nested SQLs
	set subprojects_sql "
		select	project_id as sub_project_id
		from	im_projects
		where 	parent_id = :parent_project_id and
			project_type_id not in ([im_project_type_task])
	"
	set subproject_list [db_list subprojects $subprojects_sql]
	foreach sub_project_id $subproject_list {

	    db_1row project_info "
		select	project_nr || :cloned_project_id as sub_project_nr,
			project_name || :cloned_project_id as sub_project_name,
			project_nr as sub_project_nr_org,
			project_name as sub_project_name_org
		from	im_projects
		where	project_id = :sub_project_id
	    "

	    # go for the next project
	    if {$debug_p} { ns_write "<li>im_project_clone: Clone subproject $sub_project_name\n" }
	    if {$debug_p} { ns_write "<ul>\n" }
	    set cloned_subproject_id [im_project_clone \
					  -clone_costs_p $clone_costs_p \
					  -clone_files_p $clone_files_p \
					  -clone_subprojects_p $clone_subprojects_p \
					  -clone_forum_topics_p $clone_forum_topics_p \
					  -clone_members_p $clone_members_p \
					  -clone_timesheet_tasks_p $clone_timesheet_tasks_p \
					  -clone_trans_tasks_p $clone_trans_tasks_p \
					  -clone_target_languages_p $clone_target_languages_p \
					  -company_id $company_id \
					  $sub_project_id \
					  $sub_project_name \
					  $sub_project_nr \
					  $clone_postfix \
	    ]
	    if {$debug_p} { ns_write "</ul>\n" }

	    # We can _now_ reset the subproject's name to the original one
	    db_dml set_parent "
		update	im_projects
		set
			parent_id = :cloned_project_id,
			project_nr = :sub_project_nr_org,
			project_name = :sub_project_name_org,
			template_p = 'f'
		where
			project_id = :cloned_subproject_id
	    "
	}
	if {"" == $subproject_list} { 
	    if {$debug_p} { ns_write "<li>No subprojects found\n" }
	}
    }


    if {$clone_timesheet_tasks_p && [im_table_exists "im_timesheet_tasks"]} {

	if {$debug_p} { ns_write "<li>im_project_clone: timesheet tasks: parent=$parent_project_id cloned=$cloned_project_id\n" }
	# Use a list of tasks and then "foreach" in order to avoid nested SQLs
	set task_list [db_list tasks "
		select	project_id
		from	im_projects
		where 	parent_id = :parent_project_id and
			project_type_id = [im_project_type_task]
	"]

	foreach task_id $task_list {

	    db_1row project_info "
		select	p.project_nr || '_' || :cloned_project_id as sub_task_nr,
			p.project_name || '_' || :cloned_project_id as sub_task_name,
			p.project_nr as sub_task_nr_org,
			p.project_name as sub_task_name_org
		from	im_projects p
		where	project_id = :task_id

	    "

	    # go for the next project
	    if {$debug_p} { ns_write "<li>im_project_clone: Clone task $sub_task_name\n" }
	    if {$debug_p} { ns_write "<ul>\n" }
	    set cloned_task_id [im_project_clone \
				    -clone_costs_p $clone_costs_p \
				    -clone_files_p $clone_files_p \
				    -clone_subprojects_p $clone_subprojects_p \
				    -clone_forum_topics_p $clone_forum_topics_p \
				    -clone_members_p $clone_members_p \
				    -clone_timesheet_tasks_p $clone_timesheet_tasks_p \
				    -clone_trans_tasks_p $clone_trans_tasks_p \
				    -clone_target_languages_p $clone_target_languages_p \
				    -company_id $company_id \
				    $task_id \
				    $sub_task_name \
				    $sub_task_nr \
				    $clone_postfix \
	    ]
	    if {$debug_p} { ns_write "</ul>\n" }

	    # We can _now_ reset the subtasks's name to the original one
	    db_dml set_parent "
		update	im_projects
		set
			parent_id = :cloned_project_id,
			project_nr = :sub_task_nr_org,
			project_name = :sub_task_name_org
		where
			project_id = :cloned_task_id
	    "

	    if {[db_0or1row task_info "
			select	material_id, uom_id,
	                        planned_units, billable_units,
	                        cost_center_id, invoice_id, priority, sort_order
			from	im_timesheet_tasks
			where	task_id = :task_id
	        "]
	    } {
		# Insert a task
		db_dml insert_task "
		insert into im_timesheet_tasks (
			task_id, material_id, uom_id,
			planned_units, billable_units,
			cost_center_id, invoice_id, priority, sort_order
		) values (
			:cloned_task_id, :material_id, :uom_id,
			:planned_units, :billable_units,
			:cost_center_id, :invoice_id, :priority, :sort_order
		)
	        "
	    }

            # update acs_object
            db_dml update_acs_objects "
		update acs_objects set object_type = 'im_timesheet_task' where object_id = :cloned_task_id 
            "
	}
	if {"" == $task_list} { 
	    if {$debug_p} { ns_write "<li>No tasks found\n" }
	}

    }

    # User Exit
    im_user_exit_call project_create $cloned_project_id
    im_audit -object_type im_project -action after_create -object_id $cloned_project_id

    return $cloned_project_id
}


ad_proc im_project_clone_base {
    {-debug 0}
    parent_project_id
    project_name
    project_nr
    new_company_id
    clone_postfix
} {
    Create the minimum information for a clone project
    with a new name and project_nr for unique constraint reasons.
} {
    if {$debug} { ns_log Notice "im_project_clone_base parent_project_id=$parent_project_id project_name=$project_name project_nr=$project_nr new_company_id=$new_company_id clone_postfix=$clone_postfix" }

    set new_project_name $project_name
    set new_project_nr $project_nr
    set current_user_id [ad_get_user_id]

    # --------------------------
    # Prepare Project SQL Query
    
    set query "
	select	p.*,
		o.object_type
	from	im_projects p,
		acs_objects o
	where 	p.project_id = o.object_id and
		p.project_id = :parent_project_id
    "
    if { ![db_0or1row projects_info_query $query] } {
	set project_id $parent_project_id
	ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
	return
    }

    # Take the new_company_id from the procedure parameters
    # and overwrite the information from the parent project
    # This is useful if somebody wants to "clone" a project,
    # but execute the project for the "internal" company.
    if {0 != $new_company_id && "" != $new_company_id} {
	set company_id $new_company_id
    }

    # ------------------------------------------
    # Fix name and project_nr
    
    # Create a new project_nr if it wasn't specified
    if {"" == $new_project_nr} {
	set new_project_nr [im_next_project_nr]
    }

    # Use the parents project name if none was specified
    if {"" == $new_project_name} {
	set new_project_name $project_name
    }

    # Append "Postfix" to project name if it already exists:
    while {[db_string count "select count(*) from im_projects where project_name = :new_project_name"]} {
	set new_project_name "$new_project_name - $clone_postfix"
    }

    # -------------------------------
    # Create the new project
    set cloned_project_id [project::new \
		-project_name		$new_project_name \
		-project_nr		$new_project_nr \
		-project_path		$new_project_nr \
		-company_id		$company_id \
		-parent_id		$parent_id \
		-project_type_id	$project_type_id \
		-project_status_id	$project_status_id \
		-parent_id		$parent_project_id \
    ]
    if {0 == $cloned_project_id} {
	ad_return_complaint 1 "<b>Error creating clone project</b>:<br>
		Project Name: '$new_project_name'<br>
		Project Nr: '$new_project_nr'<br>
	"
	return 0
    }

    db_dml update_project "
	update im_projects set
		parent_id = :parent_id,
		description = :description,
		billing_type_id = :billing_type_id,
		start_date = :start_date,
		end_date = :end_date,
		note = :note,
		project_lead_id = :project_lead_id,
		supervisor_id = :supervisor_id,
		requires_report_p = :requires_report_p,
		project_budget = :project_budget,
		project_budget_currency = :project_budget_currency,
		project_budget_hours = :project_budget_hours,
		percent_completed = :percent_completed,
		on_track_status_id = :on_track_status_id
	where
		project_id = :cloned_project_id
    "

    # Not cloning template_p. This is meta-information that shouldn't get copied.
    #		template_p = :template_p

    # Fix the object_type of the new project.
    # Project sub-types include im_timesheet_task, im_ticket etc.
    db_dml update_object "
	update acs_objects set
		object_type = :object_type
	where
		object_id = :cloned_project_id
    "

    # Make sure it has the correct project_name and so on
    set project_name $new_project_name
    set project_nr $new_project_nr
    set project_path $new_project_nr

    # Clone DynFields - just all of them
    set dynfield_sql [im_dynfield::create_clone_update_sql -object_type "im_project" -object_id $cloned_project_id]
    db_dml update_dynfields $dynfield_sql

    return $cloned_project_id
}




ad_proc im_project_clone_base2 {
    {-debug 0}
    parent_project_id
    new_project_id
} {
    copy project structure
} {
    if {$debug} { ns_log Notice "im_project_clone_base2 parent_project_id=$parent_project_id new_project_id=$new_project_id" }
    set errors "<li>Starting to clone base2 data: parent_project_id=$parent_project_id new_project_id=$new_project_id"

    set query "
	select	p.*
	from	im_projects p
	where 	p.project_id = :parent_project_id
    "

    if { ![db_0or1row projects_info_query $query] } {
	append errors "<li>[_ intranet-core.lt_Cant_find_the_project]"
	return $errors
    }


    # -----------------------------------------
    # Update project fields
    # Cover all fields that are not been used in project generation

    # Translation Only
    if {[im_table_exists im_trans_tasks]} {
	set project_update_sql "
	update im_projects set
		company_project_nr =	:company_project_nr,
		company_contact_id =	:company_contact_id,
		source_language_id =	:source_language_id,
		subject_area_id =	:subject_area_id,
		expected_quality_id =	:expected_quality_id,
		final_company =		:final_company,
		trans_project_words =	:trans_project_words,
		trans_project_hours =	:trans_project_hours
	where
		project_id = :new_project_id
	"
	db_dml project_update $project_update_sql
    }

    # ToDo: Add stuff for consulting projects

    # DON't clone caches. It's better to leave them emtpy.
    # They're inconsisten anyway, because we may or may have
    # not cloned subprojects and their cost elements
#    if {[im_table_exists im_costs]} {
#	set project_update_sql "
#	update im_projects set
#		cost_quotes_cache =		:cost_quotes_cache,
#		cost_invoices_cache =		:cost_invoices_cache,
#		cost_timesheet_planned_cache =	:cost_timesheet_planned_cache,
#		cost_purchase_orders_cache =	:cost_purchase_orders_cache,
#		cost_bills_cache =		:cost_bills_cache,
#		cost_timesheet_logged_cache =	:cost_timesheet_logged_cache
#	where
#		project_id = :new_project_id
#	"
#	db_dml project_update $project_update_sql
#
#    }

    append errors "<li>Finished to clone base2 data"
    return $errors
}




ad_proc im_project_clone_members {
    {-debug 0}
    parent_project_id 
    new_project_id
} {
    Copy projects members and administrators
} {
    if {$debug} { ns_log Notice "im_project_clone_members parent_project_id=$parent_project_id new_project_id=$new_project_id" }
    set errors "<li>Starting to clone member information"
    set current_user_id [ad_get_user_id]

    if {![db_0or1row project_info "
	select  p.*
	from    im_projects p
	where   p.project_id = :parent_project_id
    "]} {
	ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
	return
    }

    # -----------------------------------------------
    # Add Project Manager roles
    # - current_user (creator/owner)
    # - project_leader
    # - supervisor
    set admin_role_id [im_biz_object_role_project_manager]
    im_biz_object_add_role $current_user_id $new_project_id $admin_role_id 
    if {"" != $supervisor_id} { im_biz_object_add_role $supervisor_id $new_project_id $admin_role_id }
    if {"" != $project_lead_id} { im_biz_object_add_role $project_lead_id $new_project_id $admin_role_id }

    # -----------------------------------------------
    # Add Project members in their roles
    # There are other elements with relationships (invoices, ...),
    # but these are added when the other types of objects are
    # added to the project.

    set rels_sql "
	select 
		r.*,
		m.object_role_id,
		o.object_type
	from 
		acs_rels r 
			left outer join im_biz_object_members m 
			on r.rel_id = m.rel_id,
		acs_objects o
	where 
		r.object_id_two = o.object_id
		and r.object_id_one=:parent_project_id
    "
    db_foreach get_rels $rels_sql {
	if {"" != $object_role_id && "user" == $object_type} {
	    im_biz_object_add_role $object_id_two $new_project_id $object_role_id
	}
    }
    append errors "<li>Finished to clone member information"
    return $errors
}

    
ad_proc im_project_clone_url_map {parent_project_id new_project_id} {
    Copy projects URL Map
} {
    ns_log Notice "im_project_clone_url_map parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone url map information"

    set url_map_sql "
	select url_type_id, url
	from im_project_url_map
	where project_id = :parent_project_id
    "
    db_foreach url_map $url_map_sql {
	db_dml create_new_pum "
	    insert into im_project_url_map 
		(project_id, url_type_id, url)
	    values
		(:project_id,:url_type_id,:url)
	"
    }
    append errors "<li>Finished to clone url map information"
    return $errors
}


ad_proc im_project_clone_costs {
    parent_project_id 
    new_project_id
} {
    Copy cost items and invoices.
    There are three ugly options to perform a clone of a cost item:

    1. Use the cost class constructors (im_expense__new(...)).
       Disadvantage: These constructors don't copy all fields, so we'd
       need additional UPDATE... statements to capture the forgotten fields

    2. Use a common im_cost via im_cost__new() and then insert the class
       specific extension table manually. Kinda ugly...

    3. Cleanest probably but difficult to maintain either: 
       Introduce new PL/SQL routines im_xxxx__clone().

    => Let's kepp the shit together in a single procedure, instead of
       distributing it to a number of little piles...
} {
    ns_log Notice "im_project_clone_costs parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set current_user_id [ad_get_user_id]

    # Extract all cost items related to the current (sub-) project.
    # Don't descend to sub-projects, because this procedure is called for
    # each sub-project cloned.

    # ToDo: Deal with the case that one cost_item is related to two sub-
    # projects, so that the items is not duplicated!

    set costs_sql "
	select distinct
		c.*, i.*, e.*, rc.*, ti.*,
		c.project_id as org_cost_project_id,
		o.object_type
	from
		im_projects p,
		acs_objects o,
		acs_rels r,
		im_costs c
		left outer join im_invoices i on c.cost_id = i.invoice_id
		left outer join im_expenses e on c.cost_id = e.expense_id
		left outer join im_repeating_costs rc on c.cost_id = rc.rep_cost_id
		left outer join im_timesheet_invoices ti on c.cost_id = ti.invoice_id
	where
		p.project_id = :parent_project_id and
		r.object_id_one = p.project_id and
		r.object_id_two = c.cost_id and
		c.cost_id = o.object_id
    "

    db_foreach add_costs $costs_sql {

	# "rescue" some values that we'll need later for updates
	set old_cost_id $cost_id

	# Copy the im_cost base object
	set cost_insert_query "select im_cost__new (
		null,			-- cost_id
		:object_type,		-- object_type
		now(),			-- creation_date
		:current_user_id,	-- creation_user
		'[ad_conn peeraddr]',	-- creation_ip
		null,			-- context_id
	
		:cost_name,		-- cost_name
		:parent_id,		-- parent_id
		:new_project_id,	-- project_id
		:customer_id,		-- customer_id
		:provider_id,		-- provider_id
		:investment_id,		-- investment_id
	
		:cost_status_id,	-- cost_status_id
		:cost_type_id,		-- cost_type_id
		:template_id,		-- template_id
	
		:effective_date,	-- effective_date
		:payment_days,  	-- payment_days
		:amount,		-- amount
		:currency,		-- currency
		:vat,			-- vat
		:tax,			-- tax
	
		:variable_cost_p,	-- variable_cost_p
		:needs_redistribution_p, -- needs_redistribution_p
		:redistributed_p,	-- redistributed_p
		:planning_p,		-- planning_p
		:planning_type_id,	-- planning_type_id
	
		:description,		-- description
		:note			-- note
	)"

	# Execute the creation call
	set cost_id [db_exec_plsql cost_insert "$cost_insert_query"]
	set new_cost_id $cost_id

	# Update variables not passed through im_cost__new.
	# Currently this is only cost_center_id.
	db_dml update_cost "
		update im_costs set
			cost_center_id = :cost_center_id
		where cost_id = :cost_id
	"

	# ------------------------------------------------------
	# creation invoice project relation
	if {"" == $org_cost_project_id} {
	    ad_return_complaint 1 "Unable to clone cost item.<br>
		The cost item '$old_cost_id' has project_id=NULL, indicating 
		that it is associated with more then one project.<br>
		This is currently not supported
	    "
	    ad_script_abort
	}

	set rel_count [db_string rel_count "select count(*) from acs_rels where object_id_one = :new_project_id and object_id_two = :new_cost_id"]
	if {0 == $rel_count && "" != $new_project_id && "" != $new_cost_id} {
	    set relation_query "select acs_rel__new(
		 null,
		 'relationship',
		 :new_project_id,
		 :new_cost_id,
		 null,
		 null,
		 null
	    )"
	    db_exec_plsql insert_acs_rels "$relation_query"
	}

	# -----------------------------------------------------------
	# Now let's check the object type and perform the object type specific actions.
	switch $object_type {

	    im_cost - im_expense_bundle {
		# -----------------------------------------------------------
		# Basic costs, consisting only of an im_cost item
		# Do nothing, because the im_cost item has already been cloned.
	    }

	    im_invoice - im_trans_invoice - im_timesheet_invoice {
		# -----------------------------------------------------------
		# Covers Customer Invoice, Quote, Delivery Note, Bill and Purchase Order.
		# These costs are stored in im_costs, in_invoices and im_invoice_items

		set invoice_nr [im_next_invoice_nr -cost_type_id $cost_type_id]

		set invoice_sql "
		insert into im_invoices (
			invoice_id,
			company_contact_id,
			invoice_nr,
			payment_method_id
		) values (
			:new_cost_id,
			:company_contact_id,
			:invoice_nr,
			:payment_method_id
		)
	        "
		db_dml invoice_insert $invoice_sql

		# create invoice items
		set invoice_sql "select * from im_invoice_items where invoice_id = :old_cost_id"
		db_foreach add_invoice_items $invoice_sql {
		    set new_item_id [db_nextval "im_invoice_items_seq"]
		    set insert_invoice_items_sql "
			INSERT INTO im_invoice_items (
				item_id, item_name, project_id, invoice_id, 
				item_units, item_uom_id, price_per_unit, currency, 
				sort_order, item_type_id, item_status_id, description
			) VALUES (
				:new_item_id, :item_name, :new_project_id, :new_cost_id, 
				:item_units, :item_uom_id, :price_per_unit, :currency, 
				:sort_order, :item_type_id, :item_status_id, :description
			)
                    "
		    db_dml insert_invoice_items $insert_invoice_items_sql
		
		}

	    }

	    im_expense {
		# -----------------------------------------------------------
		# Expenses consist of im_cost and im_expenses entries
		ad_return_complaint 1 "Cloning expenses is not supported yet"
		
	    }
	    
	    im_repeating_cost {
		# Should not appear related to a project - at the moment
		ad_return_complaint 1 "Cloning repeating_costs is not supported yet"
		ad_script_abort
	    }
	}


	if {"im_timesheet_invoice" == $object_type} {
	    # Add a single entry to the normal im_invoice
	    db_dml ts_invoice_insert "
		insert into im_timesheet_invoices (
			invoice_id,
			invoice_period_start,
			invoice_period_end
		) values (
			:new_cost_id,
			:invoice_period_start,
			:invoice_period_end
		);
	    "
	}

	
    }
}

ad_proc im_project_clone_trans_tasks {
    parent_project_id 
    new_project_id
} {
    Copy translation tasks and assignments
} {
    ns_log Notice "im_project_clone_trans_tasks parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone translation tasks"

    im_exec_dml clone_project_tasks "im_trans_task__project_clone (:parent_project_id, :new_project_id)"

    append errors "<li>Finished to clone translation tasks"
    return $errors
}

ad_proc im_project_clone_target_languages {parent_project_id new_project_id} {
    Copy target languages and assignments
} {
    ns_log Notice "im_project_clone_target_languages parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone target languages"

    if {[catch { db_dml target_languages "insert into im_target_languages (
		project_id,
		language_id
	    ) (
	    select 
		:new_project_id,
		language_id
	    from 
		im_target_languages 
	    where 
		project_id = :parent_project_id
	)
    "} errmsg ]} {
	append errors "<li><pre>$errmsg\n</pre>"
    }
    append errors "<li>Finished to clone target languages"
    return $errors
}


ad_proc im_project_clone_payments {parent_project_id new_project_id} {
    Copy payments
} {
    ns_log Notice "im_project_clone_payments parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone payments"

    set payments_sql "select * from im_payments where cost_id = :old_cost_id"
    db_foreach add_payments $payments_sql {
	set old_payment_id $payment_id
	set payment_id [db_nextval "im_payments_id_seq"]
	db_dml new_payment_insert "
			insert into im_payments ( 
				payment_id, 
				cost_id,
				company_id,
				provider_id,
				amount, 
				currency,
				received_date,
				payment_type_id,
				note, 
				last_modified, 
				last_modifying_user, 
				modified_ip_address
			) values ( 
				:payment_id, 
				:new_cost_id,
				:company_id,
				:provider_id,
			:amount, 
				:currency,
				:received_date,
				:payment_type_id,
			:note, 
				(select sysdate from dual), 
				:user_id, 
				'[ns_conn peeraddr]' 
			)"
		
    }
    append errors "<li>Finished to clone payments \#$parent_project_id"
    return $errors
}


ad_proc im_project_clone_timesheet {parent_project_id new_project_id} {
    Copy timesheet information(?)
} {
    ns_log Notice "im_project_clone_timesheet parent_project_id=$parent_project_id new_project_id=$new_project_id"

    set timesheet_sql "
	select 
		user_id as usr,
		day,
	  	hours,
	  	billing_rate,
	  	billing_currency,
	  	note 
	from 
		im_hours
	where 
		project_id = :parent_project_id
    "
    db_foreach timesheet $timesheet_sql {
	db_dml add_timesheet "
		insert into im_hours 
		(user_id,project_id,day,hours,billing_rate, billing_currency, note)
		values
		(:usr,:new_project_id,:day,:hours,:billing_rate, :billing_currency, :note)
	    "
    }
}

	
ad_proc im_project_clone_forum_topics {parent_project_id new_project_id} {
    Copy forum topics
} {
    ns_log Notice "im_project_clone_forum_topics parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone forum topics"

    db_dml topic_delete "delete from im_forum_topics where object_id=:new_project_id"

    set forum_sql "
	select
		* 
	from
		im_forum_topics 
	where 
		object_id = :parent_project_id
		and not exists (
			select topic_id
			from im_forum_topics
			where object_id = 1111
		)
    " 
    db_foreach forum_topics $forum_sql {
	set old_topic_id $topic_id
	set topic_id [db_nextval "im_forum_topics_seq"]

	append errors "<li>Cloning forum topic #$topic_id"

	db_dml topic_insert {
		insert into im_forum_topics (
			topic_id, object_id, topic_type_id, 
			topic_status_id, owner_id, subject
		) values (
			:topic_id, :new_project_id, :topic_type_id, 
			:topic_status_id, :owner_id, :subject
		)
	}
	# ------------------------------------------------
	# create forums files

	set new_topic_id $topic_id
	db_foreach "get forum files" "select * from im_forum_files where msg_id = :old_topic_id" {
	    db_dml "create forum file" "insert into im_forum_files (
		msg_id,n_bytes,
		client_filename, 
		filename_stub,
		caption,content
	    ) values (
		:new_topic_id,:n_bytes,
		:client_filename, 
		:filename_stub,
		:caption,
		:content
	    )"
		
	}
		
	# ------------------------------------------------
	# create forums folders

	# ------------------------------------------------
	# create forum topics user map
	
    }

    append errors "<li>Finished to clone forum topics \#$parent_project_id"
    return $errors
}


ad_proc im_project_clone_files {parent_project_id new_project_id} {
    Copy all files and subdirectories from parent to the new project
} {
    ns_log Notice "im_project_clone_files parent_project_id=$parent_project_id new_project_id=$new_project_id"

    set errors "<li>Starting to clone files\n"

    # Base pathes don't contain a trailing slash
    set parent_base_path [im_filestorage_project_path $parent_project_id]
    set new_base_path [im_filestorage_project_path $new_project_id]

    if { [catch {
	# Copy all files from parent to new project
	# "cp" behaves a bit strange, it creates the parents
	# directory in the new_base_path if the new_base_path
	# exist. So DON't create the target directory.
	# "cp -a" preserves the ownership information of
	# the original file, so permissions should be OK.
	#
#	exec /bin/mkdir -p $parent_base_path
#	exec /bin/mkdir -p $new_base_path
	exec /bin/cp -a $parent_base_path $new_base_path

    } err_msg] } {
	append errors "<li>Error whily copying files from $parent_base_path to $new_base_path:<pre>$err_msg</pre>\n"
    }

    append errors "<li>Finished to clone files \#$parent_project_id\n"
    return $errors
}


ad_proc im_project_clone_folders {parent_project_id new_project_id} {
    Copy folders and folder permissions to new project
} {
    ns_log Notice "im_project_clone_folders parent_project_id=$parent_project_id new_project_id=$new_project_id"

    set errors "<li>Starting to clone folders\n"

    # Loop through a list structure in order to avoid nested SQLs
    set folder_list [db_list_of_lists project_folders "
	select	folder_id, path, folder_type_id, description
	from	im_fs_folders
	where	object_id = :parent_project_id
    "]
    foreach folder_info $folder_list {
	set parent_project_folder_id [lindex $folder_info 0]
	set folder_path [lindex $folder_info 1]
	set folder_type_id [lindex $folder_info 2]
	set folder_description [lindex $folder_info 3]

	if {"" == [string trim $folder_path]} { continue }

	set new_project_folder_id [db_string cnt "
		select	f.folder_id
		from	im_fs_folders f
		where	f.path = :folder_path and
			f.object_id = :new_project_id
	" -default 0]
	if {0 == $new_project_folder_id} {
	    set new_project_folder_id [db_nextval "im_fs_folder_seq"]
	    db_dml insert_folder "
		insert into im_fs_folders (
			folder_id, object_id, path, 
			folder_type_id, description
		) values (
			:new_project_folder_id, :new_project_id, :folder_path,
			:folder_type_id, :folder_description
		)
	    "
	}

	set perm_list [db_list_of_lists perms "
		select	profile_id, view_p, read_p, write_p, admin_p
		from	im_fs_folder_perms
		where	folder_id = :parent_project_folder_id
	"]
	foreach perm_info $perm_list {
	    set perm_profile_id [lindex $perm_info 0]
	    set perm_view_p [lindex $perm_info 1]
	    set perm_read_p [lindex $perm_info 2]
	    set perm_write_p [lindex $perm_info 3]
	    set perm_admin_p [lindex $perm_info 4]
	    
	    set perm_count [db_string perm_cnt "
			select	count(*)
			from	im_fs_folder_perms
			where	folder_id = :new_project_folder_id and profile_id = :perm_profile_id
	    "]
	    if {0 == $perm_count} {
		db_dml insert_folder "
			insert into im_fs_folder_perms (
				folder_id, profile_id, 
				view_p, read_p, write_p, admin_p
			) values (
				:new_project_folder_id, :perm_profile_id, 
				:perm_view_p, :perm_read_p, :perm_write_p, :perm_admin_p
			)
		"
	    }
	}
    }

    append errors "<li>Finished to clone folders \#$parent_project_id\n"
    return $errors
}


ad_proc im_project_nuke {
    {-current_user_id 0}
    project_id
} {
    Nuke (complete delete from the database) a project.
    Returns an empty string if everything was OK or an error
    string otherwise.
} {
    ns_log Notice "im_project_nuke: project_id=$project_id"
    
    # Use a predefined user_id to avoid a call to ad_get_user_id.
    # ad_get_user_id's connection isn't defined during a DELETE REST request.
    ns_log Notice "im_project_nuke: before ad_get_user_id"
    if {0 == $current_user_id} { 
	ns_log Notice "im_project_nuke: No current_user_id specified - using ad_get_user_id"
	set current_user_id [ad_get_user_id] 
    }

    # Check for permissions
    ns_log Notice "im_project_nuke: before im_project_permissions"
    im_project_permissions $current_user_id $project_id view read write admin
    if {!$admin} { return "User #$currrent_user_id isn't a system administrator" }

    # Write Audit Trail
    ns_log Notice "im_project_nuke: before im_project_audit"
    im_project_audit -user_id $current_user_id -project_id $project_id -action before_nuke

    # ---------------------------------------------------------------
    # Delete
    # ---------------------------------------------------------------
    
    # if this fails, it will probably be because the installation has 
    # added tables that reference the users table

    ns_log Notice "im_project_nuke: before db_transaction"
    db_transaction {
    
	# Helpdesk Tickets
        if {[im_table_exists im_tickets]} {
	    db_dml del_tickets "delete from im_tickets where ticket_id = :project_id"
	}


	# Permissions
	ns_log Notice "projects/nuke-2: acs_permissions"
	db_dml perms "delete from acs_permissions where object_id = :project_id"
	
	# Deleting cost entries in acs_objects that are "dangeling", i.e. that don't have an
	# entry in im_costs. These might have been created during manual deletion of objects
	# Very dirty...
	ns_log Notice "projects/nuke-2: dangeling_costs"
	db_dml dangeling_costs "
		delete from acs_objects 
		where	object_type = 'im_cost' 
			and object_id not in (select cost_id from im_costs)"
	

	# Payments
	db_dml reset_payments "
		update im_payments 
		set cost_id=null 
		where cost_id in (
			select cost_id 
			from im_costs 
			where project_id = :project_id
		)"
	
	# Costs
	db_dml reset_invoice_items "
		update im_invoice_items 
		set project_id = null 
		where project_id = :project_id"

	set cost_infos [db_list_of_lists costs "
		select cost_id, object_type 
		from im_costs, acs_objects 
		where cost_id = object_id and project_id = :project_id
	"]
	foreach cost_info $cost_infos {
	    set cost_id [lindex $cost_info 0]
	    set object_type [lindex $cost_info 1]

            # Delete Multiple-Values associated to this cost item ("Canned Notes")
            db_dml del_multi_values "delete from im_dynfield_attr_multi_value where object_id = :cost_id"

            # Delete references from im_hours to im_costs.
	    db_dml hours_costs_link "update im_hours set cost_id = null where cost_id = :cost_id"

	    # ToDo: Remove this.
	    # Instead, the referencing im_expense_bundles (data type doesn't exist yet)
	    # should be deleted with the appropriate destructor method
	    db_dml expense_cost_link "update im_expenses set bundle_id = null where bundle_id = :cost_id"

	    ns_log Notice "projects/nuke-2: deleting cost: Delete any created_from_item_id references to the items we need to delete"
	    db_dml created_from_item_id "
		update im_invoice_items 
		set created_from_item_id = null 
		where created_from_item_id in (
			select	item_id
			from	im_invoice_items
			where	invoice_id = :cost_id
		)
	    "

	    ns_log Notice "projects/nuke-2: deleting cost: ${object_type}__delete($cost_id)"
	    im_exec_dml del_cost "${object_type}__delete($cost_id)"
	}
	

        # im_notes
        if {[im_table_exists im_notes]} {
            ns_log Notice "projects/nuke-2: im_notes"
            db_dml notes "
                delete from im_notes
                where object_id = :project_id
            "
        }

	# Forum
	ns_log Notice "projects/nuke-2: im_forum_topic_user_map"
	db_dml forum "
		delete from im_forum_topic_user_map 
		where topic_id in (
			select topic_id 
			from im_forum_topics 
			where object_id = :project_id
		)
	"
	ns_log Notice "projects/nuke-2: im_forum_topics"
	db_dml forum "delete from im_forum_topics where object_id = :project_id"


	# Timesheet
	ns_log Notice "projects/nuke-2: im_hours"
	db_dml timesheet "delete from im_hours where project_id = :project_id"
	

	# Workflow
	if {[im_table_exists wf_workflows]} {
	    ns_log Notice "projects/nuke-2: wf_workflows"
	    db_dml wf_tokens "
		delete from wf_tokens
		where case_id in (
			select case_id
			from wf_cases
			where object_id = :project_id
		)
	    "
	    db_dml wf_cases "
		delete from wf_cases
		where object_id = :project_id
	    "
	}
	
	# Translation & Workflow
	if {[im_table_exists wf_workflows] && [im_table_exists im_trans_tasks]} {
	    ns_log Notice "projects/nuke-2: im_trans_tasks & wf_workflows"
	    db_dml wf_tokens "
		delete from wf_tokens
		where case_id in (
			select case_id
			from wf_cases
			where object_id in (
				select task_id
				from im_trans_tasks
				where project_id = :project_id
			)
		)
	    "
	    db_dml wf_cases "
		delete from wf_cases
		where object_id in (
			select task_id
			from im_trans_tasks
			where project_id = :project_id
		)
	    "

	}


	# Translation Quality
	ns_log Notice "projects/nuke-2: im_trans_quality_entries"
	if {[im_table_exists im_trans_quality_reports]} {
	    db_dml trans_quality "
		delete from im_trans_quality_entries 
		where report_id in (
			select report_id 
			from im_trans_quality_reports 
			where task_id in (
				select task_id 
				from im_trans_tasks 
				where project_id = :project_id
			)
		)
	    "
	    ns_log Notice "projects/nuke-2: im_trans_quality_reports"
	    db_dml trans_quality "
		delete from im_trans_quality_reports 
		where task_id in (
			select task_id 
			from im_trans_tasks 
			where project_id = :project_id
		)"
	}

	
	# Translation
	if {[im_table_exists im_trans_tasks]} {
	    ns_log Notice "projects/nuke-2: im_task_actions"
	    db_dml task_actions "
		delete from im_task_actions 
		where task_id in (
			select task_id 
			from im_trans_tasks
			where project_id = :project_id
		)"
	    ns_log Notice "projects/nuke-2: im_trans_tasks"
	    db_dml trans_tasks "
		delete from im_trans_tasks 
		where project_id = :project_id"

	    db_dml trans_tasks "
		delete from acs_objects
		where	object_type = 'im_trans_task'
			and object_id not in (
				select task_id
				from im_trans_tasks
			)
		"

	    db_dml project_target_languages "
		delete from im_target_languages 
		where project_id = :project_id"
	}

	
	# Trans RFCs
	if {[im_table_exists im_trans_rfqs]} {
	    ns_log Notice "projects/nuke-2: im_trans_rfqs"
	    db_dml trans_rfq_answers "
	        delete from im_trans_rfq_answers
		where answer_project_id = :project_id
	    "
	    db_dml trans_rfq_answers "
	        delete from im_trans_rfq_answers
		where answer_rfq_id in (
			select rfq_id
			from im_trans_rfqs
			where rfq_project_id = :project_id
		)
	    "
	    db_dml trans_rfqs "
		delete from im_trans_rfqs
		where rfq_project_id = :project_id
	    "
	}
	
	# Consulting
	if {[im_table_exists im_timesheet_tasks]} {
	    
	    ns_log Notice "projects/nuke-2: im_timesheet_tasks"
	    db_dml task_actions "
		delete from im_hours
		where project_id = :project_id
	    "

	    ns_log Notice "projects/nuke-2: im_timesheet_tasks"
	    db_dml task_actions "
		    delete from im_timesheet_tasks
		    where task_id = :project_id
	    "
	}

	# Helpdesk
	if {[im_table_exists im_tickets]} {
	    ns_log Notice "projects/nuke-2: im_tickets"
	    db_dml tickets "
		    delete from im_tickets
		    where ticket_id = :project_id
	    "
	}

	# GanttProject
	if {[im_table_exists im_timesheet_task_dependencies]} {
	    ns_log Notice "projects/nuke-2: im_timesheet_task_dependencies"
	    db_dml del_dependencies "
		delete from im_timesheet_task_dependencies
		where (task_id_one = :project_id OR task_id_two = :project_id)
	    "
	}

	if {[im_table_exists im_gantt_projects]} {
	    ns_log Notice "projects/nuke-2: im_gantt_projects"
	    db_dml del_gantt_projects "
		delete from im_gantt_projects
		where project_id = :project_id
	    "
	}


	# Skills
	if {[im_table_exists im_object_freelance_skill_map]} {
	
	    ns_log Notice "projects/nuke-2: im_object_freelance_skill_map"
	    db_dml del_skills "
		delete from im_object_freelance_skill_map
		where object_id = :project_id
	    "
	}
	
	# RFQs
	if {[im_table_exists im_freelance_rfqs]} {
	
	    ns_log Notice "projects/nuke-2: im_freelance_rfqs"
	    db_dml del_rfq_answers "
		delete from im_freelance_rfq_answers
		where answer_rfq_id in (
			select	rfq_id
			from	im_freelance_rfqs
			where	rfq_project_id = :project_id
		)
	    "
	    db_dml del_rfqs "
		delete from im_freelance_rfqs
		where rfq_project_id = :project_id
	    "
	}


	
	# Filestorage
	ns_log Notice "projects/nuke-2: im_fs_folder_status"
	db_dml filestorage "
		delete from im_fs_folder_status 
		where folder_id in (
			select folder_id 
			from im_fs_folders 
			where object_id = :project_id
		)
	"
	ns_log Notice "projects/nuke-2: im_fs_folders"
	db_dml filestorage "
		delete from im_fs_folder_perms 
		where folder_id in (
			select folder_id 
			from im_fs_folders 
			where object_id = :project_id
		)
	"
	db_dml filestorage_files "
		delete from im_fs_files 
		where folder_id in (
			select folder_id 
			from im_fs_folders 
			where object_id = :project_id
		)
	"
	db_dml filestorage "delete from im_fs_folders where object_id = :project_id"


	# Calendar
        if {[im_table_exists cal_items]} {
	    db_dml del_cal_items "
		delete from cal_items 
		where	cal_item_id in (
				select event_id 
				from acs_events 
				where	related_object_type = 'im_project' and 
					related_object_id not in (select project_id from im_projects)
			)
	    "
	    db_dml del_acs_events "
		delete	from acs_events 
		where	related_object_type = 'im_project' and 
			related_object_id not in (select project_id from im_projects)
	    "
	}


	ns_log Notice "projects/nuke-2: rels"
	set rels [db_list rels "
		select rel_id 
		from acs_rels 
		where object_id_one = :project_id 
			or object_id_two = :project_id
	"]

	set im_conf_item_project_rels_exists_p [im_table_exists im_conf_item_project_rels]
	set im_ticket_ticket_rels_exists_p [im_table_exists im_ticket_ticket_rels]

        # TS Configuration Objects
        if {[im_table_exists im_timesheet_conf_objects]} {

            ns_log Notice "projects/nuke-2: im_timesheet_conf_objects"
            db_dml del_dependencies "
                delete from im_timesheet_conf_objects
                where conf_project_id = :project_id
            "
        }
	
        # Survey responses
        if {[im_table_exists survsimp_responses]} {
            ns_log Notice "projects/nuke-2: survsimp_responses"
            db_dml del_dependencies "
                delete from survsimp_responses
                where related_object_id = :project_id or related_context_id = :project_id
            "
        }

	# Relationships
	foreach rel_id $rels {
	    db_dml del_rels "delete from group_element_index where rel_id = :rel_id"
	    db_dml del_rels "delete from im_biz_object_members where rel_id = :rel_id"
	    db_dml del_rels "delete from membership_rels where rel_id = :rel_id"
	    if {$im_conf_item_project_rels_exists_p} { db_dml del_rels "delete from im_conf_item_project_rels where rel_id = :rel_id" }
	    if {$im_ticket_ticket_rels_exists_p} { db_dml del_rels "delete from im_ticket_ticket_rels where rel_id = :rel_id" }
#	    if {$exists_p} { db_dml del_rels "delete from  where rel_id = :rel_id" }

	    db_dml del_rels "delete from acs_rels where rel_id = :rel_id"
	    db_dml del_rels "delete from acs_objects where object_id = :rel_id"
	}

	ns_log Notice "projects/nuke-2: party_approved_member_map"
	db_dml party_approved_member_map "
		delete from party_approved_member_map 
		where party_id = :project_id"
	db_dml party_approved_member_map "
		delete from party_approved_member_map 
		where member_id = :project_id"


	ns_log Notice "projects/nuke-2: acs_objecs.context_id"
	db_dml acs_objects_context_index "
		update acs_objects set context_id = null
		where context_id = :project_id";
	db_dml acs_objects_context_index2 "
		update acs_objects set context_id = null
		where object_id = :project_id";

	
	ns_log Notice "projects/nuke-2: acs_object_context_index"
	db_dml acs_object_context_index "
		delete from acs_object_context_index
		where object_id = :project_id OR ancestor_id = :project_id"

	
	ns_log Notice "users/nuke2: Main tables"
	db_dml parent_projects "
		update im_projects 
		set parent_id = null 
		where parent_id = :project_id"
	db_dml delete_projects "
		delete from im_projects 
		where project_id = :project_id"
	db_dml delete_project_biz_objs "
		delete from im_biz_objects
		where object_id = :project_id"
	db_dml delete_project_acs_obj "
		delete from acs_objects
		where object_id = :project_id"

    } on_error {

	set detailed_explanation ""
	if {[ regexp {integrity constraint \([^.]+\.([^)]+)\)} $errmsg match constraint_name]} {
	    
	    set sql "select table_name from user_constraints 
		     where constraint_name=:constraint_name"
	    db_foreach user_constraints_by_name $sql {
		set detailed_explanation "<p>[_ intranet-core.lt_It_seems_the_table_we]"
	    }
	    
	}
	return "$detailed_explanation<br><pre>$errmsg</pre>"
    }
    return ""
}


ad_proc im_project_super_project_id {
    project_id
} {
    Determine the Top superproject of the current
    project.
} {
    set super_project_id $project_id
    set loop 1
    set ctr 0
    while {$loop} {
	set loop 0
	set parent_id [db_string parent_id "select parent_id from im_projects where project_id=:super_project_id" -default ""]
	
	if {"" != $parent_id} {
	    set super_project_id $parent_id
	    set loop 1
	}
	
	# Check for recursive loop
	if {$ctr > 20} {
	    set loop 0
	}
	incr ctr
    }
 
    return $super_project_id
}





ad_proc -public im_project_base_data_component {
    {-project_id}
    {-return_url}
} {
    returns basic project info with dynfields and hard coded
    Original version from ]po[
} { 
  
    set params [list  [list base_url "/intranet-core/"]  [list project_id $project_id] [list return_url $return_url]]
    
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/project-base-data"]
    return [string trim $result]
}



# ---------------------------------------------------------------
# Personal list of tasks
# ---------------------------------------------------------------

ad_proc -public im_personal_todo_component {
    {-view_name "personal_todo_list" }
} {
    Returns a HTML table with the list of projects, tasks,
    forum items etc. assigned to the current user. 
} {
    set current_user_id [ad_get_user_id]

    # ---------------------------------------------------------------
    # Columns to show:

    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
    set column_headers [list]
    set column_vars [list]
    set extra_selects [list]
    set extra_froms [list]
    set extra_wheres [list]

    set column_sql "
	select	*
	from	im_view_columns
	where	view_id = :view_id
		and group_id is null
	order by
		sort_order
    "
    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
    }

    if {"" == $order_by_clause} {
	set order_by_clause  [parameter::get_from_package_key -package_key "intranet-core" -parameter "HomePersonalToDoListSortClause" -default "task_name DESC"]
    }

    # ---------------------------------------------------------------
    # Generate SQL Query

    set extra_select [join $extra_selects ",\n\t"]
    set extra_where [join $extra_wheres "and\n\t"]
    if { ![empty_string_p $extra_where] } {
	set extra_where "and\n\t$extra_where"
    }

    set tasks_sql "
	-- projects managed by the current user
	select	p.project_id as task_id,
		p.project_name as task_name,
		p.company_id as customer_id,
		p.project_status_id as status_id,
		p.project_type_id as type_id,
		p.start_date,
		p.end_date,
		im_category_from_id(p.project_priority_id) as priority,
		p.percent_completed
	from
	        im_projects p,
		acs_rels r,
		im_biz_object_members bom
	where
		r.object_id_one = p.project_id and
		r.object_id_two = :current_user_id and
		r.rel_id = bom.rel_id and
		bom.object_role_id = 1301 and
		p.parent_id is null and
		p.project_type_id not in ([im_project_type_task], [im_project_type_ticket]) and
		p.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","])
	UNION
	-- tasks assigned to this user
	select	p.project_id as task_id,
		p.project_name as task_name,
		p.company_id as customer_id,
		p.project_status_id as status_id,
		p.project_type_id as type_id,
		p.start_date,
		p.end_date,
		t.priority::text,
		p.percent_completed
	from
		im_projects p,
		im_timesheet_tasks t,
		acs_rels r
	where
		r.object_id_one = p.project_id and
		r.object_id_two = :current_user_id and
		p.project_id = t.task_id and
		p.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","])
	UNION
	-- tickets assigned to this user
	select	p.project_id as task_id,
		p.project_name as task_name,
		p.company_id as customer_id,
		p.project_status_id as status_id,
		p.project_type_id as type_id,
		p.start_date,
		p.end_date,
		im_category_from_id(t.ticket_prio_id) as priority,
		percent_completed
	from
		im_projects p,
		im_tickets t,
		acs_rels r
	where
		r.object_id_one = p.project_id and
		r.object_id_two = :current_user_id and
		p.project_id = t.ticket_id and
		t.ticket_status_id not in ([join [im_sub_categories [im_ticket_status_closed]] ","])
    "

    set personal_tasks_query "
	SELECT	t.*,
	        c.company_name,
	        im_category_from_id(t.type_id) as task_type,
	        im_category_from_id(t.status_id) as task_status,
		to_char(t.start_date, 'YYYY-MM-DD') as start_date_pretty,
		to_char(t.end_date, 'YYYY-MM-DD') as end_date_pretty,
		bou.url as task_url
                $extra_select
	FROM
		($tasks_sql) t,
		im_companies c,
		acs_objects o
		LEFT OUTER JOIN (select * from im_biz_object_urls where url_type = 'view') bou ON (o.object_type = bou.object_type)
                $extra_from
	WHERE
		t.customer_id = c.company_id and
		t.task_id = o.object_id
                $extra_where
	order by $order_by_clause
    "

    
    # ---------------------------------------------------------------
    # Format the List Table Header

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    set table_header_html "<tr>\n"
    foreach col $column_headers {
	regsub -all " " $col "_" col_txt
	set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
	append table_header_html "  <td class=rowtitle>$col_txt</td>\n"
    }
    append table_header_html "</tr>\n"


    # ---------------------------------------------------------------
    # Format the Result Data

    set url "index?"
    set table_body_html ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set ctr 0
    db_foreach personal_tasks_query $personal_tasks_query {

	set url [im_maybe_prepend_http $url]
	if { [empty_string_p $url] } {
	    set url_string "&nbsp;"
	} else {
	    set url_string "<a href=\"$url\">$url</a>"
	}
	
	# Append together a line of data based on the "column_vars" parameter list
	set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
	foreach column_var $column_vars {
	    append row_html "\t<td valign=top>"
	    set cmd "append row_html $column_var"
	    eval "$cmd"
	    append row_html "</td>\n"
	}
	append row_html "</tr>\n"
	append table_body_html $row_html
	
	incr ctr
    }

    # Show a reasonable message when there are no result rows:
    if { [empty_string_p $table_body_html] } {

	# Let the component disappear if there are no projects...
	if {!$show_empty_project_list_p} { return "" }

	set table_body_html "
	    <tr><td colspan=\"$colspan\"><ul><li><b> 
	    [lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
	    </b></ul></td></tr>
	"
    }
    return "
	<table class=\"table_component\" width=\"100%\">
	<thead>$table_header_html</thead>
	<tbody>$table_body_html</tbody>
	</table>
    "
}

