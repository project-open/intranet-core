# /packages/intranet-core/www/users/password-update.tcl
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

ad_page_contract {

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
    { return_url "" }
}

set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin

if {!$admin && $user_id != $current_user_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_5]"
    return
}

set page_title "[_ intranet-core.Change_Password]"
set context_bar [im_context_bar [list /intranet/users/ "[_ intranet-core.Users]"] $page_title]

db_1row user_info_by_id "
select
	im_name_from_user_id(:user_id) as name
from
        dual
"

set ad_site_home_link [ad_site_home_link]

set page_body "
<form method=POST action=\"password-update-2\">
[export_form_vars user_id name return_url]
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>[_ intranet-core.Update_Password]</td>
  </tr>
  <tr><td colspan=2>[_ intranet-core.lt_for_name_in_ad_site_h]</td></tr>
  <tr>
    <td>[_ intranet-core.New_Password]</td>
    <td><input type=password name=password_1 size=15></td>
  </tr>
  <tr>
    <td>[_ intranet-core.Confirm]</td>
    <td><input type=password name=password_2 size=15></td>
  </tr>
  <tr>
    <td></td>
    <td><input type=submit value=\"[_ intranet-core.Update]\"></td>
  </tr>
</table>
</form>
"

ad_return_template
