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

set page_title "<#_ Remove Delinquent User from List#>"
set context_bar [ad_context_bar "<#_ Delinquent Update#>"]

set delinquent_user [cl_rm_user_from_delinquent $user_id]


if { $delinquent_user == 1 } {
    append page_body "<b><#_ You have been removed from the delinquent list#></b>"
} elseif { $delinquent_user == 0 } {
    append page_body "<b><#_ You cannot be removed from the delinquent list... Log your hours !!!#></b>"
} elseif { $delinquent_user == -1 } {
    append page_body "<b><#_ User not found in the delinquent list. May be you have already been removed ?!!#></b>"
}

append page_body "<br><hr><h3><#_ REMEMBER: total of 10 units per day! (all the days)#></h3>"

ad_return_template
