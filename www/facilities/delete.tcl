# /www/intranet/facilities/delete.tcl

ad_page_contract {
    Offers a confirmation page asking the user if s/he's sure to delete the facility
    @param facility_id
    @author Tony Tseng <tony@arsdigita.com>
    @creation-date 10/26/00
    @cvs-id delete.tcl,v 1.1.2.1 2000/10/30 21:02:31 tony Exp
} {
    facility_id:naturalnum
    return_url:optional
}

#check if the user is an admin
set user_id [ad_verify_and_get_user_id]
if { ![ad_permission_p site_wide "" "" $user_id] } {
    ad_return_forbidden { Access denied } { Since this action involves deleting a user group, you must be a site-wide administrator to perform it. }
    return
}

db_1row get_facility_name {
    select facility_name 
    from im_facilities
    where facility_id=:facility_id
}
db_release_unused_handles
set page_title "Delete facility"
set context_bar [ad_context_bar [list ./ "Facilities"] $page_title]
set office_list {}

db_foreach occupying_office {
    select g.group_name as office_name
    from user_groups g, im_offices o
    where o.facility_id=:facility_id 
    and g.group_id=o.group_id
} {
    lappend office_list "{$office_name}"
}

set office_clause ""
set counter 1
foreach office $office_list {
    if { $counter == 1 } {
	append office_clause [lindex $office 0]
    } elseif { $counter == [llength $office_list] } {
	append office_clause ", and [lindex $office 0]"
    } else {
	append office_clause ", [lindex $office 0]"
    }
    incr counter
}

if { [llength $office_list] == 0 } {
    set page_body "
    <p>
    Are you sure you want to delete $facility_name?
    <form action=\"delete-2\" method=post>
    [export_form_vars facility_id]
    <input type=\"submit\" value=\"Yes\">
    <p>
    "
} elseif { [llength $office_list] == 1 } {
    set page_body "
    <p>
    Currently $office_clause office is occupying $facility_name. 
    <br>
    To remove $facility_name, you must delete or relocate it first.
    <p>
    "
} else {
    set page_body "
    <p>
    Currently $office_clause offices are occupyting $facility_name.
    <br>
    To remove $facility_name, you must delete or relocate them first.
    <p>
    "
}
   

doc_return 200 text/html [im_return_template]
