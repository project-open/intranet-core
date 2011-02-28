# /packages/intranet-core/www/admin/toggle.tcl
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
    Enable / Disable "Menus" 

    @author Malte Sussdorff (sussdorff@sussdorff.de)
} {
    menu_id:integer
    action
    { return_url "index"}
}

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$current_user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}


switch $action {
    enable {
	db_dml enable "update im_menus set enabled_p = 't' where menu_id = :menu_id"
    }
    disable {
	db_dml enable "update im_menus set enabled_p = 'f' where menu_id = :menu_id"
    }
    default {
	ad_return_complaint 1 "Unknown action: '$action'"
	return
    }
}

ad_returnredirect $return_url
