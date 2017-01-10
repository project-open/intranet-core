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
    Project Dashboard
    @author frank.bergmann@project-open.com
} {
    { plugin_id:integer 0 }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set current_user_id [auth::require_login]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set page_title  [lang::message::lookup "" intranet-core.Projects_Dashboard "Projects Dashboard"]
set page_focus "im_header_form.keywords"
set current_url [ns_conn url]
set today [lindex [split [ns_localsqltimestamp] " "] 0]

set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = 'projects_dashboard'
" -default 'f']

if {"t" ne $read_p } {
    ad_return_complaint 1 "[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# ---------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------

set menu_select_label "projects_dashboard"
set next_page_url ""
set previous_page_url ""
set dashboard_navbar_html [im_project_navbar -navbar_menu_label "projects" none "/intranet/projects/index" $next_page_url $previous_page_url [list start_idx order_by how_many letter ticket_status_id] $menu_select_label]
set left_navbar_html ""

