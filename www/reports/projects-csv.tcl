# /www/intranet/reports/projects-cvs.tcl

ad_page_contract {

    list of current and future employees, their start date, department

    @author teadams@arsdigita.com on May 15
    @creation-date 2000

    @cvs-id projects-csv.tcl,v 1.2.2.6 2000/09/22 01:38:47 kevin Exp
}

set text ""

set query "
select   (select group_name from user_groups where user_groups.group_id = im_projects.group_id) as name, 
         (select project_type from im_project_types where im_projects.project_type_id = im_project_types.project_type_id) as project_type, 
         (select project_status from im_project_status where im_project_status.project_status_id = im_projects.project_status_id) as project_status 
from     im_projects
order by project_type, project_status, name"

db_foreach get_project_info $query {
    append text "\"$name\", \"$project_type\",\"$project_status\"\n\n" 
}

doc_return  200 text $text


