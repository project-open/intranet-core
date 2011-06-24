# /packages/intranet-core/www/admin/cleanup-demo/cleanup-offices.tcl
#
# Copyright (C) 2004 Office/Open
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
    Nuke Offices
} {
    office_id:multiple
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


set page_title [lang::message::lookup {} intranet-core.Nuke_Demo_Offices "Nuke Demo Offices"]

# ------------------------------------------------------------
# Return the page header.
# This technique allows us to write out HTML output while
# the processes are runnin. Otherwise, the office would
# not see any intermediate results, but only a screen
# after possibly many minutes of waiting...
#

ad_return_top_of_page "[im_header]\n[im_navbar]"

ns_write "<h1>$page_title</h1>\n"
ns_write "<ul>\n"


foreach id $office_id {

  ns_write "<li>Nuking office \#$id ...<br>\n"
  set error ""
  if {[catch {
      set error [im_office_nuke $id]
  } err_msg]} {
      set error $err_msg
  }

  if {"" == $error} {
      ns_write "... successful\n"
  } else {
      ns_write "<font color=red>$error</font>\n"
  }

}


ns_write "</ul>\n"
ns_write "<p>You can now return to the <a href=$return_url>previous page</a>.</p>"
ns_write [im_footer]


