# /packages/intranet-core/www/admin/cleanup-demo/cleanup-users.tcl
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
    Install packages - dependency check
} {
    user_id:multiple
    return_url
}


# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}


set page_title [_ intranet-core.Nuking_Users]

# ------------------------------------------------------------
# Return the page header.
# This technique allows us to write out HTML output while
# the processes are runnin. Otherwise, the user would
# not see any intermediate results, but only a screen
# after possibly many minutes of waiting...
#

ad_return_top_of_page "[im_header]\n[im_navbar]"

ns_write "<h1>$page_title</h1>\n"
ns_write "<p>
	In this page, nuking some specific users may fail 
	(particularly 'System Administrator' and 'Ben Bigboss'),<br>
	because these users are the owners of certain system 
	objects that are required and are difficult to delete.<br>
	To work around this situation, please 'recycle' the users 
	by renaming them to some of your managers or <br>
	'mark these users as deleted'.<br>&nbsp;<br>
</p>\n"
ns_write "<ul>\n"


foreach id $user_id {

  ns_write "<li>Nuking user \#$id ...<br>\n"
  set error [im_user_nuke $id]
  if {"" == $error} {
      ns_write "... successful\n"
  } else {
      ns_write "<font color=red>$error</font>\n"
  }

}


ns_write "</ul>\n"

ns_write "<p>You can now return to the <a href=$return_url>previous page</a>.</p>"

ns_write [im_footer]


