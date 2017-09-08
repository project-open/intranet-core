# /packages/intranet-core/www/projects/dashboard.tcl
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
    Ticket Dashboard

    @author frank.bergmann@project-open.com
} {
    { plugin_id:integer 0 }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set current_user_id [auth::require_login]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set page_title  [lang::message::lookup "" intranet-core.Users_Dashboard "Users Dashboard"]
set page_focus "im_header_form.keywords"
set current_url [ns_conn url]
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set return_url "/intranet/users/dashboard"




# ---------------------------------------------------------------------
# Users Submenu
# ---------------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
set parent_menu_id [im_menu_id_from_label "user_page"]
set menu_label "users_dashboard"

set sub_navbar_html [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url $return_url \
    -plugin_url $return_url \
    $parent_menu_id \
    $bind_vars \
    "" \
    "pagedesriptionbar" \
    $menu_label \
] 

set left_navbar_html ""
