# /www/intranet/member-add.tcl

ad_page_contract {
    Presents a search form to find a user to add to a group.

    @param group_id group to which to add
    @param role role in which to add
    @param also_add_to_group_id Additional groups to which to add
    @param return_url Return URL

    @author        mbryzek@arsdigita.com
    @creation-date 16 April 2000
    @cvs-id        member-add.tcl,v 3.5.2.6 2000/09/22 01:38:22 kevin Exp
} {
    group_id:naturalnum
    { role "" }
    { return_url "" }
    { also_add_to_group_id:naturalnum "" }
    { select_from_group:naturalnum "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_group_member_p [ad_user_group_member $group_id $user_id]
set user_is_group_admin_p [im_can_user_administer_group $group_id $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p || $user_is_wheel_p]

# Check if the current group is a project (as opposed to a customer)
set project_p [db_string check_if_project "select count(*) from im_projects where project_id=:group_id"]

set translation_enabled [ad_parameter "EnableTranslationModule" "intranet" "0"]

# --------------- Permissions Stuff --------------------------
#
# - System or Intranet admins can give all permissions
# - Manager and member rights can only be given by Managers or SysAdmins
# - Sub-Roles (Translator, ...) can be given by managers and
#   members

if {!$user_is_group_member_p && !$user_admin_p} {
    ad_return_complaint "Insufficient Permissions" "<li>You need to be member of the group to add members."
}

set role_options ""

if {$project_p} {
    set role_options "
<option value=translator_rel>Translator</option>
<option value=editor_rel>Editor</option>
<option value=proofer_rel>Proof Reader</option>
"
}

if {$user_admin_p > 0} {
set role_options "
<option value=admin_rel>Administrator</option>
<option value=membership_rel>Member</option>
$role_options"
}


# Find out the project/customer name and deal with the case that the name
# may be empty.
#
set group_name [db_string group_name_for_one_group_id "select group_name from groups where group_id = :group_id"]

set page_title "Add new member to $group_name"
set context_bar [ad_context_bar "Add member"]

set locate_form "
<form method=POST action=/intranet/user-search>
[export_entire_form]
<input type=hidden name=target value=\"[im_url_stub]/member-add-2\">
<input type=hidden name=passthrough value=\"group_id role return_url also_add_to_group_id notify_asignee\">

<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=middle>Search for User</td>
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
      or Last Name
[im_gif help "Search for a substring in a persons last name, for example \"berg\" to search for all users with a last name containing \"berg\"."]
    </td>
    <td><input type=text name=last_name size=20></td>
  </tr>
  <tr> 
    <td>add as</td>
    <td>
      <select name=role>
      $role_options
      </select>
    </td>
  </tr>
  <tr> 
    <td></td>
    <td>
      <input type=submit value=Search>
      <input type=checkbox name=notify_asignee value=1 checked>Notify<br>
    </td>
  </tr>

</table>
</form>
"

# Get the list of all employees as a shortcut
#
set employee_select [im_employee_select_multiple "user_id_from_search" "" 7 ""]

set select_form "
<form method=POST action=/intranet/member-add-2>
[export_entire_form]
<input type=hidden name=target value=\"[im_url_stub]/member-add-2\">
<input type=hidden name=passthrough value=\"group_id role return_url also_add_to_group_id\">
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td class=rowtitle align=middle>Employee</td>
  </tr>
  <tr> 
    <td>
$employee_select
    </td>
  </tr>
  <tr> 
    <td>add as 
<select name=role>
$role_options
</select>
    </td>
  </tr>
  <tr> 
    <td>
      <input type=submit value=Add>
      <input type=checkbox name=notify_asignee value=1 checked>Notify
    </td>
  </tr>
</table>
</form>
"



# ---------------------------------------------------------------
# Make the freelance list:
# ---------------------------------------------------------------

set freelance_html ""
if {$translation_enabled} {
    set freelance_html [im_freelance_member_select_component $group_id $role_options $return_url]
}

# ---------------------------------------------------------------
# Join Stuff together
# ---------------------------------------------------------------

set page_content "
<table cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
    $locate_form
  </td>
  <td valign=top>
    $select_form
  </td>
</tr>
<tr>
<td colspan=2 valign=top>
    $freelance_html
</td>
</tr>
</table>
"

doc_return  200 text/html [im_return_template]
