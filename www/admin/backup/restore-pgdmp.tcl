ad_page_contract {

} {
    filename
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

set server_name [ns_info server]
set filename [im_backup_path]/[file tail $filename]

set err ""

ns_log Debug "restoring pgdmp file: $filename"
if {[catch { exec pg_restore --dbname $server_name --no-owner --clean $filename } err]} {
	
    ad_return_top_of_page "[im_header]\n[im_navbar]"
    
    ns_write "<h2>Error during import:</h2><pre>$err</pre>"
    ns_write "<a href=\"$return_url\">back to list</a>"
    ns_write [im_footer]
}

if {$err==""} {
    ad_returnredirect
}


