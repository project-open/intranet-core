# /www/intranet/reports/index.tcl

ad_page_contract {
    this is just a quick and dirty index page for now with links to the reports..
    I will add some info to this page (subset of status report)

    @author teadams
    @cvs-id index.tcl,v 1.11.2.6 2000/09/22 01:38:46 kevin Exp
} {
}

set user_id [ad_maybe_redirect_for_registration]

set team_list [db_list_of_lists team_list_statement  "select group_name,group_id
                                                      from user_groups 
                                                      where parent_group_id = [im_team_group_id]"]

set office_list [db_list_of_lists office_list_statement "select group_name,group_id
                                                         from user_groups 
                                                         where parent_group_id = [im_office_group_id]"]

db_release_unused_handles

set context_bar [ad_context_bar "Reports"]

set return_html "
[im_header "Reports Main Page"]

<h4>Company reports</h4>
<ul>
<li><a href=status/>Company status report</a>
<li><a href=payments>Payments Report</a> 
<li><a href=department-report>Department Report</a>
<li><a href=utilization>Utilization Report</a>
</ul>

<h4>Teams</h4>
<ul>"

foreach team_name_id_pair $team_list {
    set team_name [lindex $team_name_id_pair 0]
    set group_id [lindex $team_name_id_pair 1]

    append return_html "<li><a href=/admin/ug/group?[export_url_vars group_id]>$team_name</a>
<ul>
<li><a href=[im_url_stub]/employees/index?[export_url_vars group_id]>Employee listing - contact information</a>
<li><a href=[im_url_stub]/employees/admin/index?[export_url_vars group_id]>Employee listing</a> (admin view)
<li><a href=[im_url_stub]/employees/admin/bulk-edit?[export_url_vars group_id]>Bulk edit</a>
<li><a href=[im_url_stub]/allocations/one-group-one-month?[export_url_vars group_id]>Allocations</a>
</ul>"
}

append return_html "
</ul>
</h4>Offices</h4>
<ul>"

foreach office_name_id_pair $office_list {
    set office_name [lindex $office_name_id_pair 0]
    set group_id [lindex $office_name_id_pair 1]
    append return_html "<a href=[im_url_stub]/offices/view?[export_url_vars group_id]>$office_name</a>
<ul>
<li><a href=[im_url_stub]/employees/index?[export_url_vars group_id]>Employee listing - contact information
<li><a href=[im_url_stub]/employees/admin/index?[export_url_vars group_id]>Employee listing</a> (admin view)
<li><a href=[im_url_stub]/employees/admin/bulk-edit?[export_url_vars group_id]>Bulk edit</a>
<li><a href=[im_url_stub]/allocations/one-group-one-month?[export_url_vars group_id]>Allocations</a>
</ul>"
}

append return_html "
</ul>
<h4>Employee tracking</h4>
<ul>
<li><a href=[im_url_stub]/employees/admin/pipeline-list>Employee Recruiting Pipeline</a> - potential hires we are seriously looking at and their state
<li><a href=report>Employment Tracking</a> - # of employees over time meeting various criteria
<li><a href=checkpoint-progress>Checkpoint Progress Report</a> - Employees missing checkpoints in our process
<li><a href=termination-list>Termination Report</a>
</ul>

<h4>Data quality</h4>
<ul>
<li><a href=exception-missing-info>Missing Information Report</a> - Employees missing key information
<li><a href=missing-group>Missing Team/Office Report</a> - Employees who are not in at least one team or office
<li><a href=multiple-group>Multiple Team/Office Report</a> - Employees who are in more than one team and office and it is not clear which is their primary.
</ul>

<h4>CVS export</h4>
<ul>
<li><a href=employees-csv>Employees</a>
<li><a href=projects-csv>Projects</a>
</ul>

<h4>Miscellaneous</h4>
<ul>
<li><a href=birthdays>Employee Birthdays</a>
<li><a href=projects-bulk-edit-billable> Billable Projects</a> - Define which projects are billable
</ul>

[im_footer]"
doc_return  200 text/html $return_html
