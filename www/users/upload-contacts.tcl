# /intranet/companies/upload-contacts.tcl
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
    Serve the user a form to upload a new file or URL

    @author frank.bergmann@project-open.com
} {
    return_url:notnull
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Contacts CSV"
set context_bar [im_context_bar [list "/intranet/users/" "Users"] $page_title]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

array set main_site [site_node::get -url /]
set main_site_id $main_site(package_id)
set reg_req_email_verify [parameter::get -package_id $main_site_id -parameter RegistrationRequiresEmailVerificationP -default 0]


set managable_profiles [im_profile::profile_options_managable_for_user $user_id]
set profile_select "<select name=profile_id>\n"
append profile_select "<option value=\"\">[_ intranet-core.Please_Select]</option>\n"
foreach profile $managable_profiles {
    set profile_name [lindex $profile 0]
    set profile_id [lindex $profile 1]

    append profile_select "\t<option value=\"$profile_id\">$profile_name</option>\n"
}
append profile_select "</select>\n"


set page_body "
<form enctype=multipart/form-data method=POST action=upload-contacts-2.tcl>
[export_form_vars return_url]
                    <table border=0>
                      <tr> 
                        <td align=right>Filename: </td>
                        <td> 
                          <input type=file name=upload_file size=30>
                          [im_gif help "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."]
                        </td>
                      </tr>
                      <tr> 
                        <td align=right>Profile: </td>
                        <td> 
                          $profile_select
                          [im_gif help "Determine the profile for new users"]
                        </td>
                      </tr>
                      <tr> 
                        <td></td>
                        <td> 
                          <input type=submit value=Submit and Upload>
                        </td>
                      </tr>
                    </table>
</form>
"

