# /packages/intranet-core/www/group-member-option-2.tcl
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
    Redirects the user to the appropriate place based on whether they
    do or do not want to join the indicated group

    @param group_id group id we're joining
    @param continue_url where to go when we're done
    @param cancel_url where to go if we've answered no on the previous page
    @param role role in which to add the user
    @param operation YES or NO (case insensitive...) If yes, we add the user to the group. Default is No

    @author mbryzek@arsdigita.com
} {
    group_id:integer,notnull
    continue_url:notnull
    cancel_url:notnull
    { operation "NO" }
    { role "administrator" }
}


set user_id [ad_maybe_redirect_for_registration]

set operation [string toupper [string trim $operation]]

if { [string compare $operation "NO"] == 0 } {
    # Cancelled...
    ad_returnredirect $cancel_url
    return
}


# Let's make sure the group is an intranet group :)
set group_type [ad_parameter IntranetGroupType intranet intranet]

set intranet_group_type_p [db_string group_type_check \
	"select count(*) from user_groups where group_id = :group_id and group_type = :group_type"]

if { !$intranet_group_type_p } {
    ad_return_error "Invalid group type" "The group you selected is not of type [ad_parameter IntranetGroupType intranet intranet]. You cannot add yourself to this group through this interface"
    return
}

ad_user_group_user_add $user_id $role $group_id

db_release_unused_handles

ad_returnredirect $continue_url
