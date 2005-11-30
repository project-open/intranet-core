# /packages/intranet-core/www/companies/new.tcl
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
    Lets users add/modify information about our companies.
    Contact details are not stored with the company itself,
    but with a "main_office" that is a required property
    (not null).

    @param company_id if specified, we edit the company with this company_id
    @param return_url Return URL

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
    @author juanjoruizx@yahoo.es
} {
    company_id:integer,optional
    { form_mode "edit" }
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"

# Make sure the user has the privileges, because this
# pages shows the list of companies etc.
#
if {![im_permission $user_id "add_companies"]} { 
   ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "
  <li>[_ intranet-core.lt_You_dont_have_suffici]"
}

set action_url "/intranet/companies/new-2"
set focus "menu.var_name"

set page_title "[_ intranet-core.Edit_Company]"
set context_bar [im_context_bar [list index "[_ intranet-core.Companies]"] [list "view?[export_url_vars company_id]" "[_ intranet-core.One_company]"] $page_title]



# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set company_status_options [list]
set company_type_options [list]
set annual_revenue_options [list]
set country_options [im_country_options]
set employee_options [im_employee_options]

ad_form \
    -name company \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	company_id:key
	{main_office_id:text(hidden)}
	{company_name:text(text) {label "Company Name"} {html {size 60}}}
	{company_path:text(text) {label "Company Short Name"} {html {size 40}}}
	{referral_source:text(text),optional {label "Referral Source"} {html {size 60}}}
	{company_status_id:text(im_category_tree) {label "Company Status"} {custom {category_type "Intranet Company Status" } } }
	{company_type_id:text(im_category_tree) {label "Company Type"} {custom {category_type "Intranet Company Type"} } }
	{manager_id:text(select),optional {label "Key Account"} {options $employee_options} }
	
	{phone:text(text),optional {label "Phone"} {html {size 20}}}
	{fax:text(text),optional {label "Fax"} {html {size 20}}}
	{address_line1:text(text),optional {label "Address 1"} {html {size 40}}}
	{address_line2:text(text),optional {label "Address 2"} {html {size 40}}}
	{address_city:text(text),optional {label "City"} {html {size 30}}}
	{address_postal_code:text(text),optional {label "ZIP"} {html {size 6}}}
	{address_country_code:text(select),optional {label "Country"} {options $country_options} }
	{site_concept:text(text),optional {label "Web Site"} {html {size 60}}}
	{vat_number:text(text),optional {label "VAT Number"} {html {size 60}}}
	{annual_revenue_id:text(im_category_tree),optional {label "Annual Revenue"} {custom {category_type "Intranet Annual Revenue"} } }
	{vat:text(text),optional {label "Default VAT (Percent)"} {html {size 10}}}
	{invoice_template_id:text(im_category_tree),optional {label "Default Invoice<br>Template"} {custom {category_type "Intranet Cost Template"} } }
	{note:text(textarea),optional {label "Note"} {}}
    }


ad_form -extend -name company -select_query {

select
	c.*,
	to_char(c.start_date,'YYYY-MM-DD') as start_date_formatted,
	o.phone,
	o.fax,
	o.address_line1,
	o.address_line2,
	o.address_city,
	o.address_postal_code,
	o.address_country_code
from 
	im_companies c, 
	im_offices o
where 
	c.company_id = :company_id
	and c.main_office_id = o.office_id

} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

# ------------------------------------------------------
# Dynamic Fields
# ------------------------------------------------------


set dynamic_fields_p 0
if {[db_table_exists im_dynfield_attributes]} {

    set dynamic_fields_p 1
    set form_id "company"
    set object_type "im_company"
    set my_company_id 0
    if {[info exists company_id]} { set my_company_id $company_id }


    im_dynfield::append_attributes_to_form \
	-object_type $object_type \
        -form_id $form_id \
        -object_id $my_company_id
}

