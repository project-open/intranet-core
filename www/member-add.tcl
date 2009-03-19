# /packages/intranet-core/www/member-add.tcl
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
    Presents a search form to find a user to add to a group.

    @param object_id group to which to add
    @param role_id role_id in which to add
    @param also_add_to_object_id Additional groups to which to add
    @param return_url Return URL

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    object_id:naturalnum
    { role_id "1300" }
    { return_url "" }
    { also_add_to_object_id:naturalnum "" }
    { select_from_group:naturalnum "" }
}

set user_id [ad_maybe_redirect_for_registration]
set object_name [db_string object_name_for_one_object_id "select acs_object.name(:object_id) from dual"]
set page_title "[_ intranet-core.lt_Add_new_member_to_obj]"
set context_bar [im_context_bar "[_ intranet-core.Add_member]"]


# expect commands such as: "im_project_permissions" ...
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id view read write admin"
eval $perm_cmd

if {!$write} {
    ad_return_complaint 1 "[_ intranet-core.lt_You_have_no_rights_to_1]"
    return
}

set notify_checked ""
if {[parameter::get_from_package_key -package_key "intranet-core" -parameter "NotifyNewMembersDefault" -default "1"]} {
    set notify_checked "checked"
}



set locate_form "
<form method=POST action=/intranet/user-search>
[export_entire_form]
<input type=hidden name=target value=\"[im_url_stub]/member-add-2\">
<input type=hidden name=passthrough value=\"object_id role_id return_url also_add_to_object_id notify_asignee\">

<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=middle>[_ intranet-core.Search_for_User]</td>
  </tr>
  <tr> 
    <td>
      by Email
[im_gif help "Search for a substring in a persons email, for example \"lion\" to search for all users from Lionbridge."]
    </td>
    <td><input type=text name=email size=20></td>
  </tr>
  <tr> 
    <td>
      [_ intranet-core.or_Last_Name]
[im_gif help "Search for a substring in a persons last name, for example \"berg\" to search for all users with a last name containing \"berg\"."]
    </td>
    <td><input type=text name=last_name size=20></td>
  </tr>
  <tr> 
    <td>[_ intranet-core.add_as]</td>
    <td>
[im_biz_object_roles_select role_id $object_id $role_id]
    </td>
  </tr>
  <tr> 
    <td></td>
    <td>
      <input type=submit value=\"[_ intranet-core.Search]\">
      <input type=checkbox name=notify_asignee value=1 $notify_checked>[_ intranet-core.Notify]<br>
    </td>
  </tr>

</table>
</form>
"

# Get the list of all employees as a shortcut
#
set employee_select [im_employee_select_multiple user_id_from_search "" 12 multiple]


set select_form "
<form method=POST action=/intranet/member-add-2>
[export_entire_form]
<input type=hidden name=target value=\"[im_url_stub]/member-add-2\">
<input type=hidden name=passthrough value=\"object_id role_id return_url also_add_to_object_id\">
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td class=rowtitle align=middle>[_ intranet-core.Employee]</td>
  </tr>
  <tr> 
    <td>
$employee_select
    </td>
  </tr>
  <tr> 
    <td>[_ intranet-core.add_as] 
[im_biz_object_roles_select role_id $object_id $role_id]
    </td>
  </tr>
  <tr> 
    <td>
      <input type=submit value=\"[_ intranet-core.Add]\">
      <input type=checkbox name=notify_asignee value=1 $notify_checked>[_ intranet-core.Notify]
    </td>
  </tr>
</table>
</form>
"

