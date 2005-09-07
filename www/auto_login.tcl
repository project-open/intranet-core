# /packages/intranet-core/www/auto_login.tcl
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
    Purpose: login & redirect a user, based on a "auto_login"
    field that contains the information about the user's password
    in a sha1 HASH.

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
