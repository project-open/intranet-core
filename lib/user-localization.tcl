ad_page_contract {
    user-skin-info.tcl
    @author iuri sampaio(iuri.sampaio@gmail.com)
    @date 2010-10-29
} 

if {$user_id} {set user_id_from_search $user_id}

set current_user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]

# Check the permissions 
im_user_permissions $current_user_id $user_id_from_search view read write admin

# ToDo: Cleanup component to use $write instead of $edit_user
set edit_user $write

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
    return
}

# ---------------------------------------------------------------
# Localization Information
# ---------------------------------------------------------------

set site_wide_locale [lang::user::locale -user_id $user_id]
set use_timezone_p [expr [lang::system::timezone_support_p] && [ad_conn user_id]]

if {"" == $site_wide_locale} { set site_wide_locale "en_US" }


if { $use_timezone_p } {
    set timezone [lang::user::timezone]
}


