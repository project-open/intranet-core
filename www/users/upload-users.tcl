# /intranet/intranet-core/www/users/upload-users.tcl
#
# Copyright (C) 2013 ]project-open[
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
    Serve the user a form to upload a new file

    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com

} {}

set user_id [ad_maybe_redirect_for_registration]
set page_title  [lang::message::lookup "" intranet-core.UploadUsers "Upload Users"]
# set context_bar [im_context_bar [list "/intranet/users/" "Users"] $page_title]
set context_bar ""

# Check if user is ADMIN or HR Manager
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p && ![im_profile::member_p -profile_id [im_hr_group_id] -user_id $user_id]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set skill_role_id_exists_p [db_string get_data "select count(*) from information_schema.columns where table_name = 'im_employees' and column_name = 'skill_role_id';" -default 0]

set page_body "
<form enctype=multipart/form-data method=POST action=upload-users-2.tcl>
[export_form_vars return_url]
                    <table border=0 cellpadding=3 cellspacing=3>
                      <tr> 
			<td>[lang::message::lookup "" intranet-core.TitleUploadUserDataExplain "Please choose CSV file:"]</td>
                        <td align=left> 
                          <input type=file name=upload_file size=30>
                          [im_gif help "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."]
                        </td>
                      </tr>
		      <tr><td colspan=2>&nbsp;</td></tr>
                      <tr>
			<td valign='top'>[lang::message::lookup "" intranet-core.NumberFormatting "Number Formatting"]:</td>
                        <td valign='top'>
			<input type='radio' name='locale_numeric' value='en_US' checked> 
				[lang::message::lookup "" intranet-core.DecimalSeparatorPoint "Decimal Separator is Point (e.g. 1,500.23)"]<br>
			<input type='radio' name='locale_numeric' value='de_DE'>
				[lang::message::lookup "" intranet-core.DecimalSeparatorComma "Decimal Separator is Comma (e.g. 1.500,23)"] 
                        </td>
                      </tr>
"
if { $skill_role_id_exists_p  } {
	append page_body "
		      <tr><td colspan='2'>&nbsp;</td></tr>
		      <tr>
		        <td valign='top'> [lang::message::lookup "" intranet-core.AdvancedSettings "Advanced Settings"]:</td>
                        <td valign='top'>
			<input type='checkbox' name='update_hourly_rates_skill_profile'>
				[lang::message::lookup "" intranet-core.UpdateHourlyRatesSkillProfile "Import of Hourly Rates for Skill Profiles - Update users Hourly Rate"] 
				[im_gif help "Please leave unchecked if in doubt. Additional information about Skill Profiles is available at www.project-open.org"]
                        </td>
                      </tr>
	"
}
append page_body "
			<tr><td colspan='3'>&nbsp;</td></tr>
                      <tr> 
                        <td></td>
                        <td> 
                          <input type=submit value=Submit and Upload>
                        </td>
                      </tr>
                    </table>
		</form>
"
