# /www/intranet/offices/primary-contact.tcl

ad_page_contract {
    Allows user to choose primary contact for office

    @param group_id The group_id of the office.

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id primary-contact.tcl,v 3.7.2.6 2000/09/22 01:38:39 kevin Exp
} {
    group_id:notnull,integer
}

set user_id [ad_maybe_redirect_for_registration]

# Avoid hardcoding the url stub
set target [ns_conn url]
regsub {primary-contact} $target {primary-contact-2} target

set office_name [db_string intranet_offices_get_office_name \
	"select g.group_name
           from im_offices o, user_groups g
          where o.group_id = :group_id
            and o.group_id=g.group_id" ]

db_release_unused_handles

set page_title "Select primary contact for $office_name"
set context_bar [ad_context_bar [list ./ "Offices"] [list view?[export_url_vars group_id] "One office"] "Select contact"]

set page_body "

Locate your new primary contact by

<form method=get action=/user-search>
[export_form_vars group_id target limit_to_group_id]
<input type=hidden name=passthrough value=group_id>

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

