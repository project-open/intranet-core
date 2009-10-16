# /packages/intranet-core/www/index.tcl
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
    List all projects with dimensional sliders.

    @param order_by project display order 
    @param include_subprojects_p whether to include sub projects
    @param mine_p show my projects or all projects
    @param status_id criteria for project status
    @param type_id criteria for project_type_id
    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    { order_by "Project #" }
    { include_subprojects_p "f" }
    { mine_p "t" }
    { status_id "" } 
    { type_id:integer "0" } 
    { letter "scroll" }
    { start_idx:integer 0 }
    { how_many "" }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set view_types [list "t" "Mine" "f" "All"]
set subproject_types [list "t" "Yes" "f" "No"]
set page_title "Home"
# set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set current_url [ns_conn url]
set return_url "/intranet/"
set header_stuff ""

set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]



# ----------------------------------------------------------------
# Check update status
# ----------------------------------------------------------------

set upgrade_message [im_check_for_update_scripts]


# ----------------------------------------------------------------
# Administration
# ----------------------------------------------------------------

set admin_html ""
append admin_html "<li> <a href=/intranet/users/view?user_id=$current_user_id>[_ intranet-core.About_You]</A>\n"
set administration_component [im_table_with_title "[_ intranet-core.Administration]" $admin_html]

# Should we show the left navbar?
# If not, then we're going to skip the menu entirely
# because we've got nothing else to show at the moment.
set show_left_functional_menu_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "ShowLeftFunctionalMenupP" -default 0]


