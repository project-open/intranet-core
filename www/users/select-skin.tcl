# /packages/intranet-core/www/users/profile-update.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    @param user_id

    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com
} {
    user_id
    skin_id
    return_url 
}

#--------------------------------------------------------------------
# Security and Defaults
#--------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {$current_user_id != $user_id && !$current_user_admin_p} {
    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "<li>[_ intranet-core.lt_You_have_insufficient_7]"
    return
}

#--------------------------------------------------------------------
# Update the user skin
#--------------------------------------------------------------------

if {0 != $skin_id } { db_dml skinupdate "UPDATE users SET skin_id = :skin_id WHERE user_id = :user_id" }

# Clear cache 
ns_write [ns_cache flush util_memoize "im_user_skin_helper $user_id" ]
ns_write [ns_cache flush util_memoize [list db_string skin_id "select skin_id from users where user_id = $user_id"]]

# above commands would not lead to page re-fresh. Only IE (?)
util_memoize_flush_regexp "im.*"

db_release_unused_handles
ad_returnredirect $return_url


