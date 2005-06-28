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
template::element::create $form_id project_name -datatype text\
	-label "[_ intranet-core.Project_Name]" \
	-html {size 40} \
	-help_text "Please enter any suitable name for the project. The name must be unique."

template::element::create $form_id project_nr -datatype text\
	-label "[_ intranet-core.Project_]" \
	-html {size $project_nr_field_size maxlength $project_nr_field_size} \
	-help_text "A project number is composed by 4 digits for the year plus 4 digits for current identification"
	
if {$enable_nested_projects_p} {
	
	# create project list query
	#
	
    	set project_parent_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
     	set project_parent_options [concat $project_parent_options [im_project_options]]
	template::element::create $form_id parent_id -optional \
    	-label "[_ intranet-core.Parent_Project]" \
        -widget "select" \
	-options $project_parent_options \
	-help_text "Do you want to create a subproject (a project that is part of an other project)? Leave the field blank (-- Please Select --) if you are unsure."
} else {
	template::element::create $form_id parent_id -optional -widget "hidden"
}

# craete customer query
#

set customer_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
set customer_list_options [concat $customer_options [im_company_options]]
set help_text "There is a difference between &quot;Paying Client&quot; and &quot;Final Client&quot;. Here we want to know from whom we are going to receive the money..."
if {$user_admin_p} {
	set  help_text "<A HREF='/intranet/companies/new'>[im_gif new "Add a new client"] Add a new client</A>
	                <br> $help_text"
}

template::element::create $form_id company_id \
	-label "[_ intranet-core.Customer]" \
	-widget "select" \
      	-options $customer_list_options \
	-help_text $help_text


set project_lead_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
set project_lead_list_options [concat $project_lead_options [im_employee_options]]
template::element::create $form_id project_lead_id -optional\
	-label "[_ intranet-core.Project_Manager]" \
	-widget "select" \
      	-options $project_lead_list_options


set help_text "General type of project. This allows us to create a suitable folder structure."
if {$user_admin_p} {
	set  help_text "<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Project+Type'>
	[im_gif new "Add a new project type"] Add a new project type</A>
	<br> $help_text"
}

template::element::create $form_id project_type_id \
	-label "[_ intranet-core.Project_Type]" \
	-widget "im_category_tree" \
      	-custom {category_type "Intranet Project Type"} \
	-help_text $help_text


set help_text "In Process: Work is starting immediately, Potential Project: May become a project later, Not Started Yet: We are waiting to start working on it, Finished: Finished already..."
if {$user_admin_p} {
	set  help_text "<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Project+Status'>
	<%= [im_gif new "Add a new project status"] %> Add a new project status</A>
	<br> $help_text"
}

template::element::create $form_id project_status_id \
	-label "[_ intranet-core.Project_Status]" \
	-widget "im_category_tree" \
      	-custom {category_type "Intranet Project Status"} \
	-help_text $help_text

template::element::create $form_id start -datatype "date" widget "date" -label "[_ intranet-core.Start_Date]"

template::element::create $form_id end -datatype "date" widget "date" -label "[_ intranet-core.Delivery_Date]"\
	-format "DD Month YYYY HH24:MI"

set help_text "Is the project going to be in time and budget (green), does it need attention (yellow) or is it doomed (red)?"
template::element::create $form_id on_track_status_id \
	-label "[_ intranet-core.On_Track_Status]" \
	-widget "im_category_tree" \
      	-custom {category_type "Intranet Project On Track Status"} \
	-help_text $help_text

template::element::create $form_id percent_completed -optional \
	-label "[_ intranet-core.Percent_Completed]"\
     	-after_html "%"
#    <tr>
#      <td>#intranet-core.Percent_Completed#</td>
#      <td>
#	<input type=text size=5 name=percent_completed value="@percent_completed@"> %
#      </td>
#    </tr>

#    <tr>
#      <td>#intranet-core.Project_Budget_Hours#</td>
#      <td>
#	<input type=text size=20 name=project_budget_hours value="@project_budget_hours@">
#	<%= [im_gif help "How many hours can be logged on this project (both internal and external resource)?"] %> &nbsp;
#      </td>
#    </tr>


#<if @view_finance_p@>
#    <tr>
#      <td>#intranet-core.Project_Budget#</td>
#      <td>
#	<input type=text size=20 name=project_budget value="@project_budget@">
#	<%= [im_currency_select project_budget_currency $project_budget_currency] %>
#	<%= [im_gif help "What is the financial budget of this project? Includes both external (invoices) and internal (timesheet) costs."] %> &nbsp;
#      </td>
#    </tr>
#</if>

#    <tr>
#      <td>#intranet-core.Description#<br>(#intranet-core.publicly_searchable#) </td>
#      <td>
#        <textarea NAME=description rows=5 cols=50 wrap=soft>@description@</textarea>
#      </td>
#    </tr>



####### end form ###################

# Check if we are editing an already existing project
#
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