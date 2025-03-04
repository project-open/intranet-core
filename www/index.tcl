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
    Home Page

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    { plugin_id:integer 0 }
    { view_name "standard"}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [auth::require_login]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set page_title  [lang::message::lookup "" intranet-core.PageTitleHome "Home"]
set page_focus "im_header_form.keywords"
set current_url [ns_conn url]
set return_url "/intranet/"
set header_stuff ""

set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]


# ----------------------------------------------------------------
# Timesheet portlet should not be deletable by any user
# ----------------------------------------------------------------

# Delete the custom position of the timesheet portlet if redirect is enabled
set redirect_p [parameter::get -package_id [im_package_timesheet2_id] -parameter "TimesheetRedirectHomeIfEmptyHoursP" -default 0]
if {$redirect_p && !$user_admin_p} {
    db_dml del_timesheet_portlet_cust "
	delete from im_component_plugin_user_map 
	where	plugin_id in (
		select	plugin_id 
		from	im_component_plugins 
		where	plugin_name = 'Home Timesheet Component'
	) and
	user_id = :current_user_id
    "
}

# ----------------------------------------------------------------
# Check update status
# ----------------------------------------------------------------

# Check for upgrade scripts that have not yet been executed
set upgrade_message [im_check_for_update_scripts]

# Shows the Admin Guide
set admin_guide_html ""
if {[llength [info commands im_sysconfig_admin_guide]] > 0} {
    set title [lang::message::lookup "" intranet-core.Interactive_Administration_Guide "Interactive Administration Guide"]
    set admin_guide_html [im_table_with_title $title [im_sysconfig_admin_guide]]
}

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


# ---------------------------------------------------------------------
# Submenu
# ---------------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
set parent_menu_id [im_menu_id_from_label "home"]
set menu_label "home_summary"

set sub_navbar [im_sub_navbar \
		    -components \
		    -current_plugin_id $plugin_id \
		    -base_url "/intranet/index" \
		    -plugin_url "/intranet/index" \
		    $parent_menu_id \
		    $bind_vars "" "pagedesriptionbar" $menu_label] 

set show_context_help_p 0

# ---------------------------------------------------------------------
# Admin Box
# ---------------------------------------------------------------------

set admin_html_content ""

set left_navbar_html ""
if {"" != $admin_html_content} {
    append left_navbar_html "
      	<div class='filter-block'>
        <div class='filter-title'>
		[lang::message::lookup "" intranet-core.Admin_Home "Admin Home"]
        </div>
	<ul>$admin_html_content</ul>
      	</div>
	<hr/>
    "
}
