# /packages/intranet-core/users/contact-edit.tcl
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
    @param user_id
    
    @author unknown@arsdigita.com
    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin

set return_url [im_url_with_query]

if [info exists user_id_from_search] {
    set user_id $user_id_from_search
}

if {![info exists user_id]} {
    ad_return_complaint "Bad User" "<li>You must specify a valid user_id."
}

if {!$write} {
    ad_return_complaint "Insufficient Privileges" "<li>You have insufficient privileges to modify this user."
}

db_0or1row user_full_name "
select 
	first_names, 
	last_name 
from 
	persons 
where 
	person_id = :user_id
"

set page_title "Contact for $first_names"
if {[im_permission $current_user_id view_users]} {
    set context_bar [ad_context_bar [list /intranet/users/ "Users"] $page_title]
} else {
    set context_bar [ad_context_bar $page_title]
}

# use [info exists ] here?
if { [empty_string_p $first_names] && [empty_string_p $last_name] } {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was nuke?"
    return
}

# ---------------------------------------------------------------
# Get contact information
# ---------------------------------------------------------------

set users_contact_exists [db_string select_users_contact_exists "select count(*) from users_contact where user_id=:user_id"]

if {0 == $users_contact_exists} {
	db_dml insert_users_contact "insert into users_contact (user_id) values (:user_id)"
}

set ha_state ""
set ha_country_code ""

db_0or1row user_contact_info {
    select home_phone, work_phone, cell_phone, pager, fax, aim_screen_name,
           icq_number, ha_line1, ha_line2, ha_city, ha_state, ha_country_code,
           ha_postal_code, wa_line1, wa_line2, wa_city, wa_state, wa_postal_code, wa_country_code
      from users_contact where user_id = :user_id
}

if { [empty_string_p $ha_state] && [empty_string_p $ha_country_code] } {
    set ha_state ""
    set ha_country_code ""
    set wa_state ""
    set wa_country_code ""
}

# ---------------------------------------------------------------
# Format the table
# ---------------------------------------------------------------

set contact_html "
<table cellpadding=0 cellspacing=2 border=0>
<tr><td colspan=2 class=rowtitle align=center>Contact Information</td></tr>
<tr><td>Home phone</td>	<td><input type=text name=home_phone value=\"$home_phone\" ></td></tr>
<tr><td>Work phone</td>	<td><input type=text name=work_phone value=\"$work_phone\" ></td></tr>
<tr><td>Cell phone</td>	<td><input type=text name=cell_phone value=\"$cell_phone\" ></td></tr>
<tr><td>Pager</td>	<td><input type=text name=pager value=\"$pager\" ></td></tr>
<tr><td>Fax</td>	<td><input type=text name=fax value=\"$fax\" ></td></tr>
<tr><td>Aim Screen Name</td><td><input type=text name=aim_screen_name value=\"$aim_screen_name\" ></td></tr>
<tr><td>ICQ Number</td>	<td><input type=text name=icq_number value=\"$icq_number\" ></td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
</table>"

set home_html "
<table cellpadding=0 cellspacing=2 border=0>
<tr><td colspan=2 class=rowtitle align=center>Home Address</td></tr>
<tr><td valign=top>Home address</td><td>
			<input type=text name=ha_line1 value=\"$ha_line1\" >
			<input type=text name=ha_line2 value=\"$ha_line2\" ></td></tr>
<tr><td>Home City</td>	<td><input type=text name=ha_city value=\"$ha_city\" ></td></tr>
<tr><td>Home Country</td><td>[im_country_widget $ha_country_code ha_country_code]</td></tr>
<tr><td>Home Postal Code</td><td><input type=text name=ha_postal_code value=\"$ha_postal_code\" ></td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
</table>"

set work_html "
<table cellpadding=0 cellspacing=2 border=0>
<tr><td colspan=2 class=rowtitle align=center>Work Address</td></tr>
<tr><td valign=top>Work address</td><td>
			<input type=text name=wa_line1 value=\"$wa_line1\" >
			<input type=text name=wa_line2 value=\"$wa_line2\" ></td></tr>
<tr><td>Work City</td>	<td><input type=text name=wa_city value=\"$ha_city\" ></td></tr>
<tr><td>Work Postal Code</td><td><input type=text name=wa_postal_code value=\"$wa_postal_code\" ></td></tr>
<tr><td>Work Country</td><td>[im_country_widget $wa_country_code wa_country_code]</td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
</table>"


# <tr><td>Work State</td>	<td>[im_state_widget $wa_state wa_state]</td></tr>
# <tr><td>Home State</td>	<td>[im_state_widget $ha_state ha_state]</td></tr>


set whole_page "
<form action=contact-edit-2 method=POST>
[export_form_vars user_id]
<table cellpadding=0 cellspacing=2 border=0>
<tr valign=top><td>$contact_html</td><td>$home_html</td><td>$work_html</td></tr>
</table>
<input type=submit name=submit value=Submit>
</form>
"

set page_body $whole_page

doc_return  200 text/html [im_return_template]

