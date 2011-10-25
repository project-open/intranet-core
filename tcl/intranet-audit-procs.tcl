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
    This file only contains "stubs" to the calls in
    intranet-audit.

    @author frank.bergmann@project-open.com
}



# -------------------------------------------------------------------
# 
# -------------------------------------------------------------------

ad_proc -public im_audit  {
    -object_id:required
    {-user_id "" }
    {-object_type "" }
    {-status_id "" }
    {-type_id "" }
    {-action "after_update" }
    {-comment "" }
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
    if {""       == $action} { set action "after_update" }
    if {"update" == $action} { set action "after_update" }
    if {"create" == $action} { set action "after_create" }
    if {"delete" == $action} { set action "after_delete" }
    if {"nuke"   == $action} { set action "after_delete" }

    # ToDo: Remove these checks once 4.0 final is out
    if {"pre_update" == $action} { set action "before_update" }
    if {"before_view" == $action} { set action "before_update" }
    if {"after_view" == $action} { set action "after_update" }

    if {"" == $object_type || "" == $status_id || "" == $type_id} {
	ns_log Warning "im_audit: object_type, type_id or status_id not defined for object_id=$object_id"
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

    ns_log Notice "im_audit: object_id=$object_id, object_type=$object_type, status_id=$status_id, type_id=$type_id, action=$action, comment=$comment"

    # Submit a callback so that customers can extend events
    set err_msg ""
    if {[catch {
	ns_log Notice "im_audit: About to call callback ${object_type}_${action} -object_id $object_id -status_id $status_id -type_id $type_id"
	callback ${object_type}_${action} -object_id $object_id -status_id $status_id -type_id $type_id
    } err_msg]} {
	ns_log Error "im_audit: Error with callback ${object_type}_${action} -object_id $object_id -status_id $status_id -type_id $type_id:\n$err_msg"
    }

    # Call the audit implementation from intranet-audit commercial package if exists
    set err_msg ""
    set intranet_audit_exists_p [util_memoize [list db_string audit_exists_p "select count(*) from apm_packages where package_key = 'intranet-audit'"]]

    ns_log Notice "im_audit: intranet_audit_exists_p=$intranet_audit_exists_p"

    set audit_id 0
    if {$intranet_audit_exists_p} {
	if {[catch {
	    set audit_id [im_audit_impl -user_id $user_id -object_id $object_id -object_type $object_type -status_id $status_id -action $action -comment $comment]
	} err_msg]} {
	    ns_log Error "im_audit: Error executing im_audit_impl: $err_msg"
	}
    }

    return $audit_id
}



ad_proc -public im_project_audit  {
    -project_id:required
    {-user_id "" }
    {-action "after_update" }
    {-object_type "im_project" }
    {-status_id "" }
    {-type_id "" }
    {-action "after_update" }
    {-comment "" }
} {
    Specific audit for projects. This audit keeps track of the cost cache with each
    project, allowing for EVA Earned Value Analysis.
} {
    set intranet_audit_exists_p [util_memoize [list db_string audit_exists_p "select count(*) from apm_packages where package_key = 'intranet-audit'"]]
    if {!$intranet_audit_exists_p} { return "" }

    return [im_project_audit_impl \
		-user_id $user_id \
		-object_type $object_type \
		-project_id $project_id \
		-status_id $status_id \
		-type_id $type_id \
		-action $action \
		-comment $comment
    ]
}

