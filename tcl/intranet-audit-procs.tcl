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
    if {$debug_p} { ns_log Notice "im_audit_impl: object_id=$object_id, user_id=$user_id, object_type=$object_type, status_id=$status_id, type_id=$type_id, action=$action, baseline_id=$baseline_id, comment=$comment" }

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
	select	a.audit_value as old_value,
		o.object_type,
		o.last_audit_id
	from	im_audits a,
		acs_objects o
	where	o.object_id = :object_id and
		o.last_audit_id = a.audit_id
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

