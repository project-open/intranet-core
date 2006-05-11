ad_page_contract {
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2006-05-10
    @cvs-id $Id$
} {
    user_exit
    user_id
    project_id
    company_id
    trans_task_id
}

# ------------------------------------------------------
# Default & Security
# ------------------------------------------------------

set page_title "Invoke User Exit"
set context_bar [im_context_bar $page_title]

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $user_exit} {
    ad_return_complaint 1 "User Exit is empty"
    return
}

# ------------------------------------------------------
# Execute the user_exit
# ------------------------------------------------------

set user_exit_path "[acs_root_dir]/user_exits"
set user_exit_path [parameter::get -parameter UserExitPath -package_id [im_package_core_id] -default $user_exit_path]
# set exit_files [fileutil::find $user_exit_path]

set user_exit_list [im_user_exit_list]

set object_id 0
foreach user_exit_def $user_exit_list {
    set user_exit_name [lindex $user_exit_def 0]
    set user_exit_param1 [lindex $user_exit_def 1]

    if {[string equal $user_exit $user_exit_name]} {
	catch {
	    set object_id [expr \$$user_exit_param1]
	} errmsg
    }
}

set user_exit_call "$user_exit $object_id"
set err_code [im_user_exit_call $user_exit $object_id]


# ------------------------------------------------------
# Show the trace
# ------------------------------------------------------

set query "
        select	*,
		to_char(log_date, 'YYYY-MM-DD HH24:MM') as log_date_pretty
        from	acs_logs
	order by
		log_date DESC
	limit 10
"
db_multirow logs log_query $query


ad_return_template

