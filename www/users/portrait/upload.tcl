ad_page_contract {
    Uploading user portraits

    @cvs-id $Id$
} {
    {user_id ""}
    {return_url ""}
} -properties {
    first_names:onevalue
    last_name:onevalue
    context:onevalue
    export_vars:onevalue
    
}

set current_user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]

if [empty_string_p $user_id] {
    set user_id $current_user_id
}

# Check the permissions that the current_user has on user_id
im_user_permissions $current_user_id $user_id view read write admin

if {!$write} { 
    ad_return_complaint 1 "<li>You have insufficient permissions to upload a portrait for this user." 
    return
}


if ![db_0or1row name "
	select	first_names, last_name
	from	persons 
	where	person_id=:user_id
"] {
    ad_return_error "Account Unavailable" "
    We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    ad_script_abort
}

if {$admin} {
    set context [list [list "./?user_id=$user_id" "User's Portrait"] "Upload Portrait"]
} else {
    set context [list [list "./?return_url=$return_url" "Your Portrait"] "Upload Portrait"]
}

set export_vars [export_form_vars user_id return_url]


# --------------------------------
# New code - FS upload

set thumbnail_size "360x360"

set bread_crum_path ""
set folder_type "user"
set object_id $user_id
set fs_filename "asdf"



ad_return_template
