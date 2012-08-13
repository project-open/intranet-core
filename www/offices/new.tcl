# /packages/intranet-core/www/offices/new.tcl
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
    Lets users add/modify information about our offices.

    @param office_id if specified, we edit the office with this office_id
    @param return_url Return URL

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    { office_id:integer 0 }
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"

# Make sure the user has the privileges, because this
# pages shows the list of offices etc.
#
if {![im_permission $user_id "add_offices"]} { 
    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "
    <li>[_ intranet-core.lt_You_dont_have_suffici_1]"
}

if {$office_id > 0} {

    # Called with an existing office_id => Edit the office
    # We know that main_office_id is NOT NULL...

    if {![db_0or1row office_get_info "
	select	o.*
	from	im_offices o
	where	o.office_id=:office_id
	" 
    ]} {
	ad_return_error "[_ intranet-core.lt_Office_office_id_does]" "[_ intranet-core.lt_Please_back_up_and_tr]"
	return
    }

    set page_title "[_ intranet-core.Edit_office]"
    set context_bar [im_context_bar [list index "[_ intranet-core.Offices]"] [list "view?[export_url_vars office_id]" "[_ intranet-core.One_office]"] $page_title]

    
} else {

    # Completely new office. Set some reasonable defaults:
    set page_title "[_ intranet-core.Add_office]"
    set context_bar [im_context_bar [list index "[_ intranet-core.Offices]"] $page_title]
    set office_name ""
    set company_id ""
    set office_path ""
    # Grab today's date
    set note ""
    set phone ""
    set fax ""
    set address_line1 ""
    set address_line2 ""
    set address_postal_code ""
    set address_city ""
    set address_country_code ""

    # 160=Active
    set office_status_id 160
    # 170=Main Office
    set office_type_id 170
    set creation_ip_address [ns_conn peeraddr]
    set creation_user $user_id
    set office_id [im_new_object_id]
    set ignore_max_hours_per_day_p "f"
}

set page_body "
<form method=post action=new-2>
[export_form_vars return_url office_id creation_ip_address creation_user main_office_id]
		  <table border=0>
		    <tr> 
		      <td colspan=2 class=rowtitle align=center>[_ intranet-core.Add_New_Office]</td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Office_Name]</td>
		      <td> 
<input type=text size=30 name=office_name value=\"$office_name\">
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.lt_Office_Directory_Path]</td>
		      <td> 
<input type=text size=20 name=office_path value=\"$office_path\">
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Company]</td>
		      <td> 
[im_company_select "company_id" $company_id "" "" [list "Deleted" "Past" "Declined" "Inactive"]]
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Office_Status]</td>
		      <td> 
[im_office_status_select "office_status_id" $office_status_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Office+Status'>
	[im_gif new "Add a new office status"]</A>"
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Office_Type]</td>
		      <td> 
[im_office_type_select "office_type_id" $office_type_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Office+Type'>
	[im_gif new "Add a new office type"]</A>"
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Phone]</td>
		      <td> 
<input type=text size=15 name=phone value=\"$phone\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Fax]</td>
		      <td> 
<input type=text size=15 name=fax value=\"$fax\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Address_1]</td>
		      <td> 
<input type=text size=30 name=address_line1 value=\"$address_line1\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Address_2]</td>
		      <td> 
<input type=text size=30 name=address_line2 value=\"$address_line2\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.ZIP_and_City]</td>
		      <td> 
<input type=text size=5 name=address_postal_code value=\"$address_postal_code\" >
<input type=text size=30 name=address_city value=\"$address_city\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Country]</td>
		      <td> 
[im_country_select address_country_code $address_country_code]
		      </td>
		    </tr>
		    <tr> 
		      <td>[_ intranet-core.Notes]</td>
		      <td> 
<textarea name=note rows=6 cols=30 wrap=soft>[philg_quote_double_quotes $note]</textarea>
		      </td>
		    </tr>
		    <tr> 
		      <td> [lang::message::lookup "" intranet-core.IgnoreParameterTimesheetMaxHoursPerDay "Ignore restriction amount logged hours per day"]</td>
		      <td> 
"

if { "f"==$ignore_max_hours_per_day_p } {
	append page_body "<input type='checkbox' name='ignore_max_hours_per_day_p' value='t' />" 	
} else {
	append page_body "<input type='checkbox' name='ignore_max_hours_per_day_p' value='t' checked />" 	
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td colspan='2'><center><input type=submit value=\"[lang::message::lookup "" intranet-core.Submit "Submit"]\"></center> </td>
		    </tr>
</table>
</form>
"

#doc_return  200 text/html [im_return_template]
