# /packages/intranet-core/www/login_redirect.tcl
#
# Copyright (C) 2005 ]project-open[
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
    Purpose: Confirms adding of person to group

    @param user_id_from_search user_id to add
    @param object_id group to which to add
    @param role_id role in which to add
    @param return_url Return URL
    @param also_add_to_group_id Additional groups to which to add

    @param user_id	Login as this user
    @param url		What page to go to
    @param x		A hashed combination of user_id, passwd & salt

    @author frank.bergmann@project-open.com
} {
    user_id:integer
    { url "/intranet/" }
    { x "" }
}


set valid_login [im_valid_auto_login_p -user_id $user_id -auto_login $x]

if {$valid_login} {
    ad_user_login -forever=0 $user_id
    ad_returnredirect $url
} else {
    ad_return_complaint 1 "

 " 
}
