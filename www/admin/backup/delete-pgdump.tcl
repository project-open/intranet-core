ad_page_contract {

} {
    filename:multiple,optional
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

foreach i $filename {
    set tmp [im_backup_path]/[file tail $i]
    ns_log Debug  "deleting pgdmp file: $tmp"
    file delete $tmp
}

ad_returnredirect $return_url

