ad_library {
    Automated tests.

    @author Frank Bergmann
    @creation-date 14 June 2024
}

namespace eval im_project::twt {

    ad_proc new { 
	{-name ""}
	{-type_id 2501}
	{-status_id 76}
	{-start_date "" }
	{-end_date "" }
	{-customer_id "" }
	{-parent_id "" }
	{-project_manager_id "" }
    } {
	Create a new invoice 
    } {
	set project_type [im_category_from_id $type_id]
	if {"" eq $name} { set name [ad_generate_random_string 10] }
	set full_name "$project_type $name"
	if {"" eq $start_date} { set start_date "2024-01-02" }
	if {"" eq $end_date} { set start_date "2024-02-03" }
	if {"" eq $customer_id || 0 == $customer_id } { set customer_id [im_company_internal] }

	# Check if project already there
	set project_id [db_string project_p "select project_id from im_projects where project_name = :full_name" -default 0]
	if {0 != $project_id} { return $project_id }

	# Create project plus item
	set project_id [im_project::new -creation_ip '1.1.1.1' -project_name $full_name -project_nr $name -project_path $name -company_id $customer_id -project_type_id $type_id -project_status_id $status_id -parent_id $parent_id]

	if {"" ne $project_manager_id} {
	    db_dml pm_update "update im_projects set project_lead_id = :project_manager_id where project_id = :project_id"
            im_biz_object_add_role $project_manager_id $project_id [im_biz_object_role_project_manager]
	}
	return $project_id
    }

}


namespace eval wf::twt {

    ad_proc enabled_task_ids { 
	{ -case_id 0 }
	{ -object_id 0 }
    } {
	Returns a list of the ids active tasks.
	There should normally be only one active task, or zero if the WF has finished.
    } {
	if {0 != $object_id} { set case_id [db_string "select max(case_id) from wf_cases where object_id = :object_id" -default 0] }
	set tasks [db_list active_task_ids "select task_id from wf_tasks where state = 'enabled' and case_id = :case_id"]
	return $tasks
    }

    ad_proc enabled_task_keys { 
	{ -case_id 0 }
	{ -object_id 0 }
    } {
	Returns a list of the transition keys of active tasks.
	There should normally be only one active task, or zero if the WF has finished.
    } {
	if {0 != $object_id} { set case_id [db_string "select max(case_id) from wf_cases where object_id = :object_id" -default 0] }
	set task_keys [db_list active_task_keys "select transition_key from wf_tasks where state = 'enabled' and case_id = :case_id"]
	return $task_keys
    }

    ad_proc enabled_task_assignees { 
	{ -case_id 0 }
	{ -object_id 0 }
    } {
	Returns a list of assignees (users or groups) of the active tasks.
    } {
	if {0 != $object_id} { set case_id [db_string "select max(case_id) from wf_cases where object_id = :object_id" -default 0] }
	set tasks [db_list active_task_ids "select task_id from wf_tasks where state = 'enabled' and case_id = :case_id"]
	lappend tasks 0
	set assignees [db_list active_task_assignees "
		select	ut.user_id
		from	wf_user_tasks ut
		where	ut.task_id in ([join $tasks ","])
	"]
	return $assignees
    }

    ad_proc task_action { 
	{ -case_id 0 }
	{ -object_id 0 }
	{ -user_id 0 }
	{ -action "finish" }
    } {
	Approve the next WF task
    } {
	if {0 != $object_id} { set case_id [db_string "select max(case_id) from wf_cases where object_id = :object_id" -default 0] }
	if {"" eq $user_id || 0 == $user_id} { set user_id [auth::require_login] }

	# There should be exactly one task active in the WF case
	set task_id [wf::twt::enabled_task_ids -case_id $case_id]
	if {[llength $task_id] > 1} { 
	    ns_log Notice "wf::twt:task_action: Found more than one enabled tasks for wf_case_id=$case_id"
	    return 0 
	}
	if {[llength $task_id] == 0} { 
	    ns_log Notice "wf::twt:task_action: Found no enabled tasks for wf_case_id=$case_id"
	    return 0 
	}
	
	db_1row task_info "
		select	wfc.object_id,
			o.object_type,
			tr.workflow_key,
			tr.transition_key,
			tr.transition_name,
			acs_object__name(wfc.object_id) as object_name
		from	wf_tasks wft,
			wf_cases wfc,
			wf_transitions tr,
			acs_objects o
		where	wft.task_id = :task_id and
			wft.case_id = wfc.case_id and
			wfc.object_id = o.object_id and
			wft.workflow_key = tr.workflow_key and
			wft.transition_key = tr.transition_key
        "

	# Get the list of attribute to be specified in this transition
	# We can deal with transitions with zero or one attributes
	set attribute_name [db_string wf_attributes "
		select	min(aa.attribute_name)
		from	wf_transition_attribute_map tam,
                        acs_attributes aa
		where	tam.workflow_key = :workflow_key and
                        tam.transition_key = :transition_key and
                        tam.attribute_id = aa.attribute_id
	"]

	if {"" ne $attribute_name} { set attribute_hash($attribute_name) "t" }

	# Check if the current user is assigned to the task and try to self-assign if not.
	set user_assigned_p [db_string task_assigned_users "
		select	count(*)
		from	wf_user_tasks ut
		where	ut.task_id = :task_id and
			ut.user_id = :user_id
	"]
	if {!$user_assigned_p} { wf_case_add_task_assignment -task_id $task_id -party_id $user_id }

	set msg "Automatic action=$action from tclwebtest"
	ns_log Notice "wf::twt::task_action: set journal_id \[wf_task_action -user_id $user_id -msg '$msg' -attributes '[array get attribute_hash]' -assignments '[array get assignments]' '$task_id' '$action']"

	set journal_id [wf_task_action -user_id $user_id -msg $msg -attributes [array get attribute_hash] -assignments [array get assignments] $task_id $action]

	return 1
    }
    
}
