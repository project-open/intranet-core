# /packages/intranet-core/www/admin/profiles/index.tcl
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
    Permissions for the subsite itself.
    
    @author Lars Pind (lars@collaboraid.biz)
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { filter_str "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set page_title "Profiles"
set context [list "Permissions"]
set subsite_id [ad_conn subsite_id]
set context_bar [im_context_bar $page_title]
set url_stub [im_url_with_query]

set left_navbar_html "
<table width='100%'>
<tr>
  <td width='50%'>
        <div class='filter-block'>
                <div class='filter-title'>
                     [lang::message::lookup "" intranet-core.Filter "Filter"]
                </div>
        <form action=index method=GET>
        <table>
        <tr>
        <td>Text:</td>
        <td><input size='10' name='filter_str' id='filter_str' value='$filter_str'></td>
        </tr>
        <tr><td></td><td><input type=submit></td></tr>
        </form>
        </table>
        </div>
      <hr/>

        <table>
        <tr>
          <td><div class='filter-title'>Administration Options</td> </div>
        </tr>
        <tr>
        <td>
          <ul>
        <li><a href='/intranet/admin/profiles/new?group_type_exact_p=t&group_type=im_profile'>Add a new profile</a>
        <li><a href='/intranet/admin/profiles/delete'>Delete a profile</a>
        </ul>
  </td>
</tr>
</table>

</td>
</tr>
</table>

"



# The list of Core privileges
set privs [im_core_privs $filter_str]
# set privs { add_users }

# Flush the permission cache to make changes active.
# Putting this command here may cause too many flush
# actions to be performed (because it is activated
# when only viewing permission), but otherwise we would
# have to modify /permissions/perm-modify...
im_permission_flush