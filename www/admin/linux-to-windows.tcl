# /packages/intranet-core/www/admin/linux-to-windows.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Convert some parameters values from Windows to Linux
} {
    { install_dir "" }
    { return_url "/intranet/admin/" }
}


# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Linux - to - Windows"

if {"" == $install_dir} {
    # something like "C:/project-open"
    set install_dir [acs_root_dir]

    # Remove "/servers ..."
    if {[regexp {^(.*)\/servers.*} $install_dir match base_dir]} { set install_dir $base_dir }

}