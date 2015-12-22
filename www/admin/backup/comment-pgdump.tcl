ad_page_contract {

} {
    {filename:multiple {}}
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

if {0 eq [llength $filename]} { ad_returnredirect $return_url }

set filenames [list]
foreach f $filename {
    set f_body [file tail $f]

    # Eliminate a tailing ".bz2" extension
    regsub {^(.*)\.bz2$} $f_body {\1} f_body

    lappend filenames $f_body
}
