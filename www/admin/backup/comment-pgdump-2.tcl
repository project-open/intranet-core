ad_page_contract {

} {
    { filenames {}}
    { comment ""}
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

foreach f $filenames {
    db_dml insert_comment "
	insert into acs_logs (log_id, log_level, log_key, message)	
	values (nextval('t_acs_log_id_seq'), 'notice', :f, :comment)
    "
}


ad_returnredirect $return_url
