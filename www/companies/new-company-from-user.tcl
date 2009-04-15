# /packages/intranet-core/www/companies/new-company-from-user.tcl
#
# Copyright (C) 2003-2005 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Creates and updates a company for a specific user
    (Freelance or Customer).
    This is necessary because invoicing and financial documents
    work on the level of companies while user log-in and 
    task assignments work on the level of users (natural
    persons).

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    user_id:integer
    {company_name ""}
    {company_type_id 0}
    {company_status_id 0}
}

# -----------------------------------------------------------------
# Default & Security
# -----------------------------------------------------------------

set freelance_id $user_id

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id add_companies]} {
    ad_return_complaint 1 "<li>[_ intranet-trans-invoices.lt_You_have_insufficient]"
    return
}

# -----------------------------------------------------------------
# Get everything about the user
# -----------------------------------------------------------------

# V3.3->3.4

if { "" == [im_customer_group_id] } {
    set user_is_customer_p 0
} else {
    set user_is_customer_p [db_string is_customer "select count(*) from group_distinct_member_map where member_id=:user_id and group_id=[im_customer_group_id]"]
}

if { "" == [im_freelance_group_id] } {
    set user_is_freelance_p 0
} else {
    set user_is_freelance_p [db_string is_freelance "select count(*) from group_distinct_member_map where member_id=:user_id and group_id=[im_freelance_group_id]"]
}

if { "" == [im_partner_group_id] } {
   set user_is_partner_p 0
} else { 
   set user_is_partner_p [db_string is_partner "select count(*) from group_distinct_member_map where member_id=:user_id and group_id=[im_partner_group_id]"]
}

if {$user_is_customer_p && $user_is_freelance_p} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-core.Both_Customer_nor_Freelance "The user is both a customer and a freelancer. We can't decide what company type to create."]
    return
}

if {!$user_is_partner_p && !$user_is_customer_p && !$user_is_freelance_p} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-core.Neither_Customer_nor_Freelance "The user is neither a customer nor a freelancer. We can't decide what company type to create."]
    return
}

set path_prefix ""
set name_prefix ""
if {0 == $company_type_id} {
    if {$user_is_customer_p} { 
	set company_type_id [im_company_type_customer] 
	set path_prefix "customer"
	set name_prefix "Customer"
    }
    if {$user_is_freelance_p} { 
	set company_type_id [im_company_type_freelance] 
	set path_prefix "freelance"
	set name_prefix "Freelance"
    }
    if {$user_is_partner_p} { 
	set company_type_id [im_company_type_partner] 
	set path_prefix "partner"
	set name_prefix "Partner"
    }
}


db_1row freelancer_info "
select
	u.*,
	c.*
from
	cc_users u,
	users_contact c,
        country_codes ha_cc,
        country_codes wa_cc
where
	u.user_id = c.user_id(+)
	and u.user_id = pe.person_id(+)
	and u.user_id = pa.party_id(+)
        and c.ha_country_code = ha_cc.iso(+)
        and c.wa_country_code = wa_cc.iso(+)
"

set manager_id ""

# -----------------------------------------------------------------
# Setup Company Path - serves as a unique identifier
# -----------------------------------------------------------------

# Set the "Company Path" (=unique company identifier) to 
# freelance_id + "_freelance".
#
if {"" != $company_name} {
    # Specific company - build path from company
    set company_path [string tolower [string trim $company_name]]
    set company_path [string map -nocase {" " "_" "'" "" "/" "_" "-" "_"} $company_path]
} else {
    set company_path "${path_prefix}_${freelance_id}"
}

if {[regexp {\ } $company_path]} {
    ad_return_complaint 1 "Invalid company name '$company_name':<br>
    the company name contains characters that are not allowed in a company name.<br>
    please correct."
    return
}


# -----------------------------------------------------------------
# Setup Company Fields
# -----------------------------------------------------------------

# Check if the company already exists
#
set company_id [db_string company_id "select company_id from im_companies where company_path=:company_path" -default 0]

if {!$company_id} {
    
    if {"" == $company_name} {
	set company_name "$name_prefix $first_names $last_name"
    }
    if {0 == $company_status_id} {
	set company_status_id [im_company_status_active]
    }

    set office_name "$company_name Main Office"
    set office_path "${path_prefix}_office_${freelance_id}"

    set office_id [db_string office_id "select office_id from im_offices where office_path=:office_path" -default 0]
    if {!$office_id} {
	# Create a new main_office:
	set office_id [office::new \
		-office_name	$office_name \
		-office_path	$office_path \
		-office_status_id [im_office_status_active] \
		-office_type_id [im_office_type_main] \
	]
    }

    # Now create the company with the new main_office:
    set company_id [company::new \
	-company_name	$company_name \
        -company_path	$company_path \
        -main_office_id	$office_id \
        -company_type_id $company_type_id \
        -company_status_id $company_status_id]
} else {
	db_1row company_info "
		select
			c.*,
			o.*
		from
			im_companies c,
			im_offices o
		where
			c.company_id = :company_id
			and o.company_id = c.company_id
	"
}

# -----------------------------------------------------------------
# Update the Office
# -----------------------------------------------------------------

# Phone Logic: Prefer work phone over private one.
set phone ""
if {"" != $priv_home_phone} { set phone $priv_home_phone }
if {"" != $home_phone} { set phone $home_phone }
if {"" != $cell_phone} { set phone $cell_phone }
if {"" != $work_phone} { set phone $work_phone }

# Address Logic: Prefer work address over home address
set address_line1 ""
set address_line2 ""
set address_city ""
set address_postal_code ""
set address_country_code ""
if {"" != $ha_line1} { set address_line1 $ha_line1 }
if {"" != $wa_line1} { set address_line1 $wa_line1 }
if {"" != $wa_line2} { set address_line2 $wa_line2 }
if {"" != $ha_line2} { set address_line2 $ha_line2 }
if {"" != $ha_city} { set address_city $ha_city }
if {"" != $wa_city} { set address_city $wa_city }
if {"" != $ha_postal_code} { set address_postal_code $ha_postal_code }
if {"" != $wa_postal_code} { set address_postal_code $wa_postal_code }
if {"" != $ha_country_code} { set address_country_code $ha_country_code }
if {"" != $wa_country_code} { set address_country_code $wa_country_code }


set update_sql "
update im_offices set
	office_name = :office_name,
	phone = :phone,
	fax = :fax,
	address_line1 = :address_line1,
	address_line2 = :address_line2,
	address_city = :address_city,
	address_postal_code = :address_postal_code,
	address_country_code = :address_country_code
where
	office_id = :office_id
"
    db_dml update_offices $update_sql


# -----------------------------------------------------------------
# Update the Company
# -----------------------------------------------------------------

set update_sql "
update im_companies set
	company_name		= :company_name,
	company_path		= :company_path,
	company_status_id	= :company_status_id,
	company_type_id	= :company_type_id,
	manager_id		= :manager_id,
	billable_p		= 'f',
	note			= '',
	accounting_contact_id	= :freelance_id,
	primary_contact_id	= :freelance_id
where
	company_id = :company_id
"
    db_dml update_company $update_sql


#	vat_number		= :vat_number,
#	old_company_status_id	= :old_company_status_id,
#	referral_source		= :referral_source,
#	start_date		= :start_date,
#	annual_revenue_id	= :annual_revenue_id,
#	contract_value		= :contract_value,
#	site_concept		= :site_concept,


# -----------------------------------------------------------------
# Make sure the creator and the manager become Key Accounts
# -----------------------------------------------------------------

#set rel_count [db_string rel_count "select count(*) from acs_rels where object_id_one=:company_id and object_id_two = :freelance_id"]
#if {!$rel_count} {
#    # add the creating current user to the group
#    relation_add \
#	-member_state "approved" \
#	"admin_rel" \
#	$company_id \
#	$freelance_id
#}

set role_id [im_company_role_key_account]

im_biz_object_add_role $freelance_id $company_id $role_id

#if {"" != $manager_id } {
#    im_biz_object_add_role $manager_id $company_id $role_id
#}


db_release_unused_handles

ad_returnredirect "/intranet/companies/new?company_id=$company_id"

