ad_page_contract {
    @cvs-id user-add.tcl,v 3.5.2.3.2.3 2000/09/22 01:36:25 kevin Exp
} {
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $current_user_id]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------
set page_title "Add User"
set page_focus "im_header_form.keywords"

if {$user_is_employee_p} {
    set context_bar [ad_context_bar [list /intranet/users/ "Users"] $page_title]
} else {
    set context_bar [ad_context_bar $page_title]
}

# generate unique key here so we can handle the "user hit s" case
set user_id [im_new_object_id]

# Get the list of profiles that the current_user can create
set option_list [im_profiles_for_new_user $current_user_id]

if {![llength $option_list]} {
    set err_msg "You have insufficient permissions to create a new user."
    ad_return_error "Insufficient Permissions" $err_msg
}

set profile_list ""
foreach option $option_list {
    set group_id [lindex $option 0]
    set group_name [lindex $option 1]
    append profile_list "<option value=$group_id>$group_name</option>\n"
}

# ---------------------------------------------------------------
# Basic User Information
# ---------------------------------------------------------------

set basic_html "
<form method=POST action=new-2>
[export_form_vars user_id]
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=middle>$page_title</td>
  </tr>
  <tr> 
    <td>Email</td>
    <td><input type=text name=email size=40 maxlength=40></td>
  </tr>
  <tr> 
    <td>First and Last Name</td>
    <td>
      <input type=text name=first_names size=19 maxlength=40> 
      <input type=text name=last_name size=19 maxlength=40>
    </td>
  </tr>
  <tr> 
    <td>Password</td>
    <td><input type=password name=password size=10></td>
  </tr>
  <tr> 
    <td>Password Confirm</td>
    <td><input type=password name=password_confirmation size=10></td>
  </tr>
  <tr> 
    <td colspan=2>
    </td>
  </tr>
  <tr> 
    <td>Profile</td>
    <td>

<select name=profile size=6 multiple>
$profile_list
</select>

    </td>
  </tr>
  <tr> 
    <td></td>
    <td>
      <input type=submit value='Add User'
    </td>
  </tr>
</table>
<em>(If you don't provide a password, a random password will be generated.)</em>

</form>
<p>"

# ---------------------------------------------------------------
# Join all the parts together
# ---------------------------------------------------------------


set page_body "
$basic_html
"


doc_return  200 text/html [im_return_template]

