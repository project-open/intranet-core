ad_page_contract {

} {
    { filename:multiple {}}
    return_url
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

foreach f $filename {
    set f_body [file tail $f]
    db_dml del_comment "delete from acs_logs where log_key = :f_body"
}

ad_returnredirect $return_url
