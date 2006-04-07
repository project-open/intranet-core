ad_page_contract {
    writes portrait comment to database

    @author mbryzek@arsdigita.com
    @creation-date 22 Jun 2000
    @cvs-id $Id$
} {
    { description "" }
    { user_id "" }
    { return_url "" }
}

set current_user_id [ad_maybe_redirect_for_registration]

if [empty_string_p $user_id] {
    set user_id $current_user_id
}

# Check the permissions that the current_user has on user_id
im_user_permissions $current_user_id $user_id view read write admin

if {!$write} {
    ad_return_complaint 1 "<li>You have insufficient permissions to modify comments of this user."
    return
}

if { [string length $description] > 4000 } {
    ad_return_complaint 1 "Your portrait comment can only be 4000 characters long."
    return
}

db_dml unused "
update cr_revisions
set description=:description
where revision_id = (select live_revision
  from acs_rels a, cr_items c
  where a.object_id_two = c.item_id
  and a.object_id_one = :user_id
  and a.rel_type = 'user_portrait_rel')"

if { ![empty_string_p $return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect [ad_pvt_home]
}
