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

    
if { ![db_0or1row project_info_query {}] } {
    ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
    return
}

set user_id [ad_conn user_id] 
set project_type [im_category_from_id $project_type_id]
set project_status [im_category_from_id $project_status_id]

# Get the parent project's name
if {"" == $parent_id} { set parent_id 0 }
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
set user_can_see_start_end_date_p [expr [im_user_is_employee_p $current_user_id] || [im_user_is_customer_p $current_user_id]]

set show_start_date_p 0
if { $user_can_see_start_end_date_p && ![empty_string_p $start_date_formatted] } { 
    set show_start_date_p 1
}

set show_end_date_p 0
if { $user_can_see_start_end_date_p && ![empty_string_p $end_date] } {
    set show_end_date_p 1
}

set im_project_on_track_bb [im_project_on_track_bb $on_track_status_id]
 
# ---------------------------------------------------------------------
# Add DynField Columns to the display

db_multirow -extend {attrib_var value} project_dynfield_attribs dynfield_attribs_sql {} {
    set var ${attribute_name}_deref
    set value [expr $$var]
    if {"" != [string trim $value]} {
	set attrib_var [lang::message::lookup "" intranet-core.$attribute_name $pretty_name]
    }
}


set edit_project_base_data_p [im_permission $current_user_id edit_project_basedata]
set user_can_see_start_end_date_p [expr [im_user_is_employee_p $current_user_id] || [im_user_is_customer_p $current_user_id]]
