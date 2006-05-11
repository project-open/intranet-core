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

# ******************************************************
# Create the list of Widgets
# ******************************************************

set user_exits [list \
	user_create \
	user_modify \
	user_delete \
	project_create \
	project_modify \
	project_delete \
	task_create \
	task_modify \
	task_delete \
]


set user_exit_path "[acs_root_dir]/user_exits"
set user_exit_path [parameter::get -parameter UserExitPath -package_id [im_package_core_id] -default $user_exit_path]
# set exit_files [fileutil::find $user_exit_path]

multirow create exits exit_name exists_p executable_p
foreach user_exit $user_exits {

    set exit_file "$user_exit_path/$user_exit"
    set exists_p [file exists $exit_file]
    set executable_p [file executable $exit_file]

    multirow append exits $user_exit $exists_p $executable_p
}

ad_return_template




#    set exit_paths [split $exit_file "/"]
#    set exit_paths_len [llength $exit_paths]
#    set exit [lindex $exit_paths [expr $exit_paths_len-1]]

#    if {[regexp {\~} $exit]} { continue }
#    if {[regexp {.*\.pm$} $exit]} { continue }



