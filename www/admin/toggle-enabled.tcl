# /packages/intranet-core/www/admin/toggle-enabled.tcl
#
# Copyright (C) 2012 ]project-open[
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
    Enable/Disable portlets or menus.
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { plugin_id:integer "" }
    { category_id:integer "" }
    return_url
}

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$current_user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# Portlet Components
if {"" != $plugin_id} {
    set old_enabled_p [db_string old_en "select enabled_p from im_component_plugins where plugin_id = :plugin_id" -default "f"]
    set new_enabled_p "t"
    if {"t" == $old_enabled_p} { set new_enabled_p "f" }
    db_dml update_en "update im_component_plugins set enabled_p = :new_enabled_p where plugin_id = :plugin_id"
}


# Categories
if {"" != $category_id} {
    set old_enabled_p [db_string old_en "select enabled_p from im_categories where category_id = :category_id" -default "f"]
    set new_enabled_p "t"
    if {"t" == $old_enabled_p} { set new_enabled_p "f" }
    db_dml update_en "update im_categories set enabled_p = :new_enabled_p where category_id = :category_id"
}



# Flush the global permissions cache so that the
# new changes become active.
im_permission_flush


ad_returnredirect $return_url
