# /packages/intranet-core/tcl/intranet-navbar-procs.tcl
#
# Copyright (C) 1998-2007 ]project-open[
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

ad_library {
    Define the left-hand process oriented navigation bar
    @author Frank Bergmann (frank.bergmann@project-open.com)
}


# --------------------------------------------------------
# 
# --------------------------------------------------------

# from Klaus: "The ]po[ objects are clear from the top menu,
# but the underlying processes are unclear.

# ToDo: Skills for HR
# ToDo: Salaries report in HR
# Accounts Payable as first element in Finance
# Project Sales Pipeline more explicitely
# Setup menu as separate menu under "Processes" in Menu tree
# Quality Management as subprocess of Provider Management?
# Sales Pipeline as separate process?
# Query/Incident Management as subprocess of project managent?
# Risk Management as part of PM?
# Project Portfolio Management as separate Process?
# Integrate indicators per process



ad_proc -public im_navbar_doc_wiki { } {
    Link to ]po[ Wiki. Without trailing "/".
} {
    return "http://www.project-open.org/en"
}

ad_proc -public im_navbar_tree { 
    {-no_cache:boolean}
    {-user_id 0}
    {-label ""} 
} {
    Creates an <ul> ...</ul> hierarchical list with all major
    objects in the system.
} {
    if {0 == $user_id} { set user_id [ad_get_user_id] }
    set locale [lang::user::locale -user_id $user_id]

    set no_cache_p 1
    if {$no_cache_p} {
	return [im_navbar_tree_helper -user_id $user_id -locale $locale -label $label]
    } else {
	return [util_memoize [list im_navbar_tree_helper -user_id $user_id -locale $locale -label $label] 3600]
    }
}

ad_proc -public im_navbar_tree_helper { 
    -user_id:required
    {-locale "" }
    {-label ""} 
} {
    Creates an <ul> ...</ul> hierarchical list with all major
    objects in the system.
} {
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }
    set wiki [im_navbar_doc_wiki]

    set show_left_functional_menu_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "ShowLeftFunctionalMenupP" -default 0]
    if {!$show_left_functional_menu_p} { return "" }

    set general_help_l10n [lang::message::lookup "" intranet-core.Home_General_Help "\]po\[ Modules Help"]
    set html "
      	<div class=filter-block>
	<ul class=mktree>
	<li><a href=\"/intranet/index\">[lang::message::lookup "" intranet-core.Home Home]</a>
	<ul>
		<li><a href=$wiki/list_modules>$general_help_l10n</a>
		[im_menu_li dashboard]
		[im_menu_li indicators]
    "
    if {$user_id == 0} {
	append html "
		<li><a href=/register/>[lang::message::lookup "" intranet-core.Login_Navbar Login]</a>
        "
    }
    if {$user_id > 0} {
	append html "
		<li><a href=/register/logout>[lang::message::lookup "" intranet-core.logout Logout]</a>
        "
    }

    append html "
	</ul>
	[if {![catch {set ttt [im_navbar_tree_project_management -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_human_resources -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_sales_marketing -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_provider_management -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_helpdesk -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_collaboration -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
        [if {![catch {set ttt [im_navbar_tree_finance -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[if {![catch {set ttt [im_navbar_tree_master_data_management -user_id $user_id -locale $locale]}]} {set ttt} else {set ttt ""}]
	[im_navbar_tree_admin -user_id $user_id -locale $locale]
      </div>
    "
}


# --------------------------------------------------------
#
# --------------------------------------------------------



ad_proc -public im_navbar_tree_admin { 
    -user_id:required
    -locale:required
} { 
    Admin Navbar 
} {
    set wiki [im_navbar_doc_wiki]
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

    if {!$admin_p} { return "" }
    set html "
	[im_menu_li_helper admin]
		<ul>
		[im_navbar_write_tree \
			-no_cache \
			-user_id $user_id \
			-locale $locale \
			-label "admin" \
			-maxlevel 2 \
		        -ignore_disabled_p 1 \
		]
		</ul>
	</ul>
    "
    return $html
}


ad_proc -public im_navbar_tree_project_management { 
    -user_id:required
    -locale:required
} { 
    Project Management Navbar 
} {
    set wiki [im_navbar_doc_wiki]
#    if {0 == $user_id} { return "" }

    set html "
	<li><a href=/intranet/projects/>[lang::message::lookup "" intranet-core.Project_Management "Project Management"]</a>
	<ul>
	<li><a href=$wiki/module_project_management>[lang::message::lookup "" intranet-core.PM_Help "PM Help"]</a>
    "
    if {[im_permission $user_id add_projects]} {
	append html "
		<li><a href=/intranet/projects/new>[lang::message::lookup "" intranet-core.New_Project "New Project"]</a>
        "
    }
    
    # Add sub-menu with project types
    if {$user_id > 0} {
	append html "
	        <li><a href=/intranet/projects/index>[lang::message::lookup "" intranet-core.Project_Types "Project Types"]</a>
	        <ul>
        "
	set project_type_sql "
		select * from im_project_types 
		where project_type_id not in (select child_id from im_category_hierarchy)
		order by project_type
        "
	db_foreach project_types $project_type_sql {
	    set url [export_vars -base "/intranet/projects/index" {project_type_id}]
	    regsub -all " " $project_type "_" project_type_subst
	    set name [lang::message::lookup "" intranet-core.Project_type_$project_type_subst "${project_type}s"]
	    append html "<li><a href=\"$url\">$name</a></li>\n"
	}
	append html "
	        </ul>
	        </li>
        "
    }

    # Add sub-menu with project status
    if {$user_id > 0} {
	append html "
	        <li><a href=/intranet/projects/index>[lang::message::lookup "" intranet-core.Project_Status "Project Status"]</a>
	        <ul>
        "
	set project_status_sql "
		select * from im_project_status 
		where project_status_id not in (select child_id from im_category_hierarchy)
		order by project_status
        "
	db_foreach project_status $project_status_sql {
	    set url [export_vars -base "/intranet/projects/index" {project_status_id}]
	    regsub -all " " $project_status "_" project_status_subst
	    set name [lang::message::lookup "" intranet-core.Project_status_$project_status_subst "$project_status"]
	    append html "<li><a href=\"$url\">$name</a></li>\n"
	}
	append html "
	        </ul>
	        </li>
        "
    }

    set view_invoices_p [im_permission $user_id view_invoices]
    set view_projects_all_p [im_permission $user_id view_projects_all]

    if {$view_invoices_p && $view_projects_all_p} {
	append html "
		<li><a href=/intranet-dw-light/projects.csv>[lang::message::lookup "" intranet-core.Export_Projects_to_CSV "Export Projects to CSV"]</a></li>
        "
    }

    if {$user_id > 0} {
        append html "
		<li><a href=/intranet/projects/index?filter_advanced_p=1>[lang::message::lookup "" intranet-core.Project_Advanced_Filtering "Project Advanced Filtering"]</a>
        "
    }

    if {[im_permission $user_id "view_projects_all"]} {
        append html "
<li><a href=/intranet-ganttproject/gantt-resources-cube?config=resource_planning_report>[lang::message::lookup "" intranet-core.Project_Resource_Planning "Project Resource Planning"]</a>
        "
    }

    if {[im_permission $user_id view_finance] && [im_permission $user_id view_projects]} {
        append html "
		<li><a href=/intranet/projects/index?view_name=project_costs>[lang::message::lookup "" intranet-core.Projects_Profit_and_Loss "Projects Profit &amp; Loss"]</a>
        "
    }
    append html "
	</ul>
    "
    return $html
}




ad_proc -public im_navbar_tree_sales_marketing { 
    -user_id:required
    -locale:required
} { 
    Sales & Marketing Navbar
} {
    set wiki [im_navbar_doc_wiki]

    set view_invoices_p [im_permission $user_id view_invoices]
    set view_projects_all_p [im_permission $user_id view_projects_all]

    set html "
	<li><a href=/intranet/>[lang::message::lookup "" intranet-core.CRM_Sales "CRM"]</a>
	<ul>
	<li><a href=$wiki/module_crm>[lang::message::lookup "" intranet-core.CRM_Help "CRM Help"]</a>
    "

    # Add sub-menu with project status
    if {$user_id > 0} {
	append html "
		<li><a href=/intranet/projects/index>[lang::message::lookup "" intranet-core.Project_Proposals "Project Proposals"]</a>
	        <ul>
        "
	set potential_projects_sql "
		select * from im_project_status 
		where project_status_id in ([join [im_sub_categories [im_project_status_potential]] ","])
		order by project_status
        "
	db_foreach project_status $potential_projects_sql {
	    set url [export_vars -base "/intranet/projects/index" {project_status_id}]
	    regsub -all " " $project_status "_" project_status_subst
	    set name [lang::message::lookup "" intranet-core.Project_status_$project_status_subst "$project_status"]
	    append html "<li><a href=\"$url\">$name</a></li>\n"
	}
	append html "
	        </ul>
	        </li>
        "
    }

    append html "
		<li><a href=/intranet/projects/index>[lang::message::lookup "" intranet-core.Customer_Prospects "Customer Prospects"]</a>
			<ul>
    "

    if {[im_permission $user_id add_companies]} {
	append html "
			<li><a href=/intranet/companies/new>[lang::message::lookup "" intranet-core.New_Customer "New Customer"]</a></li>
        "
    }


    if {$user_id > 0} {
	set potential_companies_sql "
		select * from im_company_status 
		where company_status_id in ([join [im_sub_categories [im_company_status_potential]] ","])
		order by company_status
        "
	db_foreach company_status $potential_companies_sql {
	    set url [export_vars -base "/intranet/companies/index" {{type_id 57} {status_id $company_status_id}}]
	    regsub -all " " $company_status "_" company_status_subst
	    set name [lang::message::lookup "" intranet-core.Customers_status_$company_status_subst "$company_status"]
	    append html "<li><a href=\"$url\">$name</a></li>\n"
	}
    }
    append html "
			</ul>
		</li>
		<li><a href=/intranet/projects/index>Quoting</a>
			<ul>
    "


    if {[im_permission $user_id add_invoices]} {
	append html "
			<li><a href=/intranet-invoices/new?cost_type_id=3702>[lang::message::lookup "" intranet-core.New_Quote "New Quote"]</a></li>
        "
    }
    if {[im_permission $user_id view_invoices]} {
	append html "
			<li><a href=/intranet-invoices/list?cost_type_id=3702>[lang::message::lookup "" intranet-core.All_Quotes "All Quotes"]</a></li>
        "
    }
    append html "
			</ul>
		</li>
    "
    append html "
		<li><a href=/intranet-reporting/>[lang::message::lookup "" intranet-core.Reporting Reporting]</a>
			<ul>
    "

    if {$view_invoices_p && $view_projects_all_p} {
	append html "
			<li><a href=/intranet-dw-light/companies.csv>[lang::message::lookup "" intranet-core.Export_Customers_to_CSV "Export Customers to CSV/Excel"]</a></li>
        "
    }

    append html "
			[im_menu_li dashboard]
			[im_menu_li reporting-cubes-finance]
			</ul>
		</li>
	</ul>
    "
    return $html
}




ad_proc -public im_navbar_tree_human_resources { 
    -user_id:required
    -locale:required
} { 
    Human Resources Management
} {
    set wiki [im_navbar_doc_wiki]

    set html "
	<li><a href=/intranet/>[lang::message::lookup "" intranet-core.Human_Resources "Human Resources"]</a>
	<ul>
	<li><a href=$wiki/module_human_resources>[lang::message::lookup "" intranet-core.HR_Help "HR Help"]</a>
    "
    if {[im_permission $user_id add_users]} {
	append html "
		<li><a href=/intranet/users/new>[lang::message::lookup "" intranet-core.New_User "New User"]</a>
        "
    }

    # Add sub-menu with user profiles
    if {$user_id > 0} {
	append html "
	        <li><a href=/intranet/users/index>[lang::message::lookup "" intranet-core.User_Profiles "User Profiles"]</a>
        	<ul>
        "
	set profile_sql "
		select * from groups, im_profiles
		where group_id = profile_id and group_name not in ('The Public')
		order by group_name
	"
	db_foreach profiles $profile_sql {
	    set url [export_vars -base "/intranet/users/index" {{user_group_name $group_name}}]
	    regsub -all {[^0-9a-zA-Z]} $group_name "_" group_name_subst
	    set name [lang::message::lookup "" intranet-core.Profile_$group_name_subst $group_name]
	    append html "<li><a href=\"$url\">$name</a></li>\n"
	}
	append html "
		</ul>
		</li>
        "
    }

    if {[im_permission $user_id add_absences]} {
	append html "
		<li><a href=/intranet-timesheet2/absences/new>[lang::message::lookup "" intranet-core.New_Absence "New Absence"]</a></li>
       "
    }

    if {[im_permission $user_id "view_absences"]} {
	append html "
		<li><a href=/intranet-timesheet2/absences/index>[lang::message::lookup "" intranet-core.Absence_Types "Absence Types"]</a>
        "

	append html "
		<ul>
        "
	set absence_sql "
	select * from im_absence_types
	order by lower(absence_type)
        "
	db_foreach absences $absence_sql {
	    set url [export_vars -base "/intranet-timesheet2/absences/index" {absence_type_id}]
	    regsub -all " " $absence_type "_" absence_type_subst
	    set name [lang::message::lookup "" intranet-core.$absence_type_subst $absence_type]
	    append html "<li><a href=\"$url\">$name</a></li>\n"
	}
	append html "
		</ul>
		</li>
        "
    }

    if {[im_permission $user_id "add_expenses"]} {
	append html "
		<li><a href=/intranet-expenses/new>[lang::message::lookup "" intranet-core.New_Travel_Expense "New Travel Expense"]</a>
        "
    }

    if {[im_permission $user_id "add_expenses"]} {
	append html "
		<li><a href=/intranet-expenses/index>[lang::message::lookup "" intranet-core.Expense_Types "Expense Types"]</a>
		<ul>
        "
	set expense_sql "
		select * from im_expense_type
		order by lower(expense_type)
        "
	db_foreach expenses $expense_sql {
	    set url [export_vars -base "/intranet-expenses/index" {expense_type_id}]
	    regsub -all " " $expense_type "_" expense_type_subst
	    set name [lang::message::lookup "" intranet-expenses.$expense_type_subst $expense_type]
	    append html "<li><a href=\"$url\">$name</a></li>\n"
	}
	append html "
		</ul>
        "
    }

    append html "
		<li><a href=/intranet-reporting/>[lang::message::lookup "" intranet-core.HR_Reporting "HR Reporting"]</a>
                <ul>
    "
    append html "
        	        [im_menu_li "reporting-user-contacts"]
        	        [im_menu_li "reporting-timesheet-productivity"]
			<!-- Additional reports in future HR area? --> 
        	        [im_navbar_write_tree -user_id $user_id -locale $locale -package_key "intranet-reporting" -label "reporting-hr" -maxlevel 1]
                </ul>
		</li>
    "

    if {[im_permission $user_id view_users]} {
	append html "
		<li><a href=/intranet-dw-light/users.csv>[lang::message::lookup "" intranet-core.Export_Users_to_CSV "Export Users to CSV"]</a></li>
        "
    }
    append html "
		[im_menu_li timesheet2_timesheet]
	</ul>
    "

    return $html
}



ad_proc -public im_navbar_tree_provider_management { 
    -user_id:required
    -locale:required
} { 
    Provider Management 
} {
    set wiki [im_navbar_doc_wiki]

    set html "
	<li><a href=/intranet/>[lang::message::lookup "" intranet-core.Provider_Management "Provider Management"]</a>
	<ul>
	<li><a href=$wiki/module_provider_management>[lang::message::lookup "" intranet-core.Provider_Help "Provider Help"]</a>
    "
    if {[im_is_user_site_wide_or_intranet_admin $user_id]} {
	append html "
		<li><a href=/intranet-dw-light/companies.csv>[lang::message::lookup "" intranet-core.Export_Providers_to_CSV "Export Providers to CSV/Excel"]</a></li>
        "
    }
    append html "
		<li><a href=/intranet/projects/index>[lang::message::lookup "" intranet-core.Providers Providers]</a>
			<ul>
    "
    if {[im_permission $user_id add_companies]} {
	append html "
			<li><a href=/intranet/companies/new>[lang::message::lookup "" intranet-core.New_Provider "New Provider Company"]</a></li>
        "
    }
    if {[im_permission $user_id add_companies]} {
	append html "
			<li><a href=/intranet/users/new>[lang::message::lookup "" intranet-core.New_Provider_Contact "New Provider Contact"]</a></li>
        "
    }

    if {[im_permission $user_id add_users]} {
	append html "
			<li><a href=/intranet-freelance/index>[lang::message::lookup "" intranet-core.Search_for_Providers_by_Skill "Search for Providers by Skill"]</a></li>
	"
    }
    append html "
			[im_menu_li freelance_rfqs]
			</ul>
		</li>
		<li><a href=/intranet-reporting/>[lang::message::lookup "" intranet-core.Provider_Reporting "Provider Reporting"]</a>
			<ul>
			[im_menu_li reporting-cubes-finance]
    "
    if {[im_permission $user_id view_projects_all]} {
	append html "
			<li><a href=/intranet-ganttproject/gantt-resources-cube?config=resource_planning_report>[lang::message::lookup "" intranet-core.Project_Resource_Planning "Project Resource Planning"]</a>
        "
    }
    append html "
			</ul>
		</li>
	</ul>
    "
    return $html
}



ad_proc -public im_navbar_tree_collaboration { 
    -user_id:required
    -locale:required
} { 
    Collaboration NavBar 
} {
    set wiki [im_navbar_doc_wiki]

    set html "
	<li><a href=/intranet/>[lang::message::lookup "" intranet-core.Collaboration "Collaboration & KM"]</a>
	<ul>
	<li><a href=$wiki/module_collaboration_knowledge>[lang::message::lookup "" intranet-core.CollabKM_Help "C&KM Help"]</a></li>
		<li><a href=/intranet-search/search?type=all&q=search>[lang::message::lookup "" intranet-search-pg.Search_Engine "Search Engine"]</a></li>
		<li><a href=/calendar/>[lang::message::lookup "" intranet-calendar.Calendar "Calendar"]</a></li>
		[im_menu_li -pretty_name [lang::message::lookup "" intranet-core.Bug_Tracker "Bug Tracker"] bug_tracker]
		[im_menu_li forum]
		<li><a href=/intranet-forum/index>[lang::message::lookup "" intranet-core.Forum_Types "Forum Types"]</a>
		<ul>
    "
	
    set topic_type_sql "
	select * from im_forum_topic_types
	order by lower(topic_type)
    "
    db_foreach topic_types $topic_type_sql {
	set url [export_vars -base "/intranet-forum/index" {{forum_topic_type_id $topic_type_id}}]
	regsub -all " " $topic_type "_" topic_type_subst
	set name [lang::message::lookup "" intranet-forum.$topic_type_subst $topic_type]
	append html "<li><a href=\"$url\">$name</a></li>\n"
    }
    append html "
		</ul>
		</li>
		[im_menu_li -pretty_name Wiki wiki]
		<li><a href=/intranet-filestorage/>[lang::message::lookup "" intranet-core.File_Storage "File Storage"]</a></li>
		<li><a href=/simple-survey/>Surveys</a></li>
	</ul>
    "

    return $html
}


ad_proc -public im_navbar_tree_master_data_management { 
    -user_id:required
    -locale:required
} { 
    Master Data Management 
} {
    set wiki [im_navbar_doc_wiki]
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {!$admin_p} { return "" }

    return "
	<li><a href=/intranet/admin/categories/>Master Data Management</a>
	<ul>
		<li><a href=/intranet/companies/upload-companies>Import Companies from CSV</a>
		<li><a href=/intranet/users/upload-contacts>Import Contacts from CSV</a>
		<li><a href=/intranet/admin/categories/>General</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+UoM>Unit of Measure</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Projects</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Project+Status>Project Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Project+Type>Project Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Companies &amp; Offices</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Company+Customer+Prio>Company Customer Prio</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Company+Status>Company Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Company+Type>Company Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Office+Status>Office Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Office+Type>Office Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Absences &amp; Vacations</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Absence+Status>Absence Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Absence+Type>Absence Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>HR Recruiting</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Recruiting+Status>Recruiting Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Recruiting+Test+Result>Recruiting Test Result</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Employee+Pipeline+State>Employee Pipeline State</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Experience+Level>Experience Level</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Hiring+Source>Hiring Source</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Job+Title>Job Title</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Prior+Experience>Prior Experience</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Qualification+Process>Qualification Process</a>
		</ul>
		<li><a href=/intranet/admin/categories/>HR Skills &amp; Qualifications</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Skill+Type>Skill Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Skill+Weight>Skill Weight</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Operating+System>Operating System</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+LOC+Tool>LOC Tool</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+TM+Tool>TM Tool</a>
		</ul>
		<li><a href=/intranet/admin/categories/>RFQ/RFQ System</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Freelance+RFQ+Status>Freelance RFQ Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Freelance+RFQ+Type>Freelance RFQ Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Freelance+RFQ+Answer+Status>Freelance RFQ Answer Status</a>
	
		</ul>
		<li><a href=/intranet/admin/categories/>Expenses &amp; Travel Costs</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Expense+Type>Expense Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Expense+Payment+Type>Expense Payment Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Finance</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Invoice+Canned+Note>Invoice Canned Note</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Invoice+Payment+Method>Invoice Payment Method</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Invoice+Status>Invoice Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Invoice+Type>Invoice Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Cost+Template>Cost Template</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Payment+Type>Payment Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Materials (Service Types)</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Material+Status>Material Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Material+Type>Material Type</a>
		</ul>
		<li><a href=/intranet/admin/categories/>Forum</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Topic+Status>Forum Topic Status</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Topic+Type>Forum Topic Type</a>
	
		</ul>
		<li><a href=/intranet/admin/categories/>Translation Specific</a>
		<ul>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Quality>Translation Quality</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+File+Type>Translation File Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+Language>Translation Language</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+Quality+Type>Translation Quality Type</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+Subject+Area>Translation Subject Area</a>
			<li><a href=/intranet/admin/categories/index?select_category_type=Intranet+Translation+Task+Status>Translation Task Status</a>
		</ul>
	</ul>
    "
}

# --------------------------------------------------------
# 
# --------------------------------------------------------

ad_proc -public im_navbar_write_tree {
    {-no_cache:boolean}
    {-user_id 0 }
    {-locale "" }
    {-package_key "intranet-core" }
    {-label "main" }
    {-maxlevel 1}
    {-ignore_disabled_p 0}
} {
    Starts writing out the menu tree from a particular location
} {
    if {0 == $user_id} { set user_id [ad_get_user_id] }
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    if {$no_cache_p} {
	return [im_navbar_write_tree_helper \
		    -user_id $user_id \
		    -locale $locale \
		    -package_key $package_key \
		    -label $label \
		    -maxlevel $maxlevel \
		    -ignore_disabled_p $ignore_disabled_p \
	]
    } else {
	return [util_memoize [list im_navbar_write_tree_helper \
				  -user_id $user_id \
				  -locale $locale \
				  -package_key $package_key \
				  -label $label \
				  -maxlevel $maxlevel\
				  -ignore_disabled_p $ignore_disabled_p \
	] 3600]
    }
}

ad_proc -public im_navbar_write_tree_helper {
    -user_id:required
    {-locale "" }
    {-package_key "intranet-core" }
    {-label "main" }
    {-maxlevel 1}
    {-ignore_disabled_p 0}
} {
    Starts writing out the menu tree from a particular location
} {
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    set ignore_disabled_sql ""
    if {$ignore_disabled_p} { set ignore_disabled_sql "OR enabled_p = 'f'" }

    set main_label $label
    set main_menu_id [db_string main_menu "select menu_id from im_menus where label=:label" -default 0]
    set menu_sql "
	select	m.menu_id,
		m.label,
		m.name,
		m.url,
		(select count(*) from im_menus where parent_menu_id = m.menu_id) as sub_count
	from	im_menus m
	where	m.parent_menu_id = :main_menu_id and
		im_object_permission_p(m.menu_id, :user_id, 'read') = 't' and
		(enabled_p is null OR enabled_p = 't' $ignore_disabled_sql)
	order by sort_order
    "

    # Execute SQL first and then iterate through the list in oder to
    # avoid nested SQLs when diving down through multiple recursions
    set html ""
    set menus [db_list_of_lists menus $menu_sql]
    foreach menu_item $menus {

	set menu_id [lindex $menu_item 0]
	set label [lindex $menu_item 1]
	set name [lindex $menu_item 2]
	set url [lindex $menu_item 3]
	set sub_count [lindex $menu_item 4]

	# Localize Name
	regsub -all " " $name "_" name_key
	set name [lang::message::lookup "" "$package_key.$name_key" $name]

	append html "<li><a href=$url>$name</a>\n"
	if {$maxlevel > 0 && $sub_count > 0} {
	    append html "<ul>\n"
	    append html [im_navbar_write_tree -label $label -maxlevel [expr $maxlevel-1]]
	    append html "</ul>\n"
	}
    }
    return $html
}


ad_proc -public im_navbar_sub_tree { 
    {-label "main" }
} {
    Creates an <ul> ...</ul> hierarchical list for
    the admin section
} {
    set user_id [ad_get_user_id]
    set locale [lang::user::locale -user_id $user_id]

    set menu_id [db_string main_menu "select menu_id from im_menus where label=:label" -default 0]
    set menu_list_list [util_memoize "im_sub_navbar_menu_helper -locale $locale $user_id $menu_id" 60]

    set navbar ""
    foreach menu_list $menu_list_list {

	set menu_id [lindex $menu_list 0]
	set package_name [lindex $menu_list 1]
	set label [lindex $menu_list 2]
	set name [lindex $menu_list 3]
	set url [lindex $menu_list 4]
	set visible_tcl [lindex $menu_list 5]

	regsub -all " " $name "_" name_key
	set name [lang::message::lookup "" intranet-core.$name_key $name]
	append navbar "<li><a href=\"$url\">$name</a><ul></ul>"

    }

    return $navbar
}
