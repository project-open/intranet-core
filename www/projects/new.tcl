# /www/intranet/projects/new.tcl

ad_page_contract {
    Purpose: form to add a new project or edit an existing one
    
    @param project_id group id
    @param parent_id the parent project id
    @param return_url the url to return to
    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id new.tcl,v 3.15.2.12 2000/09/22 01:38:44 kevin Exp
} {
    project_id:optional,integer
    parent_id:optional,integer
    customer_id:optional,integer
    project_nr:optional
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]
set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"

set project_nr_field_size [ad_parameter "ProjectNumberFieldSize" "" 20]

# Make sure the user has the privileges, because this
# pages shows the list of customers etc.
#
if {![im_permission $user_id "add_projects"]} { 
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."
}


# Check if we are editing an already existing project
#
if { [exists_and_not_null project_id] } {
    # We are editing an already existing project
    #
    db_1row projects_info_query { 
select 
	p.parent_id, 
	p.customer_id, 
	p.project_name,
	p.project_type_id, 
	p.project_status_id, 
	p.description,
	p.project_lead_id, 
	p.supervisor_id, 
	p.project_nr,
	p.project_budget, 
	to_char(p.start_date,'YYYY-MM-DD') as start_date, 
	to_char(p.end_date,'YYYY-MM-DD') as end_date, 
	to_char(p.end_date,'HH24:MI') as end_time,
	p.requires_report_p 
from
	im_projects p
where 
	p.project_id=:project_id
}

    set page_title "Edit project"
    set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?[export_url_vars project_id]" "One project"] $page_title]

    if { [empty_string_p $start_date] } { set start_date $todays_date }
    if { [empty_string_p $end_date] } { set end_date $todays_date }
    set button_text "Save Changes"

} else {

    # Calculate the next project number by calculating the maximum of
    # the "reasonably build numbers" currently available

    # A completely new project or a subproject
    #
    if {![info exist project_nr]} {
	set project_nr [im_next_project_nr]
    }
    set start_date $todays_date
    set end_date $todays_date
    set end_time "12:00"
    set billable_type_id ""
    set project_lead_id "5"
    set supervisor_id ""
    set description ""
    set project_budget ""
    set "creation_ip_address" [ns_conn peeraddr]
    set "creation_user" $user_id
    set project_id [im_new_object_id]
    set project_name ""
    set button_text "Create Project"

    if { ![exists_and_not_null parent_id] } {

	# A brand new project (not a subproject)
	set requires_report_p "f"
	set parent_id ""
	if { ![exists_and_not_null customer_id] } {
	    set customer_id ""
	}
	set project_type_id 86
	set project_status_id 76
	set page_title "Add New Project"
	set context_bar [ad_context_bar [list ./ "Projects"] $page_title]

    } else {

	# This means we are adding a subproject.
	# Let's select out some defaults for this page
	db_1row projects_by_parent_id_query {
	    select 
		p.customer_id, 
		p.project_type_id, 
		p.project_status_id
	    from
		im_projects p
	    where 
		p.project_id=:parent_id 
	}

	set requires_report_p "f"
	set page_title "Add subproject"
	set context_bar [ad_context_bar [list ./ "Projects"] [list "view?project_id=$parent_id" "One project"] $page_title]
    }
}

set page_body "
                <form action=new-2.tcl method=POST>
[export_form_vars return_url project_id creation_ip_address creation_user]
                  <table border=0>
                    <tr> 
                      <td colspan=2 class=rowtitle>Project Base Data [im_gif help "To avoid duplicate projects and to determine where the project data are stored on the local file server"]</td>
                    </tr>
                    <tr> 
                      <td>Project Name</td>
                      <td> 
                        <input type=text size=40 name=project_name value=\"$project_name\">
                        [im_gif help "Just enter any suitable name for the project. You can even leave this field blank."]
                      </td>
                    </tr>
                    <tr> 
                      <td>Project # $required_field &nbsp;</td>
                      <td> 
                        <input type=text size=$project_nr_field_size name=project_nr value=\"$project_nr\" maxlength=$project_nr_field_size >
                        [im_gif help "A SLS project number is composed by 4 digits for the year plus plus 4 digits for current identification"] &nbsp; 
                      </td>
                    </tr>
"

# ToDo: The im_project_select shows a "--Please Select--" as the
# choice for "no parent project". We should replace this by a more
# appropriate wording.
#
if {[parameter::get -parameter EnableNestedProjectsP -package_id [ad_acs_kernel_id] -default 1] > 0} {
    append page_body "
                    <tr> 
                      <td>Parent Project &nbsp;</td>
                      <td> 
[im_project_select "parent_id" $parent_id "Open"]
                        [im_gif help "Do you want to create a subproject (a project that is part of an other project)? Leave the field blank (-- Please Select --) if you are unsure."] &nbsp; 
                      </td>
                    </tr>
"
}

append page_body "  
                    <tr>
                      <td>Client $required_field </td>
                      <td> 
[im_customer_select "customer_id" $customer_id "" [list "Deleted" "Past" "Declined"]]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/customers/new'>
	[im_gif new {Add a new client}]</A>"
}

append page_body "
                        <font size=-1>[im_gif help "There is a difference between &quot;Paying Client&quot; and &quot;Final Client&quot;. Here we want to know from whom we are going to receive the money..."]</font> 
                      </td>
                    </tr>
                    <tr> 
                      <td>Project Manager</td>
                      <td> 
[im_employee_select_multiple "project_lead_id" $project_lead_id "" ""]
                      </td>
                    </tr>
                    <tr> 
                      <td>Project Type  $required_field </td>
                      <td> <font size=-1> 
[im_project_type_select "project_type_id" $project_type_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/admin/categories/?select_category_type=Intranet+Project+Type'>
	[im_gif new {Add a new project type}]</A>"
}

append page_body "
                        [im_gif help "General type of project. This allows us to create a suitable folder structure."]</font></td>
                    </tr>
                    <tr> 
                      <td>Project Status $required_field </td>
                      <td>
[im_project_status_select "project_status_id" $project_status_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/admin/categories/?select_category_type=Intranet+Project+Status'>
	[im_gif new {Add a new project status}]</A>"
}

append page_body "
                        [im_gif help "In Process: Work is starting immediately, Potential Project: May become a project later, Not Started Yet: We are waiting to start working on it, Finished: Finished already..."]
                      </td>
                    </tr>\n"


append page_body "
                    <tr> 
                      <td>Start Date $required_field </td>
                      <td> 
[philg_dateentrywidget start $start_date]
                      </td>
                    </tr>

                    <tr> 
                      <td>Delivery Date $required_field </td>
                      <td> 
[philg_dateentrywidget end $end_date]
                      , &nbsp;
                      <INPUT NAME=end_time.time TYPE=text SIZE=8 MAXLENGTH=8 value='$end_time'>
                      </td>
                    </tr>
                    <tr> 
                      <td>Description<br>(publicly searchable) </td>
                      <td> 
                      <textarea NAME=description rows=5 cols=50 wrap=soft>$description</textarea>
                      </td>
                    </tr>

                    <tr> 
                      <td valign=top> 
                        <div align=right>&nbsp; </div>
                      </td>
                      <td> 
                          <p> 
                            <input type=submit value='$button_text' name=submit2>
                            [im_gif help "Create the new folder structure"]
                          </p>
                      </td>
                    </tr>
                  </table>
                </form>
"

# doc_return  200 text/html [im_return_template]

