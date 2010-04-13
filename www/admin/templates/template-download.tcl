ad_page_contract {

} {
    { category_id 0 }
    { return_url "" }
    path_to_file
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


 if {[catch {
     ns_returnfile 200 "application" $path_to_file
 } err_msg]} {
    ad_return_complaint 1 "
	<b>Error receiving template, please ask your System Adminitrator check category 'Intranet Cost Template'</b>:<br>
    "
}

