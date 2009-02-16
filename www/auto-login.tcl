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

    Example use:
    http://projop.dnsalias.com/intranet/auto_login?user_id=1234&url=/intranet-forum/&auto_login=E4E412EE1ACA294D4B9AC51B108360EEF7B307C1

    @@param user_id	Login as this user
    @@param url		What page to go to
    @@param token	A hashed combination of user_id, passwd & salt

    @@author frank.bergmann@@project-open.com
} {
    user_id:integer
    { url "/intranet/" }
    { auto_login "" }
}

# Check if the "require_manual_login" privilege exists to protect high-profile users
set priv_exists_p [db_string priv_exists "
        select count(*)
        from acs_privileges
        where privilege = 'require_manual_login'
"]
set user_requires_manual_login_p [im_permission $user_id "require_manual_login"]


if {$priv_exists_p && !$user_requires_manual_login_p} {

    # Log the dude in if the token was OK.
    set valid_login [im_valid_auto_login_p -user_id $user_id -auto_login $auto_login]
    if {$valid_login} {
        ad_user_login -forever=0 $user_id
        ad_returnredirect $url
    } else {
        ad_return_complaint 1 "<b>Wrong Security Token</b>:<br>
        Your security token is not valid. Please contact the system owner.<br>"
    }

} else {

    # Just forward to the desired page.
    # ]po[ will take care of redirecting to login if necessary
    ad_returnredirect $url

}
