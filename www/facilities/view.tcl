# /www/intranet/facilities/view.tcl
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
    Shows all info about a office
    @param office_id:integer

    @author Mark C (markc@arsdigita.com)
    @author Mike Bryzek (mbryzek@arsdigita.com)
    @cvs-id view.tcl,v 1.3.2.11 2000/10/30 21:02:31 tony Exp
} {
    office_id:integer
}
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set caller_office_id $office_id

set return_url [im_url_with_query]

if { [db_0or1row office_row "
select 
            office_id, 
            office_name, 
            fax, 
            phone,
            address_line1,
            address_line2,
            address_city,
            address_state,
            address_postal_code,
            landlord,
            security,
            note,
            contact_person_id,
            im_name_from_user_id(contact_person_id) as contact_name
from 
            im_offices
where
            office_id = :caller_office_id
"] } {
    set page_title "$office_name"
    set context_bar [ad_context_bar [list ./ "Offices"] "One office"]
    set page_body ""
    
    append page_body "
    <table cellpadding=3>
    
    <tr>
    <th valign=top align=right>Addess:</th>
    <td valign=top>[im_format_address $address_line1 $address_line2 $address_city $address_state $address_postal_code]</td>
    </tr>
    
    <tr>
    <th valign=top align=right>Phone:</TH>
    <td valign=top>$phone</td>
    </tr>
    
    <tr>
    <th valign=top align=right>Fax:</TH>
    <td valign=top>$fax</td>
    </tr>
    
    <tr>
    <th valign=top align=right>Contact:</TH>
    <td valign=top>
    "
    if { [empty_string_p $contact_person_id] } {
	append page_body "    <a href=primary-contact?office_id=$caller_office_id&limit_to_users_in_group_id=[im_employee_group_id]>Add primary contact</a>\n"
    } else {
	append page_body "
	<a href=../users/view?user_id=$contact_person_id>$contact_name</a>
	(<a href=primary-contact?office_id=$caller_office_id>change</a> |
	<a href=primary-contact-delete?[export_url_vars office_id return_url]>remove</a>)
	"
    }
    
    append page_body "
    </td>
    </tr>
    
    <tr>
    <th align=right valign=top>Landlord:</TH>
    <td valign=top>$landlord</td>
    </tr>
    
    <tr>
    <th align=right valign=top>Security:</TH>
    <td valign=top>$security</td>
    </tr>
    
    <tr>
    <th align=right valign=top>Other<Br> information:</TH>
    <td valign=top>$note</td>
    </tr>
    
    <tr>
    <th></th>
    <td align=center>(<a href=new?office_id=$caller_office_id&[export_url_vars return_url]>edit</A>)
    "
    if [im_is_user_site_wide_or_intranet_admin $user_id] {
	append page_body "
	</td>
	</tr>
	<tr>
	<th>Action:</th>
	<td><a href=delete?office_id=$caller_office_id>delete this office</a>
	"
    }
    append page_body "
    </td>
    </tr>
    
    </table>
    
    "
    
    
} else {
    ad_return_error "Error" "Office doesn't exist"
    return
}




doc_return  200 text/html [im_return_template]

