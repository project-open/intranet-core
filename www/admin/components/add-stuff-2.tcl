# /packages/intranet-core/www/admin/components/add-stuff-2.tcl
#
# Copyright (C) 2006 ]project-open[
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

    Implements component actions such as open/close
    and movements in directions up, down, left and right.

    @param plugin_id            ID of plugin to change
    @author frank.bergmann@project-open.com
} {
    plugin_id:array
    return_url
}

# -----------------------------------------------------------
# Permissions - Only Admins can change the default order
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]


# -----------------------------------------------------------
# Add components back to page
# -----------------------------------------------------------

foreach pid [array names plugin_id] {

    db_dml activate_plugin "
	update	im_component_plugin_user_map
	set	location = 'right'
	where	plugin_id = :pid
		and user_id = :user_id
    "
}


ad_returnredirect "$return_url"
