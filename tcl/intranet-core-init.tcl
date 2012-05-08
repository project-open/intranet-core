ad_library {
    Initialization for intranet-core
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)

    @creation-date 16 August, 2007
    @cvs-id $Id$
}

# Create a global cache for im_profile entries.
# The cache is bound by global timeout of 1 hour currently.
ns_cache create im_profile -timeout [ad_parameter -package_id [im_package_core_id] CacheTimeoutProfiles "" 3600]


# Create a global cache for im_company entries.
# The cache is bound by global timeout of 1 hour currently.
ns_cache create im_company -timeout [ad_parameter -package_id [im_package_core_id] CacheTimeoutCompanies "" 3600]


# ---------------------------------------------------------------
# Callbacks
#
# Generically create callbacks for all "core" object types
# ---------------------------------------------------------------


set object_types {
    im_biz_object_member
    im_baseline
    im_company
    im_company_employee_rel
    im_component_plugin
    im_conf_item
    im_cost
    im_cost_center
    im_expense
    im_expense_bundle
    im_forum_topic
    im_freelance_rfq
    im_freelance_rfq_answer
    im_fs_file
    im_indicator
    im_investment
    im_invoice
    im_key_account_rel
    im_material
    im_menu
    im_note
    im_office
    im_planning_item
    im_profile
    im_project
    im_repeating_cost
    im_report
    im_risk
    im_sla_parameter
    im_sql_selector
    im_ticket
    im_ticket_queue
    im_ticket_ticket_rel
    im_timesheet_conf_object
    im_timesheet_invoice
    im_timesheet_task
    im_trans_invoice
    im_trans_task
    im_user_absence
    membership_rel
    person
    user
}

# Create callbacks for all objects
foreach object_type $object_types {
    
    ad_proc -public -callback ${object_type}_before_create {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -
    
    ad_proc -public -callback ${object_type}_after_create {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -


    
    ad_proc -public -callback ${object_type}_before_update {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -
    
    ad_proc -public -callback ${object_type}_after_update {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -


    
    ad_proc -public -callback ${object_type}_before_delete {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -
    
    ad_proc -public -callback ${object_type}_after_delete {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -

    ad_proc -public -callback ${object_type}_view {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback tracks acess to the object's main page.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -

    ad_proc -public -callback ${object_type}_form_fill {
        -form_id:required
        -object_id:required
        { -object_type "" }
        { -type_id ""}
        { -page_url "default" }
        { -advanced_filter_p 0 }
        { -include_also_hard_coded_p 0 }
    } {
	This callback tracks acess to the object's main page.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -



}


ad_proc -public -callback im_project_new_redirect {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
    {-project_id:required}
    {-parent_id:required}
    {-company_id:required}
    {-project_type_id:required}
    {-project_name:required}
    {-project_nr:required}
    {-workflow_key:required}
    {-return_url:required}
} {
	This is mainly a callback to redirect from the original new.tcl page to somewhere else
	
	@param project_id ID of the project 
	@param project_status_id Status ID of the project. This allows for quick filtering if the callback implementation is to be executed (e.g. if you only want to execute it for new potential projects)
	@param project_type_id Type ID of the project. This allows for quick filtering if the callback implementation is to be executed (e.g. if you only want to execute it for a certain type of project)
} -


ad_proc -public -callback im_timesheet_task_new_redirect {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
    {-task_id ""}
    {-project_id:required}
    {-edit_p ""}
    {-message ""}
    {-form_mode ""}
    {-task_status_id ""}
    {-return_url:required}
} {
	This is mainly a callback to redirect from the original new.tcl page to somewhere else
	
        @param task_id ID of the task
	@param project_id ID of the project 
        @task_status_id This checks what is the current status of a task 
} -


ad_proc -public -callback im_dynfield_attribute_after_update {
    {-object_type:required}
    {-attribute_name:required}
} {
    Callback to be executed after an attribute has been changed
} -


ad_proc -public -callback im_dynfield_widget_after_update {
    {-widget_name:required}
} {
    Callback to be executed after a widget has been changed
} -


ad_proc -public -callback im_before_member_add {
    {-user_id:required}
    {-object_id:required}
} {
    Callback to be executed before a user is added to a project
} -
