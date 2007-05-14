# /packages/intranet-core/tcl/intranet-help-procs.tcl
#
# Copyright (C) 2006 ]project-open[
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
    Procedures to deal with "user_exits".
    A use_exit is an exteral (Perl) script that is executed
    by the system in order to allow for systems integration
    with other systems.

    @author frank.bergmann@project-open.com
}


ad_proc -public im_user_exit_call {
    {-nocache 0}
    user_exit
    object_id
} {
    Calls a user_exit in the filesystem.
    Returns any output from the script.
    An empty string means that the execution was successful.
} {
    ns_log Notice "im_user_exit_call: exit=$user_exit, oid=$object_id"
    
    if {$nocache} {
	set user_exit [im_user_exit_file_path $user_exit]
	set exit_exists_p [file executable $user_exit]
    } else {
	set user_exit [util_memoize "im_user_exit_file_path $user_exit"]
	set exit_exists_p [util_memoize "file executable $user_exit"]
    }

    if {!$exit_exists_p} { 
	ns_log Notice "im_user_exit_call: exit=$user_exit, oid=$object_id: user_exit doesnt exist"
	return 0 
    }

    set log_str "${user_exit}($object_id):\n"

    set result 0
    set status [catch { set retstr [exec $user_exit $object_id]} result]

    if { $status == 0 } {

        # The command succeeded, and wrote nothing to stderr. $result 
	# contains what it wrote to stdout, unless you redirected it

	im_exec_dml log "acs_log__debug('user_exit', :log_str||:result)"
	return $status

    } elseif { [string equal $::errorCode NONE] } {

        # The command exited with a normal status, but wrote something
        # to stderr, which is included in $result.

	im_exec_dml log "acs_log__notice('user_exit', :log_str||:result)"
	return $status

    } else {

        switch -exact -- [lindex $::errorCode 0] {

            CHILDKILLED {
                foreach { - pid sigName msg } $::errorCode break

                # A child process, whose process ID was $pid,
                # died on a signal named $sigName.  A human-
                # readable message appears in $msg.

		im_exec_dml log "acs_log__warn('user_exit', :log_str||:msg||': '||:result)"
		return $status
            }

            CHILDSTATUS {

                foreach { - pid code } $::errorCode break

                # A child process, whose process ID was $pid,
                # exited with a non-zero exit status, $code.

		im_exec_dml log "acs_log__warn('user_exit', :log_str||:result)"
		return $status
            }

            CHILDSUSP {

                foreach { - pid sigName msg } $::errorCode break

                # A child process, whose process ID was $pid,
                # has been suspended because of a signal named
                # $sigName.  A human-readable description of the
                # signal appears in $msg.

		im_exec_dml log "acs_log__warn('user_exit', :log_str||:msg||': '||:result)"
		return $status
            }

            POSIX {

                foreach { - errName msg } $::errorCode break

                # One of the kernel calls to launch the command
                # failed.  The error code is in $errName, and a
                # human-readable message is in $msg.

		im_exec_dml log "acs_log__warn('user_exit', :log_str||:msg||': '||:result)"
		return $status
            }

        }
    }

    im_exec_dml log "acs_log__warn('user_exit', ':log_str||': Unknown error - should never have got here')"
    return $status
}


ad_proc -public im_user_exit_list {
} {
    Returns a list of lists with user exits.
    Each user_exit costists of [name 1st_param 2nd_param ...]
} {
    return [list \
	[list user_create user_id] \
	[list user_update user_id] \
	[list user_delete user_id] \
	[list project_create project_id] \
	[list project_update project_id] \
	[list project_delete project_id] \
	[list company_create company_id] \
	[list company_update company_id] \
	[list company_delete company_id] \
	[list trans_task_create trans_task_id] \
	[list trans_task_update trans_task_id] \
	[list trans_task_delete trans_task_id] \
	[list trans_task_assign trans_task_id user_id] \
	[list trans_task_complete trans_task_id] \
    ]
}



ad_proc -public im_user_exit_file_path {
    user_exit
} {
    Determines the file location of a user_exit
} {
    set user_exit_path "[acs_root_dir]/user_exits"
    set user_exit_path [parameter::get -parameter UserExitPath -package_id [im_package_core_id] -default $user_exit_path]
    set user_exit_script [parameter::get -parameter UserExitUserCreate -package_id [im_package_core_id] -default "user_create"]

    return "$user_exit_path/$user_exit"
}

