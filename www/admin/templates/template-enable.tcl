ad_page_contract {

} {
    category_id:integer,multiple
    return_url
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

foreach cid $category_id {
    db_dml enable_template "update im_categories set enabled_p = 't' where category_id = :cid"
}

# Remove all permission related entries in the system cache
im_permission_flush

ad_returnredirect $return_url

