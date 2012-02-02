ad_page_contract {

    company-employees.tcl
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-30
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $user_id]

# Check permissions. "See details" is an additional check for
# critical information
im_company_permissions $user_id $company_id view read write admin

set company_members [im_group_member_component $company_id $user_id $admin $return_url [im_employee_group_id]]

# ad_return_complaint 1 $user_is_employee_p
if {!$user_is_employee_p} { set company_members "" }


set our_employees_str [lang::message::lookup "" intranet-core.Our_employees_related "Our Employees (managing the company)"]

# ad_return_complaint 1 $company_members
# set company_members_html [im_table_with_title $our_employees_str $company_members]
set company_members_html $company_members
