# /packages/intranet-core/www/users/portrait/upload.tcl
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
    @author philg@mit.edu
    @param user_id user whose portrait we are to manage.
    @cvs-id upload.tcl,v 1.1.2.4 2000/09/22 01:36:31 kevin Exp
} {
    user_id:naturalnum,notnull
    { return_url "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# Also accept "user_id_from_search" instead of user_id (the one to edit...)
if [info exists user_id_from_search] { set user_id $user_id_from_search}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $current_user_id]
set yourself_p [expr $user_id == $current_user_id]
set user_admin_p [|| $user_is_admin_p $user_is_wheel_p]


if {![db_0or1row admin_user_portrait_upload_get_user_info "select 
  first_names, 
  last_name
from users 
where user_id=:user_id"]} {
    ad_return_error "Account Unavailable" "
    We can't find you (user #$user_id) in the users table.<br>
    Probably your account was deleted for some reason."
    return
}

set page_title "Upload a Portrait"
set context_bar [ad_admin_context_bar [list "/admin/users/" "Users"] [list "../one?[export_url_vars user_id]" "$first_names $last_name"] [list "index?[export_url_vars user_id]" "$first_names's Portrait"] $page_title]


set page_body "
<form enctype=multipart/form-data method=POST action=\"upload-2\">
[export_form_vars user_id return_url]

<table cellpadding=1 cellspacing=1 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>Upload Portrait</td>
  </tr>
  <tr>
    <td>Filename: </td>
    <td><input type=file name=upload_file size=30></td>
  </tr>
  <tr>
    <td>Story Behind Photo<br> (optional)</td>
    <td><textarea rows=6 cols=50 wrap=soft name=portrait_comment></textarea></td>
  </tr>
  <tr>
    <td></td>
    <td><input type=submit value=\"Upload\"></td>
  </tr>
</table>
</form>

How would you like the world to see $first_names $last_name?
Upload your favorite file, a scanned JPEG or GIF, from your desktop
computer system (note that you can't refer to an image elsewhere on
the Internet; this image must be on your computer's hard drive).

<hr>
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]
