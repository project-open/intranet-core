ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2006-05-10
    @cvs-id $Id$
} {

}

# ******************************************************
# Default & Security
# ******************************************************

set page_title "User Exits"
set context_bar [im_context_bar $page_title]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# Default values for the test
set default_user_id $user_id
set default_project_id [db_string project_id "select min(project_id) from im_projects" -default 0]
set default_company_id [db_string company_id "select min(company_id) from im_companies" -default 0]

set default_trans_task_id 0
if {[im_table_exists "im_trans_tasks"]} {
    set default_trans_task_id [db_string company_id "select min(task_id) from im_trans_tasks" -default 0]
}

# ******************************************************
# Create the list of Widgets
# ******************************************************

# A list of lists with [name param1 param2 ...]
set user_exits [im_user_exit_list]


set user_exit_path "[acs_root_dir]/user_exits"
set user_exit_path [parameter::get -parameter UserExitPath -package_id [im_package_core_id] -default $user_exit_path]

multirow create exits exit_name exists_p executable_p
foreach user_exit_def $user_exits {

    set user_exit [lindex $user_exit_def 0]
    set exit_file "$user_exit_path/$user_exit"

    set exists_p [file exists $exit_file]
    set exit_exists "-"
    if {$exists_p} { set exit_exists "exists" }

    set executable_p [file executable $exit_file]
    set exit_executable "-"
    if {$executable_p} { set exit_executable "exec" }

    multirow append exits $user_exit $exists_p $executable_p
}


# ------------------------------------------------------
# Show the trace
# ------------------------------------------------------

set query "
        select	*,
		to_char(log_date, 'YYYY-MM-DD HH24:MI') as log_date_pretty
        from	acs_logs
	order by
		log_date DESC
	limit 10
"
db_multirow logs log_query $query



ad_return_template



