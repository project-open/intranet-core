# /packages/intranet-core/tcl/intranet-notification-procs.tcl
#
# Copyright (c) 2007 ]project-open[
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

ad_library {
    Library related to Notifications

    @author frank.bergmann@project-open.com
}

ad_proc -public im_notification_user_component {
    {-user_id 0}
} {
    Returns a formatted HTML showing the status of notifications
    for the current user.
} {
    if {0 == $user_id} { set user_id [ad_get_user_id] }
    set return_url [im_url_with_query]

    set params [list \
		    [list user_id $user_id] \
		    [list return_url [im_url_with_query]] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-core/www/notifications/user-notifications"]
    return $result
}

