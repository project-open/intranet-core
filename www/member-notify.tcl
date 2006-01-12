# /packages/intranet-core/www/member-notify.tcl
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
    Sends a notification message to a member
    @author frank.bergmann@project-open.com
} {
    user_id_from_search:integer
    subject
    message
    { send_me_a_copy "" }
    return_url
}

set user_id [ad_maybe_redirect_for_registration]

# Send out an email alert
im_send_alert $user_id_from_search "hourly" $subject $message


# Send a copy to myself
if {"" != $send_me_a_copy} {
    im_send_alert $user_id "hourly" $subject $message
}

ad_returnredirect $return_url
