# /www/intranet/facilities/primary-contact.tcl

ad_page_contract {
    Allows user to choose primary contact for facility
    @param limit_to_users_in_group_id:integer
    @param facility_id:integer
   
    @author: Mike Bryzek (mbrysek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id primary-contact.tcl,v 1.5.2.15 2000/09/22 01:38:36 kevin Exp
} {
    limit_to_users_in_group_id:integer,optional
    facility_id:integer
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# Avoid hardcoding the url stub
set target [ns_conn url]
regsub {primary-contact} $target {primary-contact-2} target



set facility_name [db_string facility_name \
	"select facility_name from im_facilities where facility_id = :facility_id"]

db_release_unused_handles

set page_title "Select primary contact for $facility_name"
set context_bar [ad_context_bar [list ./ "Facilities"] [list view?[export_url_vars facility_id] "One facility"] "Select contact"]

set page_body "

Locate your new primary contact by

<form method=get action=/user-search>
[export_form_vars facility_id target limit_to_group_id]
<input type=hidden name=passthrough value=facility_id>

<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value=Search>
</center>
</form>

"

doc_return  200 text/html [im_return_template]

