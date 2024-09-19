# /packages/intranet-core/tcl/intranet-audit-procs.tcl
#
# Copyright (C) 2007 ]project-open[
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
    Stubs for object auditing.
    Audit is implemented in the package intranet-audit.
    This file only contains "stubs" to the calls in intranet-audit.

    @author frank.bergmann@project-open.com
}



# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_core audit_sweep_semaphore 0


# Schedule the audit function (creates a copy of all active main projects...) every few hours
#
set sweeper_interval_hours [parameter::get_from_package_key -package_key intranet-core -parameter AuditProjectProgressIntervalHours -default 24]
if {0 != $sweeper_interval_hours} {
    ad_schedule_proc -thread t [expr $sweeper_interval_hours * 3600] im_audit_sweeper
}



# -------------------------------------------------------------------
# General hooks that do both audit and callbacks
# -------------------------------------------------------------------

ad_proc -public im_audit {
    -object_id:required
    {-user_id "" }
    {-object_type "" }
    {-status_id "" }
    {-type_id "" }
    {-action "after_update" }
    {-comment "" }
    {-debug_p 0}
} {
    Generic audit for all types of objects.
    @param object_id The object that may have changed
    @param object_type We can save one SQL statement if the calling side already knows the type of the object
    @param action One of {before|after} + '_' + {create|update|delete} or {view}:
		Create represent object creation.
		Update is the default.
		Delete refers to a "soft" delete, marking the object as deleted
		Nuke represents complete object deletion - should only be used for demo data.
		Before_update represents checks before the update of important objects im_costs,
		im_project. This way the system can detect changes from outside the system.
    @return $audit_id
} {
    ns_log Notice "im_audit: -object_id=$object_id -user_id=$user_id -object_type=$object_type -status_id=$status_id -type_id=$type_id -action=$action -comment=$comment -debug_p=$debug_p"
    
    # Deal with old action names during the transition period
    if {""              == $action} { set action "after_update" }
    if {"update"        == $action} { set action "after_update" }
    if {"create"        == $action} { set action "after_create" }
    if {"delete"        == $action} { set action "before_nuke" }
    if {"nuke"          == $action} { set action "before_nuke" }
    if {"before_delete" == $action} { set action "before_nuke" }
    if {"after_delete"  == $action} { set action "before_nuke" }

    # ToDo: Remove these checks once 4.0 final is out
    if {"pre_update" == $action} { set action "before_update" }
    if {"before_view" == $action} { set action "view" }
    if {"after_view" == $action} { set action "view" }

    if {"" == $object_type || "" == $status_id || "" == $type_id} {
	if {$debug_p} { ns_log Warning "im_audit: object_type, type_id or status_id not defined for object_id=$object_id" }
	set ref_status_id ""
	set ref_type_id ""
	db_0or1row audit_object_info "
		select	o.object_type,
			im_biz_object__get_status_id(o.object_id) as ref_status_id,
			im_biz_object__get_type_id(o.object_id) as ref_type_id
		from	acs_objects o
		where	o.object_id = :object_id
	"

	if {"" == $status_id && "" != $ref_status_id} { set status_id $ref_status_id }
	if {"" == $type_id && "" != $ref_type_id} { set type_id $ref_type_id }
    }

    if {$debug_p} { ns_log Notice "im_audit: user_id=$user_id, object_id=$object_id, object_type=$object_type, status_id=$status_id, type_id=$type_id, action=$action, comment=$comment" }

    # Submit a callback so that customers can extend events
    set err_msg ""
    if {[catch {
	if {$debug_p} { ns_log Notice "im_audit: About to call callback ${object_type}_${action} -object_id $object_id -status_id $status_id -type_id $type_id" }
	callback ${object_type}_${action} -object_id $object_id -status_id $status_id -type_id $type_id
    } err_msg]} {
	ns_log Error "im_audit: Error with callback ${object_type}_${action} -object_id $object_id -status_id $status_id -type_id $type_id:\n$err_msg"
    }

    # Call the audit implementation from intranet-audit commercial package if exists
    set err_msg ""
    set audit_id 0
    set audit_p [parameter::get_from_package_key -package_key intranet-core -parameter AuditP -default 1]
    if {$audit_p} {
	if {$debug_p} { ns_log Notice "im_audit: About to call: im_audit_impl -user_id $user_id -object_id $object_id -object_type $object_type -status_id $status_id -action $action -comment $comment" }
	if {[catch {
	    set audit_id [im_audit_impl -user_id $user_id -object_id $object_id -object_type $object_type -status_id $status_id -action $action -debug_p $debug_p -comment $comment]
	} err_msg]} {
	    ns_log Error "im_audit: Error executing im_audit_impl: $err_msg\n[ad_print_stack_trace]"
	}
    }

    return $audit_id
}




# ----------------------------------------------------------------------
# Audit Procedures
# ----------------------------------------------------------------------

ad_proc -public im_audit_object_type_sql { 
    -object_type:required
} {
    Calculates the SQL statement to extract the value for an object
    of the given object_type. The SQL will contains a ":object_id"
    colon-variables, so the variable "object_id" must be defined in 
    the context where this statement is to be executed.
} {
    ns_log Notice "im_audit_object_type_sql: object_type=$object_type"

    # ---------------------------------------------------------------
    # Construct a SQL that pulls out all information about one object
    set base_table_sql "
	select	table_name as base_table_name,
		id_column as base_id_column
	from	acs_object_types
	where	object_type = :object_type
    "
    db_1row base_table $base_table_sql

    set ext_table_sql "
	select	table_name,
		id_column
	from	acs_object_type_tables
	where	object_type = :object_type
    "

    set letters {b c d e f g h i j k l m n o p q r s t u v w x y z}
    set froms {}
    set wheres { "1=1" }
    set cnt 0
    set sql "select * from $base_table_name a"
    db_foreach ext_tables $ext_table_sql {
	set letter [lindex $letters $cnt]
	append sql " LEFT OUTER JOIN $table_name $letter ON (a.$base_id_column = $letter.$id_column)"
	incr cnt
    }

    append sql " where a.$base_id_column = :object_id"

    ns_log Notice "im_audit_object_type_sql: About to return sql=$sql"
    return $sql
}


ad_proc -public im_audit_object_rels_sql { 
} {
    Returns the SQL for pulling out all relationships for an object
} {
    ns_log Notice "im_audit_object_rels_sql:"

    # Get the list of all sub relationships, together with their meta-information
    set sub_rel_sql "
	select	aot.*
	from	acs_object_types aot
	where	aot.supertype = 'relationship'
    "
    set outer_joins ""
    db_foreach sub_rels $sub_rel_sql {
	if {![im_table_exists $table_name]} { continue }
	append outer_joins "LEFT OUTER JOIN $table_name ON (r.rel_id = $table_name.$id_column)\n\t\t"
    }

    set sql "
	select	*
	from	acs_rels r
		$outer_joins
	where	(r.object_id_one = :object_id or r.object_id_two = :object_id)
	order by
		r.rel_id
    "

    return $sql
}


ad_proc -public im_audit_object_rels { 
    -object_id:required
} {
    Creates a single string for the object's relationships with other objects.
} {
    ns_log Notice "im_audit_object_rels: object_id=$object_id"

    # Get the SQL for pulling out all rels of an object
    set sql [util_memoize [list im_audit_object_rels_sql]]

    # Execute the sql. As a result we get "col_names" with list of columns and "lol" with the result list of lists
    set col_names ""
    db_with_handle db {
	set selection [db_exec select $db query $sql 1]
	set lol [list]
	while { [db_getrow $db $selection] } {
	    set col_names [ad_ns_set_keys $selection]
	    set this_result [list]
	    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		lappend this_result [ns_set value $selection $i]
	    }
	    lappend lol $this_result
	}
    }
    db_release_unused_handles

    if {![info exists col_names]} {
	ns_log Error "im_audit_object_rels: For some reason we didn't find any record matching sql=$sql"
	return ""
    }

    set result_list ""
    foreach col_values $lol {
	set value_list ""
	for {set i 0} {$i < [llength $col_names]} {incr i} {
	    set var [lindex $col_names $i]
	    set val [lindex $col_values $i]
	    if {"" == $val} { continue }
	    lappend value_list $var $val
	}
	# The result list is an "array" type of key-value list.
	lappend result_list [join $value_list " "]
    }

    return $result_list
}


# ----------------------------------------------------------------------
# Main Audit Procedure
# ----------------------------------------------------------------------

ad_proc -public im_audit_calculate_diff { 
    -old_value:required
    -new_value:required
} {
    Calculates the difference between and old an a new value and
    returns only the lines that have changed.
    Each line consists of: variable \t value \n.
} {
    foreach old_line [split $old_value "\n"] {
	set pieces [split $old_line "\t"]
	set var [lindex $pieces 0]
	set val [lindex $pieces 1]
	set hash($var) $val
    }

    set diff ""
    foreach new_line [split $new_value "\n"] {
	set pieces [split $new_line "\t"]
	set var [lindex $pieces 0]
	set val [lindex $pieces 1]
	set old_val ""
	if {[info exists hash($var)]} { set old_val $hash($var) }
	if {$val != $old_val} { append diff "$new_line\n" }
    }

    return $diff   
}




ad_proc -public im_audit_object_value { 
    -object_id:required
    { -object_type "" }
} {
    Concatenates the value of all object fields (according to DynFields)
    to form a single string describing the object's values.
} {
    ns_log Notice "im_audit_object_value: object_id=$object_id, object_type=$object_type"
    im_security_alert_check_integer -location "im_audit_object_value: object_id" -value $object_id

    if {"" == $object_id} { return "" }
    im_security_alert_check_integer -location "im_audit_object_value" -value $object_id

    if {"" == $object_type} {
	set object_type [util_memoize [list db_string otype "select object_type from acs_objects where object_id = $object_id" -default ""]]
    }
    if {"" == $object_type} {
	ns_log Warning "im_audit_object_value -object_id $object_id:  Database inconsistency: found an empty object_type"
	return
    }

    # Get the SQL to extract all values from the object
    set sql [util_memoize [list im_audit_object_type_sql -object_type $object_type]]

    # Execute the sql. As a result we get "col_names" with list of columns and "lol" with the result list of lists
    set col_names ""
    db_with_handle db {
	set selection [db_exec select $db query $sql 1]
	set lol [list]
	while { [db_getrow $db $selection] } {
	    set col_names [ad_ns_set_keys $selection]
	    set this_result [list]
	    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		lappend this_result [ns_set value $selection $i]
	    }
	    lappend lol $this_result
	}
    }
    db_release_unused_handles

    if {![info exists col_names]} {
	ns_log Error "im_audit_object_value: For some reason we didn't find any record matching sql=$sql"
	return ""
    }

    # lol should have only a single line!
    set col_values [lindex $lol 0]

    set value ""
    for {set i 0} {$i < [llength $col_names]} {incr i} {
	set var [lindex $col_names $i]
	set val [lindex $col_values $i]

	# We need to quote \n and \t in $val because it is used to separate values
	regsub -all {\n} $val {\n} val
	regsub -all {\t} $val {\t} val

	# Skip a number of known internal variables
	if {"tree_sortkey" == $var} { continue }
	if {"max_child_sortkey" == $var} { continue }
	if {"rule_engine_old_value" == $var} { continue }

	# Add the line to the "value"
	append value "$var	$val\n"
    }
    
    # Add information about the object's relationships
    set audit_rels_p [parameter::get_from_package_key \
		-package_key intranet-core \
		-parameter AuditObjectRelationshipsP \
		-default 1 \
    ]
    if {$audit_rels_p} {
	foreach rel_record [im_audit_object_rels -object_id $object_id] {
	    array unset rel_hash
	    array set rel_hash $rel_record
	    set rel_id $rel_hash(rel_id)
	    unset rel_hash(rel_id)
	    set list ""
	    foreach key [lsort [array names rel_hash]] {
		lappend list "$key $rel_hash($key)"
	    }
	    append value "acs_rel-$rel_id	[join $list " "]\n"
	}
    }

    return $value
}


ad_proc -public im_audit_impl { 
    -object_id:required
    {-baseline_id "" }
    {-user_id "" }
    {-object_type "" }
    {-status_id "" }
    {-type_id "" }
    {-action "after_update" }
    {-comment "" }
    {-debug_p 0}
} {
    Creates a new audit item for object after an update.
    @param baseline_id A baseline is a version of a project.
           baseline_id != "" means that we have to write a new version.
	   The baseline_id is stored in im_audits.baseline_id,
	   because baselines always refer to projects.
} {
    ns_log Notice "im_audit_impl: object_id=$object_id user_id=$user_id object_type=$object_type status_id=$status_id type_id=$type_id action=$action baseline_id=$baseline_id comment=$comment"
    if {$debug_p} { }

    set baseline_exists_p [im_column_exists im_audits audit_baseline_id]
    set is_connected_p [ns_conn isconnected]
    set peeraddr "0.0.0.0"
    set x_forwarded_for "0.0.0.0"
    if {"" eq $user_id} { set user_id 0 }

    if {$is_connected_p} {
	set peeraddr [ns_conn peeraddr]
	if {0 eq $user_id} { set user_id [ad_conn user_id] }

	# Get the IP of the browser of the user
	set header_vars [ns_conn headers]
	set x_forwarded_for [ns_set get $header_vars "X-Forwarded-For"]
	if {"" != $x_forwarded_for} {
	    set peeraddr $x_forwarded_for
	}
    }

    if {"" == $action} { set action "update" }
    set action [string tolower $action]

    # Get information about the audit object
    set object_type ""
    set old_value ""
    set last_audit_id ""
    db_0or1row last_info "
	select 	a.audit_value as old_value,
		o.object_type,
		o.last_audit_id
	from 	acs_objects o
		LEFT OUTER JOIN im_audits a ON (o.last_audit_id = a.audit_id)
	where 	o.object_id = :object_id
    "

    # Get the new value from the database
    # new_value can be null in case of broken/inconsistent objects
    set new_value [im_audit_object_value -object_id $object_id -object_type $object_type]

    # Calculate the "diff" between old and new value.
    # Return "" if nothing has changed:
    set diff [im_audit_calculate_diff -old_value $old_value -new_value $new_value]

    set new_audit_id ""
    if {"" ne $new_value && ("" ne $diff || "" ne $baseline_id)} {
	# Something has changed...
	# Create a new im_audit entry and associate it to the object.
	set new_audit_id [db_nextval im_audit_seq]
	set audit_ref_object_id ""
	set audit_note $comment
	set audit_hash ""

	set baseline_sql1 ""
	set baseline_sql2 ""
	if {$baseline_exists_p} {
	    set baseline_sql1 ", audit_baseline_id"
	    set baseline_sql2 ", :baseline_id"
	}
	
	db_dml insert_audit "
		insert into im_audits (
			audit_id,
			audit_object_id,
			audit_object_status_id,
			audit_action,
			audit_user_id,
			audit_date,
			audit_ip,
			audit_last_id,
			audit_ref_object_id,
			audit_value,
			audit_diff,
			audit_note,
			audit_hash
			$baseline_sql1
		) values (
			:new_audit_id,
			:object_id,
			im_biz_object__get_status_id(:object_id),
			:action,
			:user_id,
			now(),
			:peeraddr,
			:last_audit_id,
			:audit_ref_object_id,
			:new_value,
			:diff,
			:audit_note,
			:audit_hash
			$baseline_sql2
		)
	"

	if {"" == $baseline_id} {
	    # Update the last_audit_id ONLY if this was not a baseline.
	    # Baselines can be deleted, and the foreign key constraint
	    # would give trouble with that.
	    db_dml update_object "
		update acs_objects set
			last_audit_id = :new_audit_id,
			last_modified = now(),
			modifying_user = :user_id,
			modifying_ip = :peeraddr
		where object_id = :object_id
	    "
	}

	# Action="view": Send out an email to inform the security guy about an unaudited change
	set audit_missed_grave_p [parameter::get_from_package_key -package_key "intranet-audit" -parameter AuditMissedGraveP -default 0]
	if {$action in {"view"} && $audit_missed_grave_p} {
	    set object_name [acs_object_name $object_id]
	    set message "Unaudited change of #$object_id: $object_name"
	    ns_log Notice "im_audit_impl: im_security_alert -location 'im_audit_impl' -message '$message' -value '$object_id' -severity 'Normal'"
	    ns_log Notice "im_audit_impl: new_value='$new_value'"
	    ns_log Notice "im_audit_impl: diff='$diff'"
	    ns_log Notice "im_audit_impl: baseline_id='$baseline_id'"

	    im_security_alert -location "im_audit_impl" -message $message -value $object_id -severity "Normal"
	}
    }

    return $new_audit_id
}



# -------------------------------------------------------------------
# Audit Sweeper - Make a copy of all "active" projects
# -------------------------------------------------------------------

ad_proc -public im_audit_sweeper { } {
    Make a copy of all "active" projects
} {
    set audit_exists_p [im_table_exists "im_audits"]
    if {!$audit_exists_p} { return }

    # Make sure that only one thread is sweeping at a time
    if {[nsv_incr intranet_core audit_sweep_semaphore] > 1} {
        nsv_incr intranet_core audit_sweep_semaphore -1
        ns_log Notice "im_core_audit_sweeper: Aborting. There is another process running"
        return "busy"
    }

    set debug ""
    set err_msg ""
    set counter 0
    if {[catch {
	set interval_hours [parameter::get_from_package_key \
		-package_key intranet-core \
		-parameter AuditProjectProgressIntervalHours \
		-default 0 \
        ]

	if {0 == $interval_hours} { set interval_hours 24 }

	# Select all "active" (=not deleted or canceled) main projects
	# without an update in the last X hours
	set project_sql "
	select	project_id
	from	im_projects
	where	parent_id is null and
		project_status_id not in ([im_project_status_deleted]) and
		project_id not in (
			select	distinct audit_object_id
			from	im_audits
			where	audit_date > (now() - '$interval_hours hours'::interval)
		)
        "
	db_foreach audit $project_sql {
	    append debug [im_audit -object_id $project_id]
	    lappend debug $project_id
	    incr counter
	}
    } err_msg]} {
	ns_log Error "im_audit_sweeper: $err_msg"
    }

    # Free the semaphore for next use
    nsv_incr intranet_core audit_sweep_semaphore -1

    return [string trim "$counter $debug $err_msg"]
}




# -------------------------------------------------------------------
# Prettifier: Remove system fields and lines
# -------------------------------------------------------------------

ad_proc -public im_audit_prettify_diff {
    {-ignore_fields {}}
    -object_type
    -diff
} {
    Remove unnecessary lines from an audit diff to make it human readable.
} {
    # Initialize the hash with pretty names with some static values
    array set pretty_name_hash [im_audit_attribute_pretty_names -object_type $object_type]
    array set ignore_hash [im_audit_attribute_ignore -object_type $object_type]
    array set deref_hash [im_audit_attribute_deref -object_type $object_type]
    foreach field $ignore_fields { set ignore_hash($field) 1 }; # custom ignore additions

    # Prettify the audit_diff.
    # Go through values and dereference them.
    set audit_diff_pretty ""

    array unset attribute_name_hash
    foreach field [split [string map {\" ''} $diff] "\n"] {
	set attribute_name [lindex $field 0]
	set attribute_value [lrange $field 1 end]
	
	# Deal with relatinship names
	if {[regexp {^acs_rel} $attribute_name match]} {
	    catch {
		set attribute_value [im_audit_format_rel_value -object_id $object_id -value $attribute_value]
	    }
	}
	
	# Should we ignore this field? Or is it duplicate?
	if {[info exists ignore_hash($attribute_name)]} { continue }
	if {[info exists attribute_name_hash($attribute_name)]} { continue }
	set attribute_name_hash($attribute_name) 1
	
	# Determine the pretty_name for the field
	set pretty_name $attribute_name
	if {[info exists pretty_name_hash($attribute_name)]} { set pretty_name $pretty_name_hash($attribute_name) }
	
	# Determine the pretty_value for the field
	set pretty_value $attribute_value
	
	# Apply the dereferencing function if available
	# This function will pull out the object name for an ID
	# or the category for a category_id
	if {[info exists deref_hash($attribute_name)]} {
	    set deref_function $deref_hash($attribute_name)
	    set pretty_value [db_string deref "select ${deref_function}(:attribute_value)"]
	}
	
	# Skip the field if the attribute_name is empty.
	# This could be the last line of the audit_diff or audit_value field
	if {"" == $attribute_name} { continue }
	
	if {"" != $audit_diff_pretty} { append audit_diff_pretty ",\n<br>" }
	append audit_diff_pretty "$pretty_name = $pretty_value"
    }
    
    return $audit_diff_pretty
}



ad_proc -public im_audit_attribute_pretty_names {
    -object_type:required
} {
    Returns a key-value list of pretty names for object attributes
} {
    return [im_audit_attribute_pretty_names_helper -object_type $object_type]
    return [util_memoize [list im_audit_attribute_pretty_names_helper -object_type $object_type]]
}


ad_proc -public im_audit_attribute_pretty_names_helper {
    -object_type:required
} {
    Returns a key-value list of pretty names for object attributes
} {
    # Get the list of all define DynField names
    set dynfield_sql "
	select	*
	from	acs_attributes aa,
		im_dynfield_attributes da
	where	aa.attribute_id = da.acs_attribute_id and
		aa.object_type = :object_type
    "
    db_foreach dynfields $dynfield_sql {
	set pretty_name_hash($attribute_name) $pretty_name
    }

    set pretty_name_hash(project_id) [lang::message::lookup "" intranet-core.Project_ID "Project ID"]
    set pretty_name_hash(project_name) [lang::message::lookup "" intranet-core.Project_Name "Project Name"]
    set pretty_name_hash(project_nr) [lang::message::lookup "" intranet-core.Project_Nr "Project Nr"]
    set pretty_name_hash(project_path) [lang::message::lookup "" intranet-core.Project_Path "Project Path"]
    set pretty_name_hash(project_type_id) [lang::message::lookup "" intranet-core.Project_Type "Project Type"]
    set pretty_name_hash(project_status_id) [lang::message::lookup "" intranet-core.Project_Status "Project Status"]
    set pretty_name_hash(project_lead_id) [lang::message::lookup "" intranet-core.Project_Manager "Project Manager"]

    # Project standard fields
    set pretty_name_hash(start_date) [lang::message::lookup "" intranet-core.Start_Date "Start Date"]
    set pretty_name_hash(end_date) [lang::message::lookup "" intranet-core.End_Date "End Date"]
    set pretty_name_hash(description) [lang::message::lookup "" intranet-core.Description "Description"]
    set pretty_name_hash(note) [lang::message::lookup "" intranet-core.Note "Note"]
    set pretty_name_hash(parent_id) [lang::message::lookup "" intranet-core.Parent_ID "Parent"]
    set pretty_name_hash(company_id) [lang::message::lookup "" intranet-core.Company_ID "Company"]
    set pretty_name_hash(template_p) [lang::message::lookup "" intranet-core.Template_p "Template?"]

    # Project Cost Cache
    set pretty_name_hash(cost_bills_cache) [lang::message::lookup "" intranet-core.Cost_Bills_Cache "Bills Cache"]
    set pretty_name_hash(cost_delivery_notes_cache) [lang::message::lookup "" intranet-core.Cost_Delivery_Notes_Cache "Delivery Notes Cache"]
    set pretty_name_hash(cost_expenses_logged_cache) [lang::message::lookup "" intranet-core.Cost_Expenses_Logged_Cache "Expenses Logged Cache"]
    set pretty_name_hash(cost_expenses_planned_cache) [lang::message::lookup "" intranet-core.Cost_Expenses_Planned_Cache "Expenses Planned Cache"]
    set pretty_name_hash(cost_invoices_cache) [lang::message::lookup "" intranet-core.Cost_Invoices_Cache "Invoices Cache"]
    set pretty_name_hash(cost_purchase_orders_cache) [lang::message::lookup "" intranet-core.Cost_Purchase_Orders_Cache "Purchase Orders Cache"]
    set pretty_name_hash(cost_quotes_cache) [lang::message::lookup "" intranet-core.Cost_Quotes_Cache "Quotes Cache"]
    set pretty_name_hash(cost_timesheet_logged_cache) [lang::message::lookup "" intranet-core.Cost_Timesheet_Logged_Cache "Timesheet Logged Cache"]
    set pretty_name_hash(cost_timesheet_planned_cache) [lang::message::lookup "" intranet-core.Cost_Timesheet_Planned_Cache "Timesheet Planned Cache"]
    set pretty_name_hash(reported_days_cache) [lang::message::lookup "" intranet-core.Cost_Reported_Days_Cache "Reported Days Cache"]
    set pretty_name_hash(reported_hours_cache) [lang::message::lookup "" intranet-core.Cost_Reported_Days_Cache "Reported Days Cache"]


    # Ticket fields
    set pretty_name_hash(ticket_done_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Done_Date "Ticket Done Date"]
    set pretty_name_hash(ticket_creation_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Creation_Date "Ticket Creation Date"]
    set pretty_name_hash(ticket_alarm_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Alarm_Date "Ticket Alarm Date"]
    set pretty_name_hash(ticket_reaction_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Reaction_Date "Ticket Reaction Date"]
    set pretty_name_hash(ticket_confirmation_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Confirmation_Date "Ticket Confirmation Date"]
    set pretty_name_hash(ticket_signoff_date) [lang::message::lookup "" intranet-helpdesk.Ticket_Signoff_Date "Ticket Signoff Date"]

    return [array get pretty_name_hash]
}




ad_proc -public im_audit_attribute_ignore {
    -object_type:required
} {
    Returns a hash of attributes to be ignored in the audit package
} {
    return [util_memoize [list im_audit_attribute_ignore_helper -object_type $object_type]]
    # return [im_audit_attribute_ignore_helper -object_type $object_type]
}


ad_proc -public im_audit_attribute_ignore_helper {
    -object_type:required
} {
    Returns a hash of attributes to be ignored in the audit package
} {
    set additional_ignores [parameter::get_from_package_key -package_key intranet-core -parameter AuditIgnoreAdditionalFields -default {}]
    foreach field $additional_ignores { set ignore_hash($field) 1 }

    # Project Cost Cache (automatically updated)
    set ignore_hash(cost_bills_cache) 1
    set ignore_hash(cost_delivery_notes_cache) 1
    set ignore_hash(cost_expense_logged_cache) 1
    set ignore_hash(cost_expense_planned_cache) 1
    set ignore_hash(cost_invoices_cache) 1
    set ignore_hash(cost_purchase_orders_cache) 1
    set ignore_hash(cost_quotes_cache) 1
    set ignore_hash(cost_timesheet_logged_cache) 1
    set ignore_hash(cost_timesheet_planned_cache) 1

    set ignore_hash(reported_days_cache) 1
    set ignore_hash(reported_hours_cache) 1
    set ignore_hash(cost_cache_dirty) 1

    # Obsolete project fields
    set ignore_hash(corporate_sponsor) 1
    set ignore_hash(percent_completed) 1
    set ignore_hash(requires_report_p) 1
    set ignore_hash(supervisor_id) 1
    set ignore_hash(team_size) 1
    set ignore_hash(trans_project_hours) 1
    set ignore_hash(trans_project_words) 1
    set ignore_hash(trans_size) 1

    # Ticket automatically updated fields
    set ignore_hash(ticket_resolution_time) 1
    set ignore_hash(ticket_resolution_time_per_queue) 1
    set ignore_hash(ticket_resolution_time_dirty) 1

    # The rule engine stores the last audit value...
    set ignore_hash(modifying_ip) 1
    set ignore_hash(last_modified) 1
    set ignore_hash(rule_engine_last_modified) 1
    set ignore_hash(rule_engine_old_value) 1
    set ignore_hash(last_audit_id) 1

    return [array get ignore_hash]
}


ad_proc -public im_audit_attribute_deref {
    -object_type:required
} {
    Returns a hash of deref functions for important attributes
} {
    return [util_memoize [list im_audit_attribute_deref_helper -object_type $object_type]]
    # return [im_audit_attribute_deref_helper -object_type $object_type]
}


ad_proc -public im_audit_attribute_deref_helper {
    -object_type:required
} {
    Returns a hash of deref functions for important attributes
} {
    # Get DynField meta-information and write into a hash array
    set dynfield_sql "
	select	aa.attribute_name,
		aa.pretty_name,
		dw.deref_plpgsql_function
	from	acs_attributes aa,
		im_dynfield_attributes da,
		im_dynfield_widgets dw
	where	aa.attribute_id = da.acs_attribute_id and
		da.widget_name = dw.widget_name and
		aa.object_type = :object_type
    "
    db_foreach dynfields $dynfield_sql {
	set deref_hash($attribute_name) $deref_plpgsql_function
    }

    # Manually add a few frequently used deref functions

    set deref_hash(project_id) "acs_object__name"
    set deref_hash(company_id) "acs_object__name"
    set deref_hash(ticket_id) "acs_object__name"

    set deref_hash(status_id) "im_category_from_id"
    set deref_hash(project_status_id) "im_category_from_id"
    set deref_hash(ticket_status_id) "im_category_from_id"
    set deref_hash(type_id) "im_category_from_id"
    set deref_hash(project_type_id) "im_category_from_id"
    set deref_hash(ticket_type_id) "im_category_from_id"

    set deref_hash(ticket_prio_id) "im_category_from_id"
    set deref_hash(ticket_customer_contact_id) "im_name_from_user_id"
    set deref_hash(ticket_assignee_id) "acs_object__name"
    set deref_hash(ticket_queue_id) "acs_object__name"

    return [array get deref_hash]
}




ad_proc -public im_audit_format_rel_value {
    -object_id:required
    -value:required
} {
    Returns a formatted pretty string representing a relationship
} {
    ns_log Notice "im_audit_format_rel_value: object_id=$object_id, value='$value'"
    array set rel_hash $value

    set object_id_one ""
    if {[info exists rel_hash(object_id_one)]} {
	set object_id_one $rel_hash(object_id_one)
	unset rel_hash(object_id_one)
    }

    set object_id_two ""
    if {[info exists rel_hash(object_id_two)]} {
	set object_id_two $rel_hash(object_id_two)
	unset rel_hash(object_id_two)
    }

    set rel_type ""
    if {[info exists rel_hash(rel_type)]} {
	set rel_type $rel_hash(rel_type)
	unset rel_hash(rel_type)
    }

    if {$object_id_one == $object_id} {
	set arrow [im_gif arrow_left]
	set other_object_id $object_id_two
    } else {
	set arrow [im_gif arrow_right]
	set other_object_id $object_id_one
    }

    set other_object_name "undefined"
    if {"" != $other_object_id && [string is integer $other_object_id]} {
        set other_object_name [util_memoize [list acs_object_name $other_object_id]]
    }
    set result "$rel_type $arrow $other_object_name"
    set list ""
    foreach key [lsort [array names rel_hash]] {
	lappend list "$key $rel_hash($key)"
    }
    return $result
}

