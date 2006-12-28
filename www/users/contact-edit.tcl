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
    ad_return_complaint "[_ intranet-core.Bad_User]" "<li>[_ intranet-core.lt_You_must_specify_a_va]"
    return
}

if {!$write} {
    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "<li>[_ intranet-core.lt_You_have_insufficient_2]"
    return
}


# Should we bother about State and ZIP fields?
set some_american_readers_p [parameter::get_from_package_key -package_key acs-subsite -parameter SomeAmericanReadersP -default 0]

set some_american_readers_p 1

db_0or1row user_full_name "
select 
	im_name_from_user_id(person_id) as user_name
from 
	persons 
where 
	person_id = :user_id
"

set page_title "Contact for $user_name"
if {[im_permission $current_user_id view_users]} {
    set context_bar [im_context_bar [list /intranet/users/ "Users"] $page_title]
} else {
    set context_bar [im_context_bar $page_title]
}

# use [info exists ] here?
if { [empty_string_p $user_name] } {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_We_couldnt_find_user__1]"
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
set wa_state ""
set ha_country_code ""

db_0or1row user_contact_info {
    select *
    from users_contact 
    where user_id = :user_id
}

# ---------------------------------------------------------------
# Format the table
# ---------------------------------------------------------------

set contact_html "
<table cellpadding=0 cellspacing=2 border=0>
<tr><td colspan=2 class=rowtitle align=center>[_ intranet-core.Contact_Information]</td></tr>
<tr><td>[_ intranet-core.Home_phone]</td>	<td><input type=text name=home_phone value=\"$home_phone\" ></td></tr>
<tr><td>[_ intranet-core.Work_phone]</td>	<td><input type=text name=work_phone value=\"$work_phone\" ></td></tr>
<tr><td>[_ intranet-core.Cell_phone]</td>	<td><input type=text name=cell_phone value=\"$cell_phone\" ></td></tr>
<tr><td>[_ intranet-core.Pager]</td>	<td><input type=text name=pager value=\"$pager\" ></td></tr>
<tr><td>[_ intranet-core.Fax]</td>	<td><input type=text name=fax value=\"$fax\" ></td></tr>
<tr><td>[_ intranet-core.Aim_Screen_Name]</td><td><input type=text name=aim_screen_name value=\"$aim_screen_name\" ></td></tr>
<tr><td>[_ intranet-core.ICQ_Number]</td>	<td><input type=text name=icq_number value=\"$icq_number\" ></td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
</table>"

set home_html "
<table cellpadding=0 cellspacing=2 border=0>
<tr><td colspan=2 class=rowtitle align=center>[_ intranet-core.Home_Address]</td></tr>
<tr><td valign=top>[_ intranet-core.Home_address]</td><td>
			<input type=text name=ha_line1 value=\"$ha_line1\" >
			<input type=text name=ha_line2 value=\"$ha_line2\" ></td></tr>
<tr><td>[_ intranet-core.Home_City]</td>	<td><input type=text name=ha_city value=\"$ha_city\" ></td></tr>"

if {$some_american_readers_p} { append home_html "
<tr><td>[lang::message::lookup "" intranet-core.Home_State "Home State"]</td><td><input type=text name=ha_state value=\"$ha_state\" ></td></tr>" 
}

append home_html "
<tr><td>[_ intranet-core.Home_Postal_Code]</td><td><input type=text name=ha_postal_code value=\"$ha_postal_code\" ></td></tr>
<tr><td>[_ intranet-core.Home_Country]</td><td>[im_country_widget $ha_country_code ha_country_code]</td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
</table>"

set work_html "
<table cellpadding=0 cellspacing=2 border=0>
<tr><td colspan=2 class=rowtitle align=center>[_ intranet-core.Work_Address]</td></tr>
<tr><td valign=top>[_ intranet-core.Work_address]</td><td>
			<input type=text name=wa_line1 value=\"$wa_line1\" >
			<input type=text name=wa_line2 value=\"$wa_line2\" ></td></tr>
<tr><td>[_ intranet-core.Work_City]</td>	<td><input type=text name=wa_city value=\"$wa_city\" ></td></tr>"

if {$some_american_readers_p} { append work_html "
<tr><td>[lang::message::lookup "" intranet-core.Work_State "Work State"]</td><td><input type=text name=wa_state value=\"$wa_state\" ></td></tr>" 
}

append work_html "
<tr><td>[_ intranet-core.Work_Postal_Code]</td><td><input type=text name=wa_postal_code value=\"$wa_postal_code\" ></td></tr>
<tr><td>[_ intranet-core.Work_Country]</td><td>[im_country_widget $wa_country_code wa_country_code]</td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
</table>"


set note_html "
<table cellpadding=0 cellspacing=2 border=0 width=\"100%\">
<tr>
  <td colspan=5 class=rowtitle align=center>
    [_ intranet-core.Users_Contact_Note]
  </td>
</tr>
<tr>
  <td colspan=5 align=center>
    <textarea rows=8 cols=80 name=note>$note</textarea>
  </td>
</tr>
</table>
"

# <tr><td>Work State</td>	<td>[im_state_widget $wa_state wa_state]</td></tr>
# <tr><td>Home State</td>	<td>[im_state_widget $ha_state ha_state]</td></tr>

ad_return_template

