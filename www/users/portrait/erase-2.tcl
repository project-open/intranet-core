ad_page_contract {
    erase's a user's portrait (NULLs out columns in the database)

    the key here is to null out live_revision, which is 
    used by pages to determine portrait existence

    @cvs-id $Id$
} {
    {return_url "" }
    {user_id ""}
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

db_dml portrait_delete "update cr_items
set live_revision = NULL
where item_id = (
   select object_id_two
   from acs_rels
   where object_id_one = :user_id
   and rel_type = 'user_portrait_rel')"

if [empty_string_p $return_url] {
    set return_url "/pvt/home"
}

ad_returnredirect $return_url
