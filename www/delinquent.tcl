# /packages/intranet-core/www/delinquent.tcl
#
# Copyright (C) 1998-2004 various parties
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
    Purpose: Update delinquent file /var/log/delinquent when necessary

    @author jsotil@competitiveness.com
    @author frank.bergmann@project-open.com
} {
    user_id
}

set page_title "[_ intranet-core.lt_Remove_Delinquent_Use]"
set context_bar [ad_context_bar "[_ intranet-core.Delinquent_Update]"]

set delinquent_user [cl_rm_user_from_delinquent $user_id]


if { $delinquent_user == 1 } {
    append page_body "<b>[_ intranet-core.lt_You_have_been_removed]</b>"
} elseif { $delinquent_user == 0 } {
    append page_body "<b>[_ intranet-core.lt_You_cannot_be_removed]</b>"
} elseif { $delinquent_user == -1 } {
    append page_body "<b>[_ intranet-core.lt_User_not_found_in_the]</b>"
}

append page_body "<br><hr><h3>[_ intranet-core.lt_REMEMBER_total_of_10_]</h3>"

ad_return_template
