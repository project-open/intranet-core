# /www/intranet/companies/accounting-contact.tcl
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
    Lets you select a accounting contact from users assigned to this group

    @param company_id company's group id
    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    company_id:integer,notnull
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-core.lt_Add_accounting_contac]"
set context_bar [im_context_bar [list /intranet/companies/ "[_ intranet-core.Companies]"] $page_title]

set company_name [db_string company_name {
select c.company_name
from im_companies c
where c.company_id = :company_id
}]
    
set sql "
	select distinct
	        u.user_id,
	        im_name_from_user_id(u.user_id) as name,
	        im_email_from_user_id(u.user_id) as email
	from
	        users u,
	        acs_rels r
	where
	        r.object_id_one = :company_id
	        and r.object_id_two = u.user_id
"

if {$company_id != [im_company_internal]} {
    append sql "
	        and not exists (
			select	member_id
			from	group_member_map m,
				membership_rels mr
			where	m.member_id = u.user_id
				and m.rel_id = mr.rel_id
				and mr.member_state = 'approved'
				and m.group_id = [im_employee_group_id]
		)       
    "
}

set contact_info ""
db_foreach address_book_info $sql  {
    append contact_info "<li>$name, $email  </a>(<a href=accounting-contact-2?[export_url_vars company_id user_id]>[_ intranet-core.lt_make_accounting_conta]</a>)"
} 
db_release_unused_handles


if { [empty_string_p $contact_info] } {
    set new_client_link "<A HREF=/intranet/users/new>[_ intranet-core.new_client_contact]</A>"
    set new_company_employee_link "<A HREF=/intranet/companies/view?company_id=$company_id>[_ intranet-core.company_employee]</A>"
    set page_body "
<H3>[_ intranet-core.lt_No_Company_Employees_]</H3>
[_ intranet-core.lt_We_have_no_contacts_i]<BR>
<UL>
  <LI>[_ intranet-core.lt_Please_create_a_new_c]

  <LI>[_ intranet-core.lt_Make_the_new_client_c]

  <LI>[_ intranet-core.lt_Finally_revisit_this_]

</UL>

[_ intranet-core.lt_Also_please_make_sure]
"

    ad_return_template
    return
}

set return_url "[im_url_stub]/companies/view?[export_url_vars company_id]"

set page_title "[_ intranet-core.lt_Select_accounting_con]"
set context_bar [im_context_bar [list ./ "[_ intranet-core.Companies]"] [list view?[export_url_vars company_id] "[_ intranet-core.One_company]"] "[_ intranet-core.Select_contact]"]

set page_body "
<ul>
$contact_info
</ul>
"

ad_return_template
