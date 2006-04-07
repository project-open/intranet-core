ad_page_contract {
    Erases a portrait

    @cvs-id $Id$
} {
    {return_url "" }
    {user_id ""}
} -properties {
    context:onevalue
    export_vars:onevalue
}

set current_user_id [ad_maybe_redirect_for_registration]

if [empty_string_p $user_id] {
    set user_id $current_user_id
}

# Check the permissions that the current_user has on user_id
im_user_permissions $current_user_id $user_id view read write admin

if {!$write} {
    ad_return_complaint 1 "<li>You have insufficient permissions to erase a portrait for this user."
    return
}


if {$admin} {
    set context [list [list "./?user_id=$user_id" "User's Portrait"] "Erase"]
} else {
    set context [list [list "./" "Your Portrait"] "Erase"]
}

set export_vars [export_form_vars user_id return_url]

