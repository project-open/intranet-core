ad_page_contract {
    The display for the project base data 
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-07

} 

# ---------------------------------------------------------------------
# Get Everything about the project
# ---------------------------------------------------------------------


set extra_selects [list "0 as zero"]
db_foreach column_list_sql {}  {
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"
}
    
set extra_select [join $extra_selects ",\n\t"]



set project_info_sql "
select	*,
	$extra_select
from	(
	select
		p.*,
		bo.*,
		o.*,
		to_char(p.end_date, 'HH24:MI') as end_date_time,
		to_char(p.start_date, 'YYYY-MM-DD') as start_date_formatted,
		to_char(p.end_date, 'YYYY-MM-DD') as end_date_formatted,
		to_char(p.percent_completed, '999990.9%') as percent_completed_formatted,
		im_name_from_user_id(p.project_lead_id) as project_lead,
		im_name_from_user_id(p.supervisor_id) as supervisor,
		ic.company_name,
		ic.company_path,
		ic.primary_contact_id as company_contact_id,
		im_name_from_user_id(ic.manager_id) as manager,
		im_name_from_user_id(ic.primary_contact_id) as company_contact,
		im_email_from_user_id(ic.primary_contact_id) as company_contact_email
	from
		im_projects p
		LEFT OUTER JOIN im_biz_objects bo ON (p.project_Id = bo.object_id),
		acs_objects o,
		im_companies ic
	where 
		p.project_id = :project_id and
		p.project_id = o.object_id and
		p.company_id = ic.company_id
	) t
"
    
if {![db_0or1row project_info_query $project_info_sql] } {
    ad_return_complaint 1 [_ intranet-core.lt_Cant_find_the_project]
    ad_script_abort
}

set user_id [ad_conn user_id] 
set project_type [im_category_from_id $project_type_id]
set project_status [im_category_from_id $project_status_id]

# Get the parent project's name
if {"" == $parent_id} { set parent_id 0 }
im_security_alert_check_integer -location "intranet-core/lib/project-base-data: parent_id" -value $parent_id
set parent_name [util_memoize [list db_string parent_name "select project_name from im_projects where project_id = $parent_id" -default ""]]


# ---------------------------------------------------------------------
# Redirect to timesheet if this is timesheet
# ---------------------------------------------------------------------

# Redirect if this is a timesheet task (subtype of project)
if {$project_type_id == [im_project_type_task]} {
    ad_returnredirect [export_vars -base "/intranet-timesheet2-tasks/new" {{task_id $project_id}}]
    
}


# ---------------------------------------------------------------------
# Check permissions
# ---------------------------------------------------------------------

# get the current users permissions for this project                                                                                                         
im_project_permissions $user_id $project_id view read write admin

set current_user_id $user_id
set enable_project_path_p [parameter::get -parameter EnableProjectPathP -package_id [im_package_core_id] -default 0] 

set view_finance_p [im_permission $current_user_id view_finance]
set view_budget_p [im_permission $current_user_id view_budget]
set view_budget_hours_p [im_permission $current_user_id view_budget_hours]


# ---------------------------------------------------------------------
# Project Base Data
# ---------------------------------------------------------------------
    

set im_company_link_tr [im_company_link_tr $user_id $company_id $company_name "[_ intranet-core.Client]"]
set im_render_user_id [im_render_user_id $project_lead_id $project_lead $user_id $project_id]

# VAW Special: Freelancers shouldnt see star and end date
# ToDo: Replace this hard coded condition with DynField
# permissions per field.
set user_can_see_start_end_date_p [expr {[im_user_is_employee_p $current_user_id] || [im_user_is_customer_p $current_user_id]}]

set show_start_date_p 0
if { $user_can_see_start_end_date_p && $start_date_formatted ne "" } { 
    set show_start_date_p 1
}

set show_end_date_p 0
if { $user_can_see_start_end_date_p && $end_date ne "" } {
    set show_end_date_p 1
}

set im_project_on_track_bb [im_project_on_track_bb $on_track_status_id]
 
# ---------------------------------------------------------------------
# Add DynField Columns to the display

db_multirow -extend {attrib_var value} project_dynfield_attribs dynfield_attribs_sql {} {
    set var ${attribute_name}_deref
    set value [expr $$var]

    # Empty values will be skipped anyway
    if {"" != [string trim $value]} {
	set attrib_var [lang::message::lookup "" intranet-core.$attribute_name $attribute_pretty_name]

	set translate_p 0
	switch $acs_datatype {
	    boolean - string { set translate_p 1 }
	}
	switch $widget {
	    im_category_tree - checkbox - generic_sql - select { set translate_p 1 }
	    richtext - textarea - text - date { set translate_p 0 }
	}
	
	set value_l10n $value
	if {$translate_p} {
	    # ToDo: Is lang::util::suggest_key the right way? Or should we just use blank substitution?
	    set value_l10n [lang::message::lookup "" intranet-core.[lang::util::suggest_key $value] $value] 
	}
	set value $value_l10n
    }
}


set edit_project_base_data_p [im_permission $current_user_id edit_project_basedata]
set user_can_see_start_end_date_p [expr {[im_user_is_employee_p $current_user_id] || [im_user_is_customer_p $current_user_id]}]
