# /packages/intranet-core/tcl/intranet-ds-procs.tcl
#
# Copyright (C) 20012 ]project-open[
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
    Procedures to write out Developer Support messages
    @author frank.bergmann@project-open.com
}


ad_proc -public im_ds_display_config_info {
} {
    Write out the debugging information
} {
    # Fast exit if not enabled
    if {![ds_user_switching_enabled_p]} { return }

    # --------------------------------------------
    # Write out the list of privileges checked
    #
    array set privilege_hash [nsv_array get privilege_hash]
    set privilege_list [list]
    foreach key [array names privilege_hash] {
	if {"request" == $key} { continue }
	set value $privilege_hash($key)
	set key_elements [split $key "-"]
	set package_id [lindex $key_elements 0]
	set privilege [lindex $key_elements 1]
	set package_name $package_id
	if {[string is integer $package_id]} { set package_name [acs_object_name $package_id] }
	lappend privilege_list "$package_name: $privilege = $value"
    }

    set privilege_list [lsort $privilege_list]
    foreach privilege_line $privilege_list {
	ds_comment "Privilege: $privilege_line"
    }

    # --------------------------------------------
    # Write out the list of parameters checked:
    #
    array set parameter_hash [nsv_array get parameter_hash]
    set parameter_list [list]
    foreach key [array names parameter_hash] {
	if {"request" == $key} { continue }
	set value $parameter_hash($key)
	set key_elements [split $key "-"]
	set package_id [lindex $key_elements 0]
	set parameter [lindex $key_elements 1]
	set package_name $package_id
	if {[string is integer $package_id]} { set package_name [acs_object_name $package_id] }
	lappend parameter_list "$package_name: $parameter = $value"
    }

    set parameter_list [lsort $parameter_list]
    foreach parameter_line $parameter_list {
	ds_comment "Parameter: $parameter_line"
    }

}



ad_proc -public im_ds_restart_with_new_request {
} {
    Check if the request has changed and clear up caches before
    storing the stuff of the new request
} {
    # Get the current number of this request
    global ad_conn
    set current_request ""
    if {[info exists ad_conn(request)] } { set current_request $ad_conn(request) }

    # Get the last request number from the parameter_hash
    array set parameter_hash [nsv_array get parameter_hash]
    set last_request ""
    if {[info exists parameter_hash(request)]} { set last_request $parameter_hash(request) }
    # ds_comment "Restart: current_request=$current_request, last_request=$last_request"

    # Reset the parameter_hash both locally and on the NSV thread structure
    # ds_comment "current_request=$current_request, last_request=$last_request"
    if {$current_request != $last_request} {
	# ds_comment "Restart: reset"
	array unset parameter_hash
	set parameter_hash(request) $current_request
	nsv_array reset parameter_hash [list request $current_request]
	nsv_array reset privilege_hash [list]
    }
}


ad_proc -public im_ds_comment_parameter {
    -package_id:required
    -parameter:required
    -result:required
} {
    Write out the results of a parameter call to OpenACS Developer Support
} {
    # Fast exit if not enabled
    if {![ds_user_switching_enabled_p]} { return }

    # ds_comment "Parameter: package_id=$package_id, parameter=$parameter, result=$result"
    im_ds_restart_with_new_request

    # set stack [list]
    # for {set i 0} {$i <= [info level]} {incr i} { lappend stack [info level $i] }
    # ds_comment "Stack=[join $stack "\n"]"

    array set parameter_hash [nsv_array get parameter_hash]
    set key "$package_id-$parameter"
    set parameter_hash($key) $result
    nsv_array set parameter_hash [array get parameter_hash]
}



ad_proc -public im_ds_comment_privilege {
    -user_id:required
    -privilege:required
    -result:required
} {
    Write out the results of a parameter call to OpenACS Developer Support
} {
    # Fast exit if not enabled
    if {![ds_user_switching_enabled_p]} { return }

    # ds_comment "Permission: user_id=$user_id, privilege=$privilege, result=$result"
    im_ds_restart_with_new_request

    array set privilege_hash [nsv_array get privilege_hash]
    set key "$user_id-$privilege"
    set privilege_hash($key) $result
    nsv_array set privilege_hash [array get privilege_hash]
}

