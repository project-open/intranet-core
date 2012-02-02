ad_page_contract {

    company-contacts.tcl
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-30
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $user_id]

# Check permissions. "See details" is an additional check for
# critical information
im_company_permissions $user_id $company_id view read write admin


set also_add_to_group [im_customer_group_id]
set company_clients [im_group_member_component $company_id $user_id $admin $return_url "" [im_employee_group_id] $also_add_to_group]


set companys_employees_str [lang::message::lookup "" intranet-core.Companys_Contacts "Company's Contacts"]

# ad_return_complaint 1 $company_members_html
# set company_clients_html [im_table_with_title $companys_employees_str $company_clients]
set company_clients_html $company_clients
