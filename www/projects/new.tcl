# /packages/intranet-core/projects/new.tcl
#
# Copyright (C) 1998-2004 various parties
# The software is based on ArsDigita ACS 3.4
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
    Purpose: form to add a new project or edit an existing one
    
    @param project_id group id
    @param parent_id the parent project id
    @param return_url the url to return to

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    project_id:optional,integer
    { parent_id:integer "" }
    { company_id:integer "" }
    project_nr:optional
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]
set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"

set project_nr_field_size [ad_parameter -package_id [im_package_core_id] ProjectNumberFieldSize "" 20]
set enable_nested_projects_p [parameter::get -parameter EnableNestedProjectsP -package_id [ad_acs_kernel_id] -default 1] 

set view_finance_p [im_permission $user_id view_finance]


# Make sure the user has the privileges, because this
# pages shows the list of companies etc.
if {![im_permission $user_id add_projects]} { 

    # Double check for the case that this guy is a freelance 
    # project manager of the project or similar...
    im_project_permissions $user_id $project_id view read write admin
    if {!$write} {
	ad_return_complaint "Insufficient Privileges" "
        <li>You don't have sufficient privileges to see this page."
    }
}

# create form
#
set form_id "project-ae"

template::form::create $form_id
template::form::section $form_id "[_ intranet-core.Project_Base_Data] [im_gif help "To avoid duplicate projects and to determine where the project data are stored on the local file server"]"
template::element::create $form_id project_id -widget "hidden"
template::element::create $form_id supervisor_id -widget "hidden" -optional
template::element::create $form_id requires_report_p -widget "hidden" -optional
template::element::create $form_id return_url -widget "hidden" -optional -datatype text
template::element::create $form_id project_name -datatype text\
	-label "[_ intranet-core.Project_Name]" \
	-html {size 40} \
	-after_html "[im_gif help "Please enter any suitable name for the project. The name must be unique."]"

template::element::create $form_id project_nr -datatype text\
	-label "[_ intranet-core.Project_]" \
	-html {size $project_nr_field_size maxlength $project_nr_field_size} \
	-after_html "[im_gif help "A project number is composed by 4 digits for the year plus 4 digits for current identification"]"
	
if {$enable_nested_projects_p} {
	
	# create project list query
	#
	
    	set project_parent_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
    	set project_parent_options [concat $project_parent_options [im_project_options 0]]
	template::element::create $form_id parent_id -optional \
    	-label "[_ intranet-core.Parent_Project]" \
        -widget "select" \
	-options $project_parent_options \
	-after_html "[im_gif help "Do you want to create a subproject (a project that is part of an other project)? Leave the field blank (-- Please Select --) if you are unsure."]"
} else {
	template::element::create $form_id parent_id -optional -widget "hidden"
}

# craete customer query
#

set customer_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
set customer_list_options [concat $customer_options [im_company_options 0]]
set help_text "[im_gif help "There is a difference between &quot;Paying Client&quot; and &quot;Final Client&quot;. Here we want to know from whom we are going to receive the money..."]"
if {$user_admin_p} {
	set  help_text "<A HREF='/intranet/companies/new'>[im_gif new "Add a new client"]</A> $help_text"
}

template::element::create $form_id company_id \
	-label "[_ intranet-core.Customer]" \
	-widget "select" \
      	-options $customer_list_options \
	-after_html $help_text


set project_lead_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
set project_lead_list_options [concat $project_lead_options [im_employee_options 0]]
template::element::create $form_id project_lead_id -optional\
	-label "[_ intranet-core.Project_Manager]" \
	-widget "select" \
      	-options $project_lead_list_options


set help_text "[im_gif help "General type of project. This allows us to create a suitable folder structure."]"
if {$user_admin_p} {
	set  help_text "<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Project+Type'>
	[im_gif new "Add a new project type"]</A> $help_text"
}

template::element::create $form_id project_type_id \
	-label "[_ intranet-core.Project_Type]" \
	-widget "im_category_tree" \
      	-custom {category_type "Intranet Project Type"} \
	-after_html $help_text


set help_text "[im_gif help "In Process: Work is starting immediately, Potential Project: May become a project later, Not Started Yet: We are waiting to start working on it, Finished: Finished already..."]"
if {$user_admin_p} {
	set  help_text "<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Project+Status'>
	<%= [im_gif new "Add a new project status"] %></A>$help_text"
}

template::element::create $form_id project_status_id \
	-label "[_ intranet-core.Project_Status]" \
	-widget "im_category_tree" \
      	-custom {category_type "Intranet Project Status"} \
	-after_html $help_text

template::element::create $form_id start -datatype "date" widget "date" -label "[_ intranet-core.Start_Date]"

template::element::create $form_id end -datatype "date" widget "date" -label "[_ intranet-core.Delivery_Date]"\
	-format "DD Month YYYY HH24:MI"

set help_text "[im_gif help "Is the project going to be in time and budget (green), does it need attention (yellow) or is it doomed (red)?"]"
template::element::create $form_id on_track_status_id \
	-label "[_ intranet-core.On_Track_Status]" \
	-widget "im_category_tree" \
      	-custom {category_type "Intranet Project On Track Status"} \
	-after_html $help_text

template::element::create $form_id percent_completed -optional \
	-label "[_ intranet-core.Percent_Completed]"\
     	-after_html "%"

template::element::create $form_id project_budget_hours -optional \
	-label "[_ intranet-core.Project_Budget_Hours]"\
	-html {size 20} \
     	-after_html "[im_gif help "How many hours can be logged on this project (both internal and external resource)?"]"

if {$view_finance_p} {
	template::element::create $form_id project_budget -optional \
		-label "[_ intranet-core.Project_Budget]"\
		-html {size 20} 
		
	template::element::create $form_id project_budget_currency -optional \
		-widget "select"\
		-datatype "text" \
		-label "[_ intranet-core.Project_Currency]"\
		-options "[im_currency_options]" \
	     	-after_html "[im_gif help "What is the financial budget of this project? Includes both external (invoices) and internal (timesheet) costs."]"

} else {
	template::element::create $form_id project_budget -optional -widget hidden
	template::element::create $form_id project_budget_currency -optional -widget hidden -datatype "text"
}

template::element::create $form_id description -optional -datatype text\
		-widget textarea \
		-label "[_ intranet-core.Description]<br>([_ intranet-core.publicly_searchable])"\
		-html {rows 5 cols 50}
		
		
# ------------------------------------------------------
# Dynamic Fields
# ------------------------------------------------------


set dynamic_fields_p 0
if {[db_table_exists im_dynfield_attributes]} {

    set dynamic_fields_p 1
    set object_type "im_project"
    set my_company_id 0
    if {[info exists project_id]} { set my_project_id $project_id }


    im_dynfield::append_attributes_to_form \
	-object_type $object_type \
        -form_id $form_id \
        -object_id $my_project_id
}

####### end form ###################

# Check if we are editing an already existing project
#
set button_text "[_ intranet-core.Save_Changes]"
if {[form is_request $form_id]} {
	if { [exists_and_not_null project_id] } {
	    # We are editing an already existing project
	    #
	    db_1row projects_info_query { 
	select 
		p.parent_id, 
		p.company_id, 
		p.project_name,
		p.project_type_id, 
		p.project_status_id, 
		p.description,
		p.project_lead_id, 
		p.supervisor_id, 
		p.project_nr,
		p.project_budget, 
		p.project_budget_currency, 
		p.project_budget_hours,
		p.on_track_status_id, 
		p.percent_completed, 
	        to_char(p.percent_completed, '99.9%') as percent_completed_formatted,
		to_char(p.start_date,'YYYY-MM-DD') as start_date, 
		to_char(p.end_date,'YYYY-MM-DD') as end_date, 
		to_char(p.end_date,'HH24:MI') as end_time,
		p.requires_report_p 
	from
		im_projects p
	where 
		p.project_id=:project_id
	}
	
	    set page_title "[_ intranet-core.Edit_project]"
	    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] [list "/intranet/projects/view?[export_url_vars project_id]" "One project"] $page_title]
	
	    if { [empty_string_p $start_date] } { set start_date $todays_date }
	    if { [empty_string_p $end_date] } { set end_date $todays_date }
	    if { [empty_string_p $end_time] } { set end_time "12:00" }
	    set button_text "[_ intranet-core.Save_Changes]"
	    
	
	} else {
	
	    # Calculate the next project number by calculating the maximum of
	    # the "reasonably build numbers" currently available
	
	    # A completely new project or a subproject
	    #
	    if {![info exist project_nr]} {
		set project_nr [im_next_project_nr]
	    }
	    set start_date $todays_date
	    set end_date $todays_date
	    set end_time "12:00"
	    set billable_type_id ""
	    set project_lead_id "5"
	    set supervisor_id ""
	    set description ""
	    set project_budget ""
	    set project_budget_currency ""
	    set project_budget_hours ""
	    set on_track_status_id ""
	    set percent_completed "0"
	    set "creation_ip_address" [ns_conn peeraddr]
	    set "creation_user" $user_id
	    set project_id [im_new_object_id]
	    set project_name ""
	    set button_text "[_ intranet-core.Create_Project]"
	
	    if { ![exists_and_not_null parent_id] } {
	
		# A brand new project (not a subproject)
		set requires_report_p "f"
		set parent_id ""
		if { ![exists_and_not_null company_id] } {
		    set company_id ""
		}
		set project_type_id 85
		set project_status_id 76
		set page_title "[_ intranet-core.Add_New_Project]"
		set context_bar [im_context_bar [list ./ "[_ intranet-core.Projects]"] $page_title]
		
	    } else {
	
		# This means we are adding a subproject.
		# Let's select out some defaults for this page
		db_1row projects_by_parent_id_query {
		    select 
			p.company_id, 
			p.project_type_id, 
			p.project_status_id
		    from
			im_projects p
		    where 
			p.project_id=:parent_id 
		}
	
		set requires_report_p "f"
		set page_title "[_ intranet-core.Add_subproject]"
		set context_bar [im_context_bar [list ./ "[_ intranet-core.Projects]"] [list "view?project_id=$parent_id" "[_ intranet-core.One_project]"] $page_title]
	    }
	}
	
	if {"" == $on_track_status_id} {
	    set on_track_status_id [im_project_on_track_status_green]
	}
	
	if {"" == $percent_completed} {
	    set percent_completed 0
	}
	template::element::set_value $form_id project_id $project_id
	template::element::set_value $form_id supervisor_id $supervisor_id
	template::element::set_value $form_id requires_report_p $requires_report_p
	template::element::set_value $form_id return_url $return_url
	template::element::set_value $form_id project_name $project_name
	template::element::set_value $form_id project_nr $project_nr
	template::element::set_value $form_id parent_id $parent_id
	template::element::set_value $form_id company_id $company_id
	template::element::set_value $form_id project_lead_id $project_lead_id
	template::element::set_value $form_id project_type_id $project_type_id
	template::element::set_value $form_id project_status_id $project_status_id
	set start_date_list [split $start_date "-"]
	template::element::set_value $form_id start $start_date_list
	set end_date_list [split $end_date "-"]
	set end_date_list [concat $end_date_list [split $end_time ":"]]
	template::element::set_value $form_id end $end_date_list
	template::element::set_value $form_id on_track_status_id $on_track_status_id
	template::element::set_value $form_id percent_completed $percent_completed
	template::element::set_value $form_id project_budget_hours $project_budget_hours
	template::element::set_value $form_id project_budget $project_budget
	template::element::set_value $form_id project_budget_currency $project_budget_currency
	template::element::set_value $form_id description $description
}
 template::form::set_properties $form_id edit_buttons "[list [list "$button_text" ok]]"
 
 if {[form is_submission $form_id]} {
 	form get_values $form_id
 	if {![im_permission $user_id add_projects]} {
	
	    # Double check for the case that this guy is a freelance
	    # project manager of the project or similar...
	    im_project_permissions $user_id $project_id view read write admin
	    if {!$write} {
	        ad_return_complaint "Insufficient Privileges" "
	        <li>You don't have sufficient privileges to see this page."
	    }
	}
	
	ad_proc var_contains_quotes { var } {
	    if {[regexp {"} $var]} { return 1 }
	    if {[regexp {'} $var]} { return 1 }
	    return 0
	}
	set n_error 0
	# check that no variable contains double or single quotes
	if {[var_contains_quotes $project_name]} { 
	    template::element::set_error $form_id project_name "[_ intranet-core.lt_Quotes_in_Project_Nam]"
	    incr n_error
	}
	if {[var_contains_quotes $project_nr]} { 
	    template::element::set_error $form_id project_nr "[_ intranet-core.lt_Quotes_in_Project_Nr_]"
	    incr n_error
	}
	#if {[var_contains_quotes $project_path]} { 
	#    append errors "<li>[_ intranet-core.lt_Quotes_in_Project_Pat]"
	#}
	if {[regexp {/} $project_nr]} { 
	    template::element::set_error $form_id project_nr "[_ intranet-core.lt_Slashes__in_Project_P]"
	    incr n_error
	}
	if {[regexp {\.} $project_nr]} { 
	    template::element::set_error $form_id project_nr "[_ intranet-core.lt_Dots__in_Project_Path]"
	    incr n_error
	}
	
	if {$percent_completed > 100 || $percent_completed < 0} {
	    #ad_return_complaint 1 "Error with '$percent_completed'% completed:<br>
	    template::element::set_error $form_id percent_completed "Number must be in range (0 .. 100)"
	    incr n_error
	}
	if {[template::util::date::compare $end $start] == -1} {
	    template::element::set_error $form_id end "[_ intranet-core.lt_End_date_must_be_afte]"
	    incr n_error
	}
	
	
	set project_nr_exists [db_string project_nr_exists "
	select 	count(*)
	from	im_projects
	where	project_nr = :project_nr
	        and project_id <> :project_id"]
	
	if { $project_nr_exists > 0 } {
	    incr n_error
	    template::element::set_error $form_id project_nr "[_ intranet-core.lt_The_specified_project]"
	}
	
	
	# Make sure the project name has a minimum length
	if { [string length $project_name] < 5} {
	   incr n_error
	   template::element::set_error $form_id project_name "[_ intranet-core.lt_The_project_name_that] <br>
	   [_ intranet-core.lt_Please_use_a_project_]"
	}
	
	# Let's make sure the specified name is unique
	set project_name_exists [db_string project_name_exists "
	select 	count(*)
	from	im_projects
	where	(
		    upper(trim(project_name)) = upper(trim(:project_name))
		    or upper(trim(project_nr)) = upper(trim(:project_nr))
		    or upper(trim(project_path)) = upper(trim(:project_nr))
		)
	        and project_id <> :project_id"]
	
	if { $project_name_exists > 0 } {
	    incr n_error
	    template::element::set_error $form_id project_name "[_ intranet-core.lt_The_specified_name_pr]"
	    template::element::set_error $form_id project_nr "[_ intranet-core.lt_The_specified_name_pr]"
	}
	
	
	if {$n_error >0} {
		return
	}
 
 }
 
 if {[form is_valid $form_id]} {
 	set project_path $project_nr
  	# -----------------------------------------------------------------
	# Create a new Project if it didn't exist yet
	# -----------------------------------------------------------------
	
	# Double-Click protection: the project Id was generated at the new.tcl page
	
	set id_count [db_string id_count "select count(*) from im_projects where project_id=:project_id"]
	
	
	# Create the "administration group" for this project.
	# The project is going to get the same ID then.
	#
	if {0 == $id_count} {
	
	    set project_id [project::new \
	        -project_name		$project_name \
	        -project_nr		$project_nr \
	        -project_path		$project_path \
	        -company_id		$company_id \
	        -parent_id		$parent_id \
	        -project_type_id	$project_type_id \
		-project_status_id	$project_status_id]
	
	    # add users to the project as PMs
	    # - current_user (creator/owner)
	    # - project_leader
	    # - supervisor
	    set role_id [im_biz_object_role_project_manager]
	    im_biz_object_add_role $user_id $project_id $role_id 
	    if {"" != $project_lead_id} {
		im_biz_object_add_role $project_lead_id $project_id $role_id 
	    }
	    if {"" != $supervisor_id} {
		im_biz_object_add_role $supervisor_id $project_id $role_id 
	    }
	}
	
	
	# -----------------------------------------------------------------
	# Update the Project
	# -----------------------------------------------------------------
	set start_date [template::util::date get_property sql_date $start]
	set end_date [template::util::date get_property sql_date $end]
	
	    set project_update_sql "
	update im_projects set
		project_name =	:project_name,
		project_path =	:project_path,
		project_nr =	:project_nr,
		project_type_id =:project_type_id,
		project_status_id =:project_status_id,
		project_lead_id =:project_lead_id,
		company_id =	:company_id,
		supervisor_id =	:supervisor_id,
		parent_id =	:parent_id,
		description =	:description,
		requires_report_p =:requires_report_p,
		project_budget =:project_budget,
		project_budget_currency =:project_budget_currency,
		project_budget_hours =:project_budget_hours,
		percent_completed = :percent_completed,
		on_track_status_id =:on_track_status_id,
		start_date =	$start_date,
		end_date =	$end_date
	where
		project_id = :project_id
	"
	
	#    ad_return_complaint 1 "Test:<br>end_time=$end_date_time"
	
	
	    db_dml project_update $project_update_sql
	
	# -----------------------------------------------------------------
	# Store dynamic fields
	# -----------------------------------------------------------------
	
	if {[db_table_exists im_dynfield_attributes]} {
	
	    ns_log Notice "companies/new: before attribute_store"
	    im_dynfield::attribute_store \
		-object_type $object_type \
		-object_id $company_id \
		-form_id $form_id
	    ns_log Notice "companies/new-2: after attribute_store"
	
}
	
	if { [exists_and_not_null project_lead_id] } {
	
	    # add the creating current user to the group
	    relation_add \
	        -member_state "approved" \
	        "admin_rel" \
	        $project_id \
	        $project_lead_id
	
	}
	
	
	if { ![exists_and_not_null return_url] } {
	    set return_url "[im_url_stub]/projects/view?[export_url_vars project_id]"
	}
	
	ad_returnredirect $return_url

 }