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
    @author koen.vanwinckel@dotprojects.be
} {
    { project_id:integer "" }
    { parent_id:integer "" }
    { company_id:integer "" }
    { project_type_id:integer "" }
    { project_status_id:integer "" }
    { project_name "" }
    project_nr:optional
    { workflow_key "" }
    { workflow_case_id "" }
    { return_url "" }
}


# Redirect to custom new page if necessary
callback im_project_new_redirect -object_id $project_id \
    -status_id $project_status_id -type_id $project_type_id \
    -project_id $project_id -parent_id $parent_id \
    -company_id $company_id -project_type_id $project_type_id \
    -project_name $project_name -project_nr [im_opt_val project_nr] \
    -workflow_key $workflow_key -return_url $return_url


# -----------------------------------------------------------
# Defaults
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"
set current_url [im_url_with_query]
set org_project_type_id [im_opt_val project_type_id]

set project_nr_field_size [ad_parameter -package_id [im_package_core_id] ProjectNumberFieldSize "" 20]
set project_nr_field_editable_p [ad_parameter -package_id [im_package_core_id] ProjectNumberFieldEditableP "" 1]
set enable_nested_projects_p [parameter::get -parameter EnableNestedProjectsP -package_id [ad_acs_kernel_id] -default 1] 
set enable_project_path_p [parameter::get -parameter EnableProjectPathP -package_id [im_package_core_id] -default 0]
set enable_absolute_project_path_p [parameter::get -parameter EnableAbsoluteProjectPathP -package_id [im_package_core_id] -default 0] 

set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set normalize_project_nr_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NormalizeProjectNrP" -default 1]
set sub_navbar ""
set auto_increment_project_nr_p [parameter::get -parameter ProjectNrAutoIncrementP -package_id [im_package_core_id] -default 0]

if { ![exists_and_not_null return_url] && [exists_and_not_null project_id]} {
    set return_url [export_vars -base "/intranet/projects/view" {project_id}]
}

# Do we need the customer_id for creating a project?
# This is necessary if the project_nr depends on the customer_id.
set customer_required_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NewProjectRequiresCustomerP" -default 0]

# ad_return_complaint 1 $project_id
# ad_return_complaint 1 "[info exists project_id], $company_id, $customer_required_p"

if { (![info exists project_id] || "" == $project_id) && $company_id == "" && $customer_required_p} {
    ad_returnredirect [export_vars -base "new-custselect" {project_id parent_id project_nr workflow_key return_url}]
    ad_script_abort
}

# -----------------------------------------------------------
# Permissions
# -----------------------------------------------------------
     
set view_finance_p [im_permission $user_id view_finance]
set view_budget_p [im_permission $user_id view_budget]
set view_budget_hours_p [im_permission $user_id view_budget_hours]
set add_budget_p [im_permission $user_id add_budget]
set add_budget_hours_p [im_permission $user_id add_budget_hours]


set project_exists_p 0
if {[info exists project_id]} {
    set project_exists_p [db_string project_exists "
	select count(*) 
	from im_projects 
	where project_id = :project_id
    "]
}

if {$project_exists_p} {

    # Check project permissions for this user
    im_project_permissions $user_id $project_id view read write admin
    if {!$write} {
	ad_return_complaint "Insufficient Privileges" "
            <li>You don't have sufficient privileges to see this page."
	return
    }

} else {

    set perm_p 0
    # Check if the user has admin rights on the parent_id
    # to allow freelancers to add sub-projects
    if {"" != $parent_id} {
	im_project_permissions $user_id $parent_id view read write admin
	if {$admin} { set perm_p 1 }
    }

    # Users with "add_projects" privilege can always create new projects...
    if {[im_permission $user_id add_projects]} { set perm_p 1 } 
    if {!$perm_p} { 
	ad_return_complaint "Insufficient Privileges" "
            <li>You don't have sufficient privileges to see this page."
	return
    }

    # Do we need to get the project type first in order to show the right DynFields?
    if {("" == $org_project_type_id || 0 == $org_project_type_id)} {
      set all_same_p [im_dynfield::subtype_have_same_attributes_p -object_type "im_project"]
      if {!$all_same_p} {
          set exclude_category_ids [list \
              [im_project_type_ticket] \
              [im_project_type_software_release_item] \
          ]
          ad_returnredirect [export_vars -base "/intranet/biz-object-type-select" {
              project_name
              also_add_users
              company_id
              { return_url $current_url }
              { object_type "im_project" }
              { type_id_var "project_type_id" }
              { pass_through_variables "project_name also_add_users company_id" }
              { exclude_category_ids $exclude_category_ids }
          }]
      }
    }

}

# -----------------------------------------------------------
# Create the Form
# -----------------------------------------------------------



set form_id "project-ae"

template::form::create $form_id
template::form::section $form_id ""
template::element::create $form_id project_id -widget "hidden"
template::element::create $form_id supervisor_id -widget "hidden" -optional
template::element::create $form_id workflow_case_id -widget "hidden" -optional
template::element::create $form_id requires_report_p -widget "hidden" -optional -datatype text
template::element::create $form_id workflow_key -widget "hidden" -optional -datatype text
template::element::create $form_id return_url \
    -widget "hidden" \
    -optional \
    -datatype text
template::element::create $form_id project_name \
    -datatype text\
    -label "[_ intranet-core.Project_Name]" \
    -html {size 40} \
    -after_html "[im_gif help "Please enter any suitable name for the project. The name must be unique."]"


set project_nr_mode "display"
if {$project_nr_field_editable_p} { set project_nr_mode "edit" }
template::element::create $form_id project_nr \
    -datatype text \
    -mode $project_nr_mode \
    -label "[lang::message::lookup "" intranet-core.Project_Nr "Project Nr."]" \
    -html {size $project_nr_field_size maxlength $project_nr_field_size} \
    -after_html "[im_gif help "A project number is composed by 4 digits for the year plus 4 digits for current identification"]"


if {$enable_project_path_p} {
    template::element::create $form_id project_path \
	-datatype text \
	-label "[lang::message::lookup "" intranet-core.Project_Path "Project Path"]" \
	-html {size 40} \
	-after_html "[im_gif help "An optional full path to the project filestorage"]"
}

if {$enable_nested_projects_p} {
	
    # Create project list query.
    # The list has to include subprojects in the case of nested projects,
    # either the superprojects of this project, or the the subprojects
    # of the parent, in the case of creating a sub-subproject.
    set super_project_id 0
    if {"" != $parent_id} { set super_project_id $parent_id }
    if {[info exists project_id]} { set super_project_id $project_id }

    if { [exists_and_not_null project_id] } {
        set project_parent_options [im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -project_id $super_project_id]
    } else {
        set project_parent_options [im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -project_id $super_project_id]
    }

    template::element::create $form_id parent_id -optional \
    	-label "[_ intranet-core.Parent_Project]" \
        -widget "select" \
	-options $project_parent_options \
	-after_html "[im_gif help "Do you want to create a subproject (a project that is part of an other project)? Leave the field blank (-- Please Select --) if you are unsure."]"
} else {
    template::element::create $form_id parent_id -optional -widget "hidden"
}

# create customer query
#
set customer_list_options [im_company_options -include_empty_p 0 -status "Active or Potential" -type "CustOrIntl"]
set help_text "[im_gif help "There is a difference between &quot;Paying Client&quot; and &quot;Final Client&quot;. Here we want to know from whom we are going to receive the money..."]"
if {$user_admin_p} {
    set  help_text "<A HREF='/intranet/companies/new'>[im_gif new "Add a new client"]</A> $help_text"
}

template::element::create $form_id company_id \
    -label "[_ intranet-core.Customer]" \
    -widget "select" \
    -options $customer_list_options \
    -after_html $help_text

# Include current PM in list of potential PMs if not there
# already ...
#
set project_lead_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
set project_lead_id 0
if {[info exists project_id]} {
    set project_lead_id [db_string project_lead "select	project_lead_id from im_projects where project_id = :project_id" -default 0]
}
set project_lead_list_options [concat $project_lead_options [im_project_manager_options -include_empty 0 -current_pm_id $project_lead_id]]

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
	[im_gif new "Add a new project status"]</A>$help_text"
}


# ### ToDo: optimize [START]

# Suppress the status field if the project has a WF associated
set wf_case_exists_p 0
set wf_instace_exists_p 0

if {[info exists project_type_id] && ![info exists project_id] } {
	# project not yet created 
	set wf_key [db_string wf "select aux_string1 from im_categories where category_id = :project_type_id" -default ""]
} else {
	# project exists
	if {[info exists project_id] } {
	        set wf_key [db_string wf_exists "select project_type_id from im_projects where project_id = :project_id" -default 0]
	} else {
		ad_return_complaint 1 "Configuration Error - please contact your System Administrator"
	}
}

set wf_exists_p [db_string wf_exists "select count(*) from wf_workflows where workflow_key = :wf_key"]
if {[info exists project_id] } {
    if { [db_string wf_exists "select count(*) from wf_cases where object_id = :project_id"] > 0 } { set wf_instace_exists_p 1}
}

if {[info exists project_id] } {
    	if { !$wf_instace_exists_p || [im_permission $user_id edit_project_status]  } {
	    template::element::create $form_id project_status_id \
        	-label "[_ intranet-core.Project_Status]" \
	        -widget "im_category_tree" \
        	-custom {category_type "Intranet Project Status"} \
	        -after_html $help_text
	} else {
	    template::element::create $form_id project_status_id -optional -widget hidden
	}
} else {
    if { $wf_exists_p } {
	    template::element::create $form_id project_status_id -optional -widget hidden
    } else {
            template::element::create $form_id project_status_id \
                -label "[_ intranet-core.Project_Status]" \
                -widget "im_category_tree" \
                -custom {category_type "Intranet Project Status"} \
                -after_html $help_text
    }
}

# ### ToDo: optimize [END]


template::element::create $form_id start \
    -datatype "date" widget "date" \
    -label "[_ intranet-core.Start_Date]" \
    -format "DD Month YYYY" \
    -after_html {<input type="button" style="height:23px; width:23px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendarWithDateWidget('start', 'y-m-d');" >}

template::element::create $form_id end \
    -datatype "date" widget "date" \
    -label "[_ intranet-core.Delivery_Date]"\
    -format "DD Month YYYY HH24:MI" \
    -after_html {<input type="button" style="height:23px; width:23px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendarWithDateWidget('end', 'y-m-d');" >}

set help_text "[im_gif help "Is the project going to be in time and budget (green), does it need attention (yellow) or is it doomed (red)?"]"
template::element::create $form_id on_track_status_id \
    -label "[_ intranet-core.On_Track_Status]" \
    -widget "im_category_tree" \
    -custom {category_type "Intranet Project On Track Status"} \
    -after_html $help_text

template::element::create $form_id percent_completed \
    -datatype float \
    -optional \
    -label "[_ intranet-core.Percent_Completed]"\
    -after_html "%"

if {$add_budget_hours_p} {
    template::element::create $form_id project_budget_hours -optional \
	-label "[_ intranet-core.Project_Budget_Hours]"\
	-html {size 20} \
     	-after_html "[im_gif help "How many hours can be logged on this project (both internal and external resource)?"]"

} else {
    template::element::create $form_id project_budget_hours -optional -widget hidden
}


if {$add_budget_p} {
    template::element::create $form_id project_budget -optional \
	-label "[_ intranet-core.Project_Budget]"\
	-html {size 20} 
		
    template::element::create $form_id project_budget_currency -optional \
	-widget "select"\
	-datatype "text" \
	-label "[_ intranet-core.Project_Budget_Currency]"\
	-options "[im_currency_options]" \
	-after_html "[im_gif help "What is the financial budget of this project? Includes both external (invoices) and internal (timesheet) costs."]"

} else {
    template::element::create $form_id project_budget -optional -widget hidden
    template::element::create $form_id project_budget_currency -optional -widget hidden -datatype "text"
}

template::element::create $form_id company_project_nr \
    -datatype text \
    -optional \
    -label "[lang::message::lookup "" intranet-core.Company_Project_Nr "Customer's ProjectNr"]" \
    -after_html "[im_gif help [lang::message::lookup "" intranet-core.Company_Project_Nr_Help "The customer's reference to this project. This number will appear in invoices of this project."]  ]"

template::element::create $form_id description -optional -datatype text\
    -widget textarea \
    -label "[_ intranet-core.Description]<br>([_ intranet-core.publicly_searchable])"\
    -html {rows 5 cols 50}

	
# ------------------------------------------------------
# Dynamic Fields
# ------------------------------------------------------

set object_type "im_project"
set dynfield_project_type_id [im_opt_val project_type_id]
if {[info exists project_id]} {
    set existing_project_type_id [db_string ptype "select project_type_id from im_projects where project_id = :project_id" -default 0]
    if {0 != $existing_project_type_id && "" != $existing_project_type_id} {
	set dynfield_project_type_id $existing_project_type_id
    }
}

set dynfield_project_id 0
if {[info exists project_id]} { set dynfield_project_id $project_id }

ns_log Notice "/intranet/projects/new: im_dynfield::append_attributes_to_form -object_subtype_id $dynfield_project_type_id -object_type $object_type -form_id $form_id -object_id $dynfield_project_id"

set field_cnt [im_dynfield::append_attributes_to_form \
    -object_subtype_id $dynfield_project_type_id \
    -object_type $object_type \
    -form_id $form_id \
    -object_id $dynfield_project_id \
]



# Check if we are editing an already existing project
#
set edit_existing_project_p 0
set button_text "[_ intranet-core.Save_Changes]"
if {[form is_request $form_id]} {
    if { [exists_and_not_null project_id] } {
	# We are editing an already existing project
	#
	set edit_existing_project_p 1

	db_1row projects_info_query { 
	select 
		p.parent_id, 
		p.company_id, 
		p.project_name,
		p.project_type_id, 
		p.project_status_id, 
		p.description,
	        p.company_project_nr,
		p.project_lead_id, 
		p.supervisor_id, 
		p.project_nr,
	        p.project_path,
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
	    set project_nr [im_next_project_nr -customer_id $company_id -parent_id $parent_id]
       	}
	set project_path $project_nr
	set edit_existing_project_p 0
	set start_date $todays_date
	set end_date $todays_date
	set end_time "12:00"
	set billable_type_id ""
	set project_lead_id $user_id
	set supervisor_id ""
	set description ""
	set company_project_nr ""
	set project_budget ""
	set project_budget_currency ""
	set project_budget_hours ""
	set on_track_status_id ""
	set percent_completed "0"
	set "creation_ip_address" [ns_conn peeraddr]
	set "creation_user" $user_id
	set project_id [im_new_object_id]
	set project_name [im_opt_val project_name]
	set button_text "[_ intranet-core.Create_Project]"

	if { ![exists_and_not_null parent_id] } {
	    
	    # A brand new project (not a subproject)
	    set requires_report_p "f"
	    set parent_id ""
	    if { ![exists_and_not_null company_id] } {
		set company_id ""
	    }
	    if {![exists_and_not_null project_type_id]} { set project_type_id 85 }
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

    if {"" == $project_budget_currency} {
	set project_budget_currency $default_currency
    }

    template::element::set_value $form_id project_id $project_id
    template::element::set_value $form_id supervisor_id $supervisor_id
    template::element::set_value $form_id requires_report_p $requires_report_p
    template::element::set_value $form_id return_url $return_url
    template::element::set_value $form_id workflow_key $workflow_key
    template::element::set_value $form_id project_name $project_name
    template::element::set_value $form_id project_nr $project_nr
    if {$enable_project_path_p} { template::element::set_value $form_id project_path $project_path }
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
    template::element::set_value $form_id company_project_nr $company_project_nr
}

template::form::set_properties $form_id edit_buttons "[list [list "$button_text" ok]]"
 
if {[form is_submission $form_id]} {
    form get_values $form_id

    # Permission check. Cases include a user with full add_projects rights,
    # but also a freelancer updating an existing project or a freelancer
    # creating a sub-project of a project he or she can admin.
    set perm_p 0

    # Check for the case that this guy is a freelance
    # project manager of the project or similar...
    im_project_permissions $user_id $project_id view read write admin
    if {$write} { set perm_p 1 }

    # Check if the user has admin rights on the parent_id
    # to allow freelancers to add sub-projects
    if {"" != $parent_id} {
	im_project_permissions $user_id $parent_id view read write admin
	if {$write} { set perm_p 1 }
    }

    # Users with "add_projects" privilege can always create new projects...
    if {[im_permission $user_id add_projects]} { set perm_p 1 } 

    if {!$perm_p} { 
	ad_return_complaint "Insufficient Privileges" "<li>You don't have sufficient privileges to see this page."
	ad_script_abort
    }
    
    set n_error 0
    # check that no variable contains double or single quotes
    if {[var_contains_quotes $project_name]} { 
	template::element::set_error $form_id project_name "[_ intranet-core.lt_Quotes_in_Project_Nam]"
	incr n_error
    }

    if {[info exists project_nr] && $normalize_project_nr_p} {
	set project_nr [string tolower [string trim $project_nr]]
	if {![regexp {^[a-z0-9_]+$} $project_nr match]} {
	    incr n_error
	    template::element::set_error $form_id project_nr [lang::message::lookup "" intranet-core.Non_alphanum_chars_in_nr "The specified path contains invalid characters.<br> Allowed are only aphanumeric characters including a-z, 0-9 and '_'."]

	}
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

    if {$parent_id == $project_id} { 
	template::element::set_error $form_id parent_id "Parent Project = Project"
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

    # Check for project number duplicates
    set project_nr_exists [db_string project_nr_exists "
	select 	count(*)
	from	im_projects
	where	project_nr = :project_nr
	        and project_id <> :project_id
    "]
     if {$project_nr_exists} {
	 # We have found a duplicate project_nr, now check how to deal with this case:
	 if {$auto_increment_project_nr_p} {
	     # Just increment to the next free number. 
	     set project_nr [im_next_project_nr -customer_id $company_id -parent_id $parent_id]
	 } else {
	     # Report an error
	     incr n_error
	     template::element::set_error $form_id project_nr "[_ intranet-core.lt_The_specified_project]"
	 }
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
	where	upper(trim(project_name)) = upper(trim(:project_name))
	        and project_id <> :project_id
		and parent_id = :parent_id
    "]

	
    if { $project_name_exists > 0 } {
	incr n_error
	template::element::set_error $form_id project_name "[_ intranet-core.lt_The_specified_name_pr]"
    }

    # Make sure company_project_nr has a max length 50
    if { [string length $company_project_nr] > 50} {
        incr n_error
        template::element::set_error $form_id company_project_nr "[_ intranet-core.Max50Chars]"
    }
		
    if {$n_error >0} {
	return
    }
 
}

if {[form is_valid $form_id]} {

    if {!$enable_project_path_p} { set project_path $project_nr }

    # -----------------------------------------------------------------
    # Create a new Project if it didn't exist yet
    # -----------------------------------------------------------------
    
    # Double-Click protection: the project Id was generated at the new.tcl page
    set id_count [db_string id_count "select count(*) from im_projects where project_id=:project_id"]
    if {0 == $id_count} {
	
	set project_id ""
	catch {
	    set project_id [project::new \
			    -project_name	$project_name \
			    -project_nr		$project_nr \
			    -project_path	$project_path \
			    -company_id		$company_id \
			    -parent_id		$parent_id \
			    -project_type_id	$project_type_id \
			    -project_status_id	$project_status_id \
	    ]
	} err_msg
	
        if {0 == $project_id || "" == $project_id} {
            ad_return_complaint 1 "<b>Error creating project</b>:<br>
                We have got an error creating a new project.<br>
		There is probably something wrong with the projects's parameters below:<br>&nbsp;<br>
		<pre>
		project_name            $project_name
		project_nr              $project_nr
		project_path            $project_path
		company_id              $company_id
		parent_id               $parent_id
		project_type_id         $project_type_id
		project_status_id       $project_status_id
		</pre><br>&nbsp;<br>
		For reference, here is the error message:<br>
		<pre>$err_msg</pre>
            "
            ad_script_abort
        }

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

    # Set the old project type. Used to detect changes in the project
    # type and therefore the need to display new DynField fields in a
    # second page.
    if {0 == $id_count} {
	set previous_project_type_id 0
    } else {
	set previous_project_type_id [db_string prev_ptype "select project_type_id from im_projects where project_id = :project_id" -default 0]
    }
	
    # -----------------------------------------------------------------
    # Update the Project
    # -----------------------------------------------------------------
    set start_date [template::util::date get_property sql_date $start]
    set end_date [template::util::date get_property sql_timestamp $end]


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
		company_project_nr = :company_project_nr,
		requires_report_p =:requires_report_p,
		percent_completed = :percent_completed,
		on_track_status_id =:on_track_status_id,
		start_date =	$start_date,
		end_date =	$end_date
	where
		project_id = :project_id
    "
    db_dml project_update $project_update_sql

    if {$add_budget_hours_p} {
	set project_update_sql "
	    update im_projects set
		project_budget_hours =:project_budget_hours
	where
		project_id = :project_id
        "
	db_dml project_update $project_update_sql
    }

    if {$add_budget_p} {
	set project_update_sql "
	    update im_projects set
		project_budget =:project_budget,
		project_budget_currency =:project_budget_currency
	where
		project_id = :project_id
        "
	db_dml project_update $project_update_sql
    }



    # -----------------------------------------------------------------
    # Create a new Workflow for the project either if:
    # - specified explicitely in the parameters or
    # - if there is a WF associated with the project_type

    # Check if there is a WF associated with the project type
    if {"" == $workflow_key} {
	set wf_key [db_string wf "select aux_string1 from im_categories where category_id = :project_type_id" -default ""]
	set wf_exists_p [db_string wf_exists "select count(*) from wf_workflows where workflow_key = :wf_key"]
	if {$wf_exists_p} { set workflow_key $wf_key }
    }

    # Project Approval WF had been executed and finsihed at least one 
    set wf_finished_p 0

    if {[info exists project_id] } {
	# Check if WF case already exist for project
      	set workflow_case_id [db_string wf_exists "select case_id from wf_cases where workflow_key = :wf_key and object_id = :project_id limit 1" -default 0]
    } else {
	set wf_finished_p [db_string wf_exists "select count(*) from wf_cases where workflow_key = :wf_key and object_id = :project_id and state = 'finished' limit 1"]
    }

    if { 0 == $workflow_case_id && $wf_exists_p && !$wf_finished_p } {
	    # Create a new workflow case (instance)
	    set context_key ""
	    set case_id [wf_case_new \
                     $workflow_key \
                     $context_key \
                     $project_id \
		     ]
	    # Determine the first task in the case to be executed and start+finisch the task.
	    im_workflow_skip_first_transition -case_id $case_id
    }

    # Write Audit Trail
    im_project_audit -project_id $project_id


    # -----------------------------------------------------------------
    # Store dynamic fields

    ns_log Notice "/intranet/projects/new: im_dynfield::attribute_store -object_type $object_type -object_id $project_id -form_id $form_id"
    im_dynfield::attribute_store \
	-object_type $object_type \
	-object_id $project_id \
	-form_id $form_id

    # -----------------------------------------------------------------
    # add the creating current_user to the group
   
    if { [exists_and_not_null project_lead_id] } {
	im_biz_object_add_role $project_lead_id $project_id [im_biz_object_role_project_manager]
    }


    # -----------------------------------------------------------------
    # Call the "project_create" or "project_update" user_exit

    if {0 == $id_count} {
	im_user_exit_call project_create $project_id
        im_audit -object_type im_project -action after_create -object_id $project_id -status_id $project_status_id -type_id $project_type_id
    } else {
	im_user_exit_call project_update $project_id
	im_audit -object_type im_project -action after_update -object_id $project_id -status_id $project_status_id -type_id $project_type_id
    }


    # -----------------------------------------------------------------
    # Flush caches related to the project's information

    util_memoize_flush_regexp "im_project_has_type_helper.*"
    util_memoize_flush_regexp "db_list_of_lists company_info.*"


    # -----------------------------------------------------------------
    # Where do we want to go now?
    #
    # "Wizard" type of operation: We need to display a second page
    # with all the potentially new DynField fields if the type of the
    # project has changed. 

    if {[info exists previous_project_type_id]} {
	if {$project_type_id != $previous_project_type_id} {

	    # Check that there is atleast one dynfield. Otherwise
	    # it's not necessary to show the same page again
	    if {$field_cnt > 0} {

		set return_url [export_vars -base "/intranet/projects/new" {project_id return_url}]
	    }
	}
    }

    # Patch #1712047 from Koen van Winckel
    if {"" == $return_url} {

        # Check if we have a translation project
        if { [im_project_has_type $project_id "Translation Project"] } {

            # and return to the translation details
            set return_url [export_vars -base "/intranet-translation/projects/edit-trans-data" {project_id return_url}]

        } else {

            # not a translation project
            set return_url [export_vars -base "/intranet/projects/view" {project_id}]

        }
    }

    ad_returnredirect $return_url
}


# -----------------------------------------------------------
# NavBars
# -----------------------------------------------------------

set sub_navbar ""

if {$edit_existing_project_p && "" != $project_id} {

    # Setup the subnavbar
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id [im_opt_val project_id]
    set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set menu_label "project_summary"
    set sub_navbar [im_sub_navbar \
			-base_url [export_vars -base "/intranet/projects/view" {project_id}] \
			$parent_menu_id \
			$bind_vars "" "pagedesriptionbar" $menu_label \
		       ]
}

