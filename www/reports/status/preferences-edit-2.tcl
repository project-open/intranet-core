# /www/intranet/preferences-edit-2.tcl

ad_page_contract { 
    Displays the user's preferences for status reports

    @author Michael Pih (pihman@arsdigita.com)
    @creation-date 1 August 2000
    @cvs-id preferences-edit-2.tcl,v 1.1.2.1 2000/08/16 21:28:43 mbryzek Exp

    @param sections A list of status report sections id's to include
    @param offices A list of offices to include in view
    @param projects A list of projects to include in view
    @param customers A list of customers to include in view

} {
    {sections:multiple ""}
    {offices:multiple ""}
    {my_projects_only_p "f"}
    {my_customers_only_p "f"}
}

# make sure the user is logged in
set user_id [ad_maybe_redirect_for_registration]

# default vars
set exception_count 0
set exception_text ""


# get killed_sections from $sections
set sql_query "select sr_section_id from im_status_report_sections"
if { ![empty_string_p $sections] } {
    set sections_csv [join $sections ,]
    append sql_query " where sr_section_id not in ($sections_csv)"
}
set killed_sections [db_list killed_section_id $sql_query]


# get killed_offices from $offices
set sql_query "select imo.group_id as group_id 
               from im_offices imo, user_groups ug
               where imo.group_id = ug.group_id"
if { ![empty_string_p $offices] } {
    set offices_csv [join $offices ,]
    append sql_query " and imo.group_id not in ($offices_csv)" 
}
set killed_offices [db_list killed_office_id $sql_query]


## get killed_projects from $projects
#set sql_query "select imp.group_id as group_id 
#               from im_projects imp, user_groups ug
#               where imp.group_id = ug.group_id
#               and start_date < trunc(sysdate)
#               and end_date > trunc(sysdate)
#               and requires_report_p = 't'"
#if { ![empty_string_p $projects] } {
#    set projects_csv [join $projects ,]
#    append sql_query " and imp.group_id not in ($projects_csv)" 
#}
#set killed_projects [db_list killed_project_id $sql_query]


# get killed_customers from $customers
#set sql_query "select imc.group_id as group_id 
#               from im_customers imc, user_groups ug
#               where imc.group_id = ug.group_id"
#if { ![empty_string_p $customers] } {
#    set customers_csv [join $customers ,]
#    append sql_query " and imc.group_id not in ($customers_csv)" 
#}
#set killed_customers [db_list killed_customer_id $sql_query]




# update the user's status report preferences
db_transaction {
    set sql "select 1
             from im_status_report_preferences
             where user_id = :user_id" 
    set existing_preferences_p \
	    [db_string existing_preferences_p $sql -default 0]

    # if there are existing preferences, we update them
    #  otherwise, we insert the preferences
    if { $existing_preferences_p } {
	set sql "update im_status_report_preferences
                 set killed_sections = :killed_sections,
                 killed_offices = :killed_offices,
                 my_customers_only_p = :my_customers_only_p,
                 my_projects_only_p = :my_projects_only_p
                 where user_id = :user_id"
    } else {
	set sql "insert into im_status_report_preferences
	         (user_id, killed_sections, killed_offices,
                  my_customers_only_p, my_projects_only_p)
                 values
                 (:user_id, :killed_sections, :killed_offices,
                  :my_customers_only_p, :my_projects_only_p)"
    }

    # try the insert or update
    if { [catch {db_dml do_insert_or_update_preferences $sql} err_msg] } {
	incr exception_count
	append exception_text "$err_msg\n"
	ad_return_complaint $exception_count $exception_text
	return
    }
}

db_release_unused_handles

ad_returnredirect preferences-edit
return