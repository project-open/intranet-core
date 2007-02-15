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
ad_proc -public im_project_type_task {} { return 100 }


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
    set user_is_group_member_p [im_biz_object_member_p $user_id $project_id]
    set user_is_group_admin_p [im_biz_object_admin_p $user_id $project_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]
    set user_in_project_group_p [string compare "t" [db_string user_belongs_to_project "select ad_group_member_p( :user_id, :project_id ) from dual" ] ]

    # Treat the project mangers_fields
    # A user man for some reason not be the group PM
    if {!$user_is_group_admin_p} {
	set project_manager_id [db_string project_manager "select project_lead_id from im_projects where project_id = :project_id" -default 0]
	if {$user_id == $project_manager_id} {
	    set user_is_group_admin_p 1
	}
    }
    
    # Admin permissions to global + intranet admins + group administrators
    set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
    set user_admin_p [expr $user_admin_p || $user_is_wheel_p]

    set write $user_admin_p
    set admin $user_admin_p

    # Get the projects's company and the project status
    set query "
	select	company_id, 
		lower(im_category_from_id(project_status_id)) as project_status 
	from	im_projects
	where	project_id=:project_id
    "
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

    set user_is_company_member_p [im_biz_object_member_p $user_id $company_id]

    if {$user_admin_p} { 
	set admin 1
	set write 1
	set read 1
	set view 1
    }

# 20050729 fraber: Don't let customer's contacts see their project
# without exlicit permission...
#    if {$user_is_company_member_p} { set read 1}

    if {$user_is_group_member_p} { set read 1}
    if {[im_permission $user_id view_projects_all]} { set read 1}
    if {[im_permission $user_id edit_projects_all]} { 
	set read 1
	set write 1
	set admin 1
    }

    # companies and freelancers are not allowed to see non-open projects.
    # 76 = open
    if {![im_permission $user_id view_projects_history] && ![string equal $project_status "open"]} {
	# Except their own projects...
	if {!$user_is_company_member_p} {
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
	set dup_sql "
		select	count(*)
		from	im_projects 
		where
			upper(trim(project_name)) = upper(trim(:project_name))
			or upper(trim(project_nr)) = upper(trim(:project_nr))
			or upper(trim(project_path)) = upper(trim(:project_path))
	"
	if {[db_string duplicates $dup_sql]} { 
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
        return $project_id
    }
}

# -----------------------------------------------------------
# Projects Business Logic
# -----------------------------------------------------------


ad_proc -public im_next_project_nr { 
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
    if {![info exists nr_digits]} {
	set nr_digits [parameter::get -package_id [im_package_core_id] -parameter "ProjectNrDigits" -default "4"]
    }
    if {![info exists date_format]} {
	set date_format [parameter::get -package_id [im_package_core_id] -parameter "ProjectNrDateFormat" -default "YYYY_"]
    }
    if {"none" == $date_format} { set date_format "" }

    set todate [db_string today "select to_char(now(), :date_format)"]
    
    # ----------------------------------------------------
    # Calculate the next invoice Nr by finding out the last
    # one +1

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


ad_proc -public im_project_options { 
    {-include_empty 1}
    {-include_empty_name ""}
    {-exclude_subprojects_p 1}
    {-project_status ""}
    {-project_type 0}
    {-exclude_status 0}
    {-exclude_status_id 0}
    {-member_user_id 0}
    {-company_id 0}
    {-project_id 0}
} { 
    Get a list of projects
} {
    set current_project_id $project_id
    set bind_vars [ns_set create]
    set user_id [ad_get_user_id]
    ns_set put $bind_vars user_id $user_id
    
    if {[im_permission $user_id view_projects_all]} {
	 # The user can see all projects
	 # This is particularly important for sub-projects.
	 set sql "
		select
			p.project_name,
			p.project_id
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

    if {$company_id} {
	ns_set put $bind_vars company_id $company_id
	append sql " and p.company_id = :company_id"
    }

    # Exclude subprojects does not work with subprojects,
    # if we are showing this box for a sub-sub-project.
    set subsubproject_sql ""
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
	                and r.object_id_two = :user_id
	        )
	"
	if {[im_permission $user_id "view_projects_all"]} { set perm_sql "im_projects" }


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

	set subsubproject_sql "
	    OR p.parent_id in ([join $subprojects ","])
	"
    }

    if {$exclude_subprojects_p} {
	append sql " and (p.parent_id is null $subsubproject_sql)"
    }
    
    if {"" != $project_status} {
	ns_set put $bind_vars status $project_status
	append sql " and p.project_status_id = (
	     select project_status_id 
	     from im_project_status 
	     where lower(project_status)=lower(:project_status))"
    }

    if {$exclude_status} {
	set exclude_string [im_append_list_to_ns_set $bind_vars project_status $exclude_status]
	append sql " and p.project_status_id in (
	    select project_status_id 
            from im_project_status 
            where project_status not in ($exclude_string)) "
    }

    if {0 != $exclude_status_id} {
	ns_set put $bind_vars exclude_status_id $exclude_status_id
	append sql " and p.project_status_id not in (
		select 	child_id
		from	im_category_hierarchy
		where	(parent_id = :exclude_status_id OR child_id = :exclude_status_id)
	)"
    }

    if {$project_type} {
	ns_set put $bind_vars type $project_type
	append sql " and p.project_type_id = (
	    select project_type_id 
	    from im_project_types 
	    where project_type=:type)"
    }

    if {$member_user_id} {

	# Show the default project always
	set project_sql ""
	if {"" != $project_id} {
	    set project_sql "UNION select :project_id"
	}

	ns_set put $bind_vars member_user_id $member_user_id
	append sql "	and p.project_id in (
				select object_id_one
				from acs_rels
				where object_id_two = :member_user_id
			    $project_sql
			)
		    "
    }

    append sql " order by lower(p.project_name)"

    set options [db_list_of_lists project_options $sql]
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




ad_proc -public im_project_template_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all projects that qualify as templates.
} {
    set bind_vars [ns_set create]
#    ns_set put $bind_vars project_id $project_id

    # Include the "template_p" field of im_projects IF its defined
    set template_p_sql ""
    if {[db_column_exists im_projects template_p]} {
	set template_p_sql "or template_p='t'"
    }

    set sql "
        select
		project_id,
		project_name
        from
		im_projects
	where
		lower(project_name) like '%template%'
		$template_p_sql
	order by
		lower(project_name)
    "

    return [im_selection_to_select_box -translate_p 0 $bind_vars "project_member_select" $sql $select_name $default]
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
	im_name_from_user_id(u.user_id) as user_name
from
	user_group_map m,
	users u
where
	m.group_id=:project_id
	and m.user_id=u.user_id
order by 
	user_name"

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

ad_proc -public im_project_select { 
    { -include_all 0 } 
    { -exclude_subprojects_p 1 }
    { -exclude_status_id 0 }
    select_name 
    { default "" } 
    { status "" } 
    {type ""} 
    { exclude_status "" } 
    { member_user_id ""} 
    {company_id ""} 
} {
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

     if { $exclude_subprojects_p } {
	 append sql " and p.parent_id is null"
     }

     if { ![empty_string_p $status] } {
	 ns_set put $bind_vars status $status
	 append sql " and p.project_status_id = (
	     select project_status_id 
	     from im_project_status 
	     where lower(project_status)=lower(:status))"
    }

    if {0 != $exclude_status_id} {
	ns_set put $bind_vars exclude_status_id $exclude_status_id
	append sql " and p.project_status_id not in (
		select 	child_id
		from	im_category_hierarchy
		where	(parent_id = :exclude_status_id OR child_id = :exclude_status_id)
	)"
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




ad_proc -public im_project_personal_active_projects_component {
    {-view_name "project_personal_list" }
    {-order_by_clause ""}
    {-project_type_id 0}
} {
    Returns a HTML table with the list of projects of the
    current user. Don't do any fancy with sorting and
    pagination, because a single user won't be a member of
    many active projects.
} {
    set user_id [ad_get_user_id]
    set page_focus "im_header_form.keywords"

    if {"" == $order_by_clause} {
	set order_by_clause  [parameter::get_from_package_key -package_key "intranet-core" -parameter "HomeProjectListSortClause" -default "project_nr DESC"]
    }

    # ---------------------------------------------------------------
    # Columns to show:

    set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]
    set column_headers [list]
    set column_vars [list]
    
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

    db_foreach column_list_sql $column_sql {
	if {"" == $visible_for || [eval $visible_for]} {
	    lappend column_headers "$column_name"
	    lappend column_vars "$column_render_tcl"
	}
    }

    # ---------------------------------------------------------------
    # Generate SQL Query

    # Project Type restriction
    set project_type_restriction ""
    if {0 != $project_type_id} {
	set project_type_restriction "
	and p.project_type_id in (
		select	h.child_id
		from	im_category_hierarchy h
		where	h.parent_id = :project_type_id
	    UNION
		select	:project_type_id
	)
	"
    }

    # Limit the list to open projects only
    set project_history_restriction "
	and p.project_status_id = [im_project_status_open]
    "

    set perm_sql "
	(select
	        p.*
	from
	        im_projects p,
		acs_rels r
	where
		r.object_id_one = p.project_id
		and r.object_id_two = :user_id
		and p.parent_id is null
		and p.project_status_id not in ([im_project_status_deleted], [im_project_status_closed])
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
	FROM
		$perm_sql p,
		im_companies c
	WHERE
		p.company_id = c.company_id
		$project_history_restriction
		$project_type_restriction
	order by $order_by_clause
    "

    
    # ---------------------------------------------------------------
    # Format the List Table Header

    # Set up colspan to be the number of headers + 1 for the # column
    set colspan [expr [llength $column_headers] + 1]

    set table_header_html "<tr>\n"
    foreach col $column_headers {
	regsub -all " " $col "_" col_txt
	set col_txt [_ intranet-core.$col_txt]
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
	set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
        There are currently no projects matching the selected criteria
        </b></ul></td></tr>"
    }
    return "
	<table width=100% cellpadding=2 cellspacing=2 border=0>
	  $table_header_html
	  $table_body_html
	</table>
    "
}




# ---------------------------------------------------------------------
# Cloning Procs
# ---------------------------------------------------------------------

ad_proc im_project_clone {
    {-company_id 0}
    parent_project_id 
    project_name 
    project_nr 
    clone_postfix
} {
    Clone project main routine.
    ToDo: Start working with Service Contracts to allow other modules
    to include their clone routines.
} {
    ns_log Notice "im_project_clone parent_project_id=$parent_project_id project_name=$project_name project_nr=$project_nr clone_postfix=$clone_postfix"

ad_return_complaint 1 "Clone Project temporarily disabled"

    set clone_members_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectMembersP" -default 1]
    set clone_costs_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectCostsP" -default 1]
    set clone_trans_tasks_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTransTasksP" -default 1]
    set clone_timesheet_tasks_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTimesheetTasksP" -default 1]
    set clone_target_languages_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTargetLanguagesP" -default 1]
    set clone_forum_topics_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectForumTopicsP" -default 1]
    set clone_files_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectFilesP" -default 1]
    set clone_subprojects_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectSubprojectsP" -default 1]

    set errors "<li>Starting to clone project \#$parent_project_id => $project_nr / $project_name"
    set new_project_id [im_project_clone_base $parent_project_id $project_name $project_nr $company_id $clone_postfix]

    # --------------------------------------------
    # Delete Trans Tasks for the NEW project
    # (when using the same project over and over again for debugging purposes)
    if {[db_table_exists im_trans_tasks]} {
	db_dml delete_trans_tasks "delete from im_trans_tasks where project_id = :new_project_id"
    }

    # --------------------------------------------
    # Delete Costs
    # (when using the same project over and over again for debugging purposes)
    ns_log Notice "im_project_clone: reset_invoice_items"
    db_dml reset_invoice_items "update im_invoice_items set project_id = null where project_id = :new_project_id"

    ns_log Notice "im_project_clone: cost_infos"
    set cost_infos [db_list_of_lists costs "
	select cost_id, object_type 
	from im_costs, acs_objects 
	where cost_id = object_id 
	      and project_id = :new_project_id
    "]
    foreach cost_info $cost_infos {
        set cost_id [lindex $cost_info 0]
        set object_type [lindex $cost_info 1]
        ns_log Notice "im_projects_clone: deleting cost: ${object_type}__delete($cost_id)"
        im_exec_dml del_cost "${object_type}__delete($cost_id)"
    }
    ns_log Notice "im_project_clone: finished deleting old costs"

    # --------------------------------------------
    # Clone the project

    append errors [im_project_clone_files $parent_project_id $new_project_id]
    append errors [im_project_clone_base2 $parent_project_id $new_project_id]
    append errors [im_project_clone_members $parent_project_id $new_project_id]
    append errors [im_project_clone_url_map $parent_project_id $new_project_id]

    if {$clone_trans_tasks_p && [db_table_exists "im_trans_tasks"]} {
#	append errors [im_project_clone_trans_tasks $parent_project_id $new_project_id]
    }
    if {$clone_timesheet_tasks_p && [db_table_exists "im_timesheet_tasks"]} {
#	append errors [im_project_clone_timesheet2_tasks $parent_project_id $new_project_id]
    }
    if {$clone_target_languages_p && [db_table_exists "im_target_languages"]} {
#	append errors [im_project_clone_target_languages $parent_project_id $new_project_id]
    }
    if {$clone_forum_topics_p && [db_table_exists "im_forum_topics"]} {
#        append errors [im_project_clone_forum_topics $parent_project_id $new_project_id]
    }
    if {$clone_costs_p && [db_table_exists "im_costs"]} {
#        append errors [im_project_clone_costs $parent_project_id $new_project_id]
#        append errors [im_project_clone_payments $parent_project_id $new_project_id]
    }
    if {$clone_subprojects_p} {
#	append errors [im_project_clone_subprojects $parent_project_id $new_project_id]
    }

    append errors "<li>Finished to clone project \#$parent_project_id"
    return $errors
}


ad_proc im_project_clone_base {parent_project_id project_name project_nr new_company_id clone_postfix} {
    Create the minimum information for a clone project
    with a new name and project_nr for unique constraint reasons.
} {
    ns_log Notice "im_project_clone_base parent_project_id=$parent_project_id project_name=$project_name project_nr=$project_nr new_company_id=$new_company_id clone_postfix=$clone_postfix"

    set new_project_name $project_name
    set new_project_nr $project_nr
    set current_user_id [ad_get_user_id]

    # --------------------------
    # Prepare Project SQL Query
    
    set query "
	select	p.*
	from	im_projects p
	where 	p.project_id = :parent_project_id
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
	
    set project_id [project::new \
		-project_name		$new_project_name \
		-project_nr		$new_project_nr \
		-project_path		$new_project_nr \
		-company_id		$company_id \
		-parent_id		$parent_id \
		-project_type_id	$project_type_id \
		-project_status_id	$project_status_id \
    ]
    if {0 == $project_id} {
	ad_return_complaint 1 "Error creating clone project with name '$new_project_name' and nr '$new_project_nr'"
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
		project_id = :project_id
    "


# Not cloning the template_p anymore. This is actually 
# meta-information that shouldn't get copied.
#		template_p = :template_p

    return $project_id
}




ad_proc im_project_clone_base2 {parent_project_id new_project_id} {
    copy project structure
} {
    ns_log Notice "im_project_clone_base2 parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone base2 information: parent_project_id=$parent_project_id new_project_id=$new_project_id"

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
    if {[db_table_exists im_trans_tasks]} {
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

    # Costs Stuff
    if {[db_table_exists im_costs]} {
	set project_update_sql "
	update im_projects set
		cost_quotes_cache =		:cost_quotes_cache,
		cost_invoices_cache =		:cost_invoices_cache,
		cost_timesheet_planned_cache =	:cost_timesheet_planned_cache,
		cost_purchase_orders_cache =	:cost_purchase_orders_cache,
		cost_bills_cache =		:cost_bills_cache,
		cost_timesheet_logged_cache =	:cost_timesheet_logged_cache
	where
		project_id = :new_project_id
	"
	db_dml project_update $project_update_sql
    }

    append errors "<li>Finished to clone base2 information"
    return $errors
}




ad_proc im_project_clone_members {parent_project_id new_project_id} {
    Copy projects members and administrators
} {
    ns_log Notice "im_project_clone_members parent_project_id=$parent_project_id new_project_id=$new_project_id"
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


ad_proc im_project_clone_costs {parent_project_id new_project_id} {
    Copy cost items and invoices
} {
    ns_log Notice "im_project_clone_costs parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set current_user_id [ad_get_user_id]

    # ToDo: There are costs _associated_ with a project, 
    # but without project_id! (?)
    #

    set costs_sql "
	select	c.*,
		i.*,
		o.object_type
	from
		acs_objects o,
		im_costs c
		left outer join
			im_invoices i on c.cost_id = i.invoice_id
	where
		c.cost_id = o.object_id
		and project_id = :parent_project_id
    "
    db_foreach add_costs $costs_sql {

	set old_cost_id $cost_id

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

	set cost_id [db_exec_plsql cost_insert "$cost_insert_query"]
	set new_cost_id $cost_id

	# ------------------------------------------------
	# create invoices

	if {"im_invoice" == $object_type} {

	    set invoice_nr [im_next_invoice_nr -invoice_type_id $cost_type_id]

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
	
	    # -------------------------------------
	    # creation invoice project relation
	    
	    set relation_query "select acs_rel__new(
		 null,
		 'relationship',
		 :new_project_id,
		 :invoice_id,
		 null,
		 null,
		 null
	    )"
	    db_exec_plsql insert_acs_rels "$relation_query"

	    set new_invoice_id $invoice_id


	    # ------------------------------------------------
	    # create invoice items

	    set invoice_sql "
		select * 
		from im_invoice_items 
		where invoice_id = :old_cost_id
	    "

	    db_foreach add_invoice_items $invoice_sql {
		set new_item_id [db_nextval "im_invoice_items_seq"]
		set insert_invoice_items_sql "
			INSERT INTO im_invoice_items (
				item_id, item_name, 
				project_id, invoice_id, 
				item_units, item_uom_id, 
				price_per_unit, currency, 
				sort_order, item_type_id, 
				item_status_id, description
			) VALUES (
				:item_id, :item_name, 
				:new_project_id, :new_invoice_id, 
				:item_units, :item_uom_id, 
				:price_per_unit, :currency, 
				:sort_order, :item_type_id, 
				:item_status_id, :description
			)"
				
		db_dml insert_invoice_items $insert_invoice_items_sql
		
	    }
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

ad_proc im_project_clone_timesheet2_tasks {parent_project_id new_project_id} {
    Copy translation tasks and assignments
} {
    ns_log Notice "im_project_clone_timesheet2 parent_project_id=$parent_project_id new_project_id=$new_project_id"

    # ------------------------------------------------
    # create timesheet2 tasks
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


ad_proc im_project_clone_subprojects {parent_project_id new_project_id} {
    Copy subprojects
} {
    ns_log Notice "im_project_clone_subprojects parent_project_id=$parent_project_id new_project_id=$new_project_id"

    subprojects_sql "
	select
		project_id as next_project_id
	from 
		im_projects
	where 
		parent_id = :parent_project_id
    "
    db_foreach subprojects $subprojects_sql {
		# go for the next project
		im_project_clone $next_project_id
    }
}

ad_proc im_project_clone_files {parent_project_id new_project_id} {
    Copy all files and subdirectories from parent to the new project
} {
    ns_log Notice "im_project_clone_files parent_project_id=$parent_project_id new_project_id=$new_project_id"

    set errors "<li>Starting to clone files"

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
#	exec /bin/mkdir -p $new_base_path
	exec /bin/cp -a $parent_base_path $new_base_path

    } err_msg] } {
	append errors "<li>Error whily copying files from $parent_base_path to $new_base_path: 
	<pre>$err_msg</pre>\n"
    }

    append errors "<li>Finished to clone files \#$parent_project_id"
    return $errors
}


ad_proc im_project_nuke {project_id} {
    Nuke (complete delete from the database) a project
} { #beginn of procedure body
    ns_log Notice "im_project_nuke project_id=$project_id"
    
    set current_user_id [ad_get_user_id]
    im_project_permissions $current_user_id $project_id view read write admin
    if {!$admin} { return }

    # ---------------------------------------------------------------
    # Delete
    # ---------------------------------------------------------------
    
    # if this fails, it will probably be because the installation has 
    # added tables that reference the users table

    with_transaction {
    
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

	    db_dml hours_costs_link "update im_hours set cost_id = null where cost_id = :cost_id"

	    ns_log Notice "projects/nuke-2: deleting cost: ${object_type}__delete($cost_id)"
	    im_exec_dml del_cost "${object_type}__delete($cost_id)"
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
	

	# Translation Quality
	ns_log Notice "projects/nuke-2: im_trans_quality_entries"
	if {[db_table_exists im_trans_quality_reports]} {
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
	if {[db_table_exists im_trans_tasks]} {
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

	
	# Consulting
	if {[db_table_exists im_timesheet_tasks]} {
	    
	    ns_log Notice "projects/nuke-2: im_hours - for timesheet tasks"
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



	ns_log Notice "projects/nuke-2: rels"
	set rels [db_list rels "
		select rel_id 
		from acs_rels 
		where object_id_one = :project_id 
			or object_id_two = :project_id
	"]
	foreach rel_id $rels {
	    db_dml del_rels "delete from group_element_index where rel_id = :rel_id"
	    db_dml del_rels "delete from im_biz_object_members where rel_id = :rel_id"
	    db_dml del_rels "delete from membership_rels where rel_id = :rel_id"
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
	
	
	ns_log Notice "users/nuke2: Main tables"
	db_dml parent_projects "
		update im_projects 
		set parent_id = null 
		where parent_id = :project_id"
	db_dml delete_projects "
		delete from im_projects 
		where project_id = :project_id"
	db_dml delete_project_acs_obj "
		delete from acs_objects
		where object_id = :project_id"

	# End "with_transaction"
    } {

	set detailed_explanation ""
	if {[ regexp {integrity constraint \([^.]+\.([^)]+)\)} $errmsg match constraint_name]} {
	    
	    set sql "select table_name from user_constraints 
		     where constraint_name=:constraint_name"
	    db_foreach user_constraints_by_name $sql {
		set detailed_explanation "<p>[_ intranet-core.lt_It_seems_the_table_we]"
	    }
	    
	}
	ad_return_error "[_ intranet-core.Failed_to_nuke]" "
		[_ intranet-core.Failed_to_nuke] Project: $project_id:<br>
		$detailed_explanation
		<p>
		<blockquote>
		<pre>
		$errmsg
		</pre>
		</blockquote>
	"
	return
    }
    set return_to_admin_link "<a href=\"/intranet/projects/\">[_ intranet-core.lt_return_to_user_admini]</a>" 
}