# /packages/intranet-core/www/admin/process-config/index.tcl
#
# Copyright (C) 2004-2010 ]project-open[


ad_page_contract {
    Show the permissions for all menus in the system

    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/admin/process-config/index" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Process Configuration"
set context_bar [im_context_bar $page_title]
set context ""

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"


# ------------------------------------------------------
# Modules
# ------------------------------------------------------

multirow create modules module_code module_short_name module_name


multirow append modules module_reporting BI "Biz Intelligence & Reporting"
multirow append modules module_collaboration_knowledge CKM "Collaboration & KM"
multirow append modules module_crm CRM "Customer Relationship Management"
multirow append modules module_finance FI "Finance"
multirow append modules module_human_resources HR "Human Resources"
multirow append modules module_itsm ITSM "IT Services Management"
multirow append modules module_product_development PD "Product Development"
multirow append modules module_project_management PM "Project Management"
multirow append modules module_software_development SD "Software Development"
multirow append modules module_service_management SM "Service Management"
multirow append modules module_translation TR "Translation Management"
multirow append modules module_provider_management PMA "Provider Management"

# Copy the multirow into hashes
multirow foreach modules {
    set module_short_name_hash($module_code) $module_short_name
    set module_name_hash($module_code) $module_name
}


# ------------------------------------------------------
# Multirow for processes
# ------------------------------------------------------

multirow create processes process_code process_name module_code module_description

multirow append processes process_ckm_collaboration "Collaboration" module_collaboration_knowledge "Collaboration within \]project-open\[ is a horizontal process that is integrated and integral part of several other processes."
multirow append processes process_ckm_knowledge_management "Knowledge Management" module_collaboration_knowledge "Knowledge Management refers to the identification and dissemination of business critical knowledge resources."
multirow append processes process_ckm_eroom_communication "Project E-Room Communication" module_collaboration_knowledge "Distributed teams residing in different time zones seldom have the opportunity to get together in a central place at a given time. E-room allow an easy to track and archive way of communicate, discuss and inform project stake holders during project definition and execution phase independent from location and time."
multirow append processes process_crm_campaign_management "Campaign Mgmt" module_crm "Campaign management in \]project-open\[ refers to planning, executing and evaluating mailings and other campaigns."
multirow append processes process_crm_customer_file_maintenance "Customer File Maintenance" module_crm "Customer File Maintenance ensures the availability of up-to-date customer data. Customer data refers to customer master data such as general address and contact information and transactional data such as projects performed for customer, internal employees involved and all related financial data."
multirow append processes process_crm_price_list_maintenance "Price List Maintenance" module_crm "Provider Price List Maintenance manages the administration of price lists and ensures that information is always up-to-date."
multirow append processes process_crm_sales_forecasting "Sales Forecasting" module_crm "The purpose of Sales Forecasting is to estimate the sales in the future as input to Resource Planning and Financial Planning processes."
multirow append processes process_fi_accounting "Accounting Process" module_finance "Accounting in the \]po\[ refers to the elaboration of Balance Sheets and Income Statements via double-entry book keeping. The \]po\[ team deliberately decided not to include double-entry accounting functionality within \]po\[. Instead, \]po\[ will export its captured financial information to an external accounting package."
multirow append processes process_fi_accounts_payable "Accounts Payable" module_finance "Accounts payable manages the processing of provider bills. "
multirow append processes process_fi_accounts_receivable "Accounts Receivable" module_finance "Accounts receivable starts when a new invoice has been created and covers all tasks until the payment has been made by the clients."
multirow append processes process_fi_controlling "Controlling" module_finance "Controlling in \]po\[ refers to the process of identification, accumulation and analysis of financial information in order to plan, evaluate and control operations. The main purpose of the Controlling process is to provide indicators for the other processes."
multirow append processes process_fi_credit_control "Credit Control" module_finance "Credit control describes all procedures necessary to ensure cash flow and minimize the risk of failure of payment."
multirow append processes process_fi_project_expenses "Managing Project Expenses" module_finance "Managing project expenses ensures that other than timesheet expenses are tracked and cleared in both directions, towards employees s well as clients."
multirow append processes process_fi_project_invoicing "Project Invoicing" module_finance "The project invoicing process deals with creating invoices for projects, according to a number of different scenarios."
multirow append processes process_fi_timesheet_invoicing "Timesheet Invoicing" module_finance "Timesheet Invoicing refers to the process of creating Invoices or Delivery Notes based on timesheet information."
multirow append processes process_fi_work_in_progress "Work in Progress Calculation" module_finance "Work in progress (WIP) figures are of foremost interest for Project Manager and Accountants. "
multirow append processes process_hr_employee_absence_management "Absence Management" module_human_resources "Absence Management refers to the process of managing absences. "
multirow append processes process_hr_employee_maintenance "Employee Maintenance" module_human_resources "Employee Maintenance refers to the maintenance of employee master data. \]po\[ allows the management of employee data such as contact information, cost involved and share of compound costs. The sum of monthly costs for an internal resource will be broken down to an hourly rate that is used to calculate costs on activities (project tasks, RFC's, incidents, etc.)"
multirow append processes process_hr_freelancer_management "Freelance Management" module_human_resources "Freelance management / management of external consultants refers to a group of processes from HR and other functional areas, which are specifically enabled for dealing with freelancers and external consultants. "
multirow append processes process_hr_project_staffing "Project Staffing" module_human_resources "Project staffing ensures that the right people will be assigned to the right projects."
multirow append processes process_hr_recruiting "Recruiting" module_human_resources "Recruiting refers to searching and contracting new company employees."
multirow append processes process_hr_skill_maintenance "Skill Maintenance" module_human_resources "The skill maintenance process deals with maintaining information about the skills of internal and external resources."
multirow append processes process_itsm_account_management "Account Management" module_itsm "The ITSM account management process refers to the interaction between customers/business users and IT staff. Some mature IT organizations have introduced a formalized account management process in order to assure business users with high service and to shield IT staff by priorizing user input."
multirow append processes process_itsm_change_management "Change Management" module_itsm "Change Management ensures standardized methods and procedures for efficient handling of changes. Changes should not disrupt services and performed with optimized resource allocation. Requests for Change (RFCs) are usually transmitted by   employees across al departments and hierarchy levels."
multirow append processes process_itsm_configuration_management "Configuration Management" module_itsm "Configuration Management tracks Configuration Items (CI) in an IT infrastructure."
multirow append processes process_itsm_incident_management "Incident Management" module_itsm "The goal of Incident Management is to restore a normal service operation as quickly as possible after an incidence interrupted business operations."
multirow append processes process_itsm_problem_management "Problem Management" module_itsm "The goal of 'Problem Management' is to resolve cause of incidents and to prevent their recurrence. "
multirow append processes process_itsm_release_management "Release Management" module_itsm "Release management (RM) is the process of managing software releases. The main goals of ITSM release management are the reduction of cost implementing and maintaining software and the reduction of service interruptions due to release changes."
multirow append processes process_itsm_service_level_management "Service Level Management" module_itsm "The purpose of Service Level Management is to manage customer-client relationship for services delivered, enable improvement in service quality and reduction in service disruption."

multirow append processes process_pd_idea_generation "PD Idea Generation" module_product_development "The idea generation process should certain groups of people to introduce 'ideas' into the system. These ideas will then be screened, evaluated and implemented as part of product development."

multirow append processes process_pm_project_planning "PM Project Planning" module_project_management "Project planning includes the preparation of a project plan and other documents."
multirow append processes process_pm_project_portfolio_management "PM Project Portfolio Mgmt" module_project_management ""
multirow append processes process_pm_project_resource_planning "PM Project Resource Planning" module_project_management ""
multirow append processes process_pm_project_tracking "PM Project Tracking & Monitoring" module_project_management ""
multirow append processes process_pm_project_timesheet_mangement "PM Timesheet Management" module_project_management ""
multirow append processes process_provider_rfq_management "PMA Provider Auction, RFQ & RFP" module_provider_management ""
multirow append processes process_provider_maintenance "PMA Provider Maintenance" module_provider_management ""


multirow create processes_full process_code process_name module_code module_short_name module_name module_description

multirow foreach processes {
    multirow append processes_full $process_code $process_name $module_code $module_short_name_hash($module_code) module_name_hash($module_code) $module_description
}




template::list::create \
    -name processes_full \
    -key process_code \
    -elements {
	module_short_name {
	    label "Module"
            link_url_eval "http://www.project-open.org/en/$module_code"
	}
	process_name {
	    label "Name"
            link_url_eval "http://www.project-open.org/en/$process_code"
	}
	module_description {
	    label "Description"
	}
	
    } \
    -bulk_actions {
	"Disable" "disable-processes" "Disable Processes"
	"Enable" "enable-processes" "Enable Processes"
    } \
    -bulk_action_method post \
    -bulk_action_export_vars { return_url } \
    -actions [list "New backup" [export_vars -base pg_dump] "create new postgres dump"] \

