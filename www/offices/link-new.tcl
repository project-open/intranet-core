# /www/intranet/offices/link-new.tcl

ad_page_contract {
    Adds/edits an office link

    @param group_id The group id to add a link to.
    @param link_id If this exists, then edit this link.    

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id link-new.tcl,v 3.6.2.7 2000/09/22 01:38:39 kevin Exp
} {
    group_id:notnull,integer
    { link_id:integer "" }
}

set user_id [ad_maybe_redirect_for_registration]

# link_id specified if we're editing a link

if { [exists_and_not_null link_id] } {
    set sql_query "select link_id, group_id, user_id, url, link_title, active_p from im_office_links where link_id=:link_id"
    db_1row intranet_offices_get_link_info $sql_query

    set page_title "Edit link"
    set delete_link "  <ul><li><a href=link-delete?[export_url_vars link_id group_id]>Delete this link</a></ul>"

} else {
    set active_p t
    set url "http://"
    set page_title "Add link"
    set link_id [db_string intranet_offices_get_link_id "select im_office_links_seq.nextval from dual"]
}

set office_name [db_string intranet_offices_get_office_name "select group_name from user_groups where group_id=:group_id" ]
append page_title " for $office_name"

db_release_unused_handles

set context_bar [ad_context_bar [list ./ "Offices"] [list "view?[export_url_vars group_id]" "One office"] $page_title]

set page_body "
<form method=post action=link-new-2>
<input type=hidden name=dp.im_office_links.link_id value=$link_id>
<input type=hidden name=dp.im_office_links.group_id value=$group_id>

<table border=0 cellpadding=3 cellspacing=0 border=0>

<TR>
<TD ALIGN=RIGHT>Link title:</TD>
<TD><INPUT NAME=dp.im_office_links.link_title SIZE=50 [export_form_value link_title] MAXLENGTH=100></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Link URL:</TD>
<TD><INPUT NAME=dp.im_office_links.url SIZE=50 [export_form_value url] MAXLENGTH=300></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Is this link active?</TD>
<TD>
<input type=radio name=dp.im_office_links.active_p value=t[util_decode $active_p t " checked" ""]> Yes &nbsp;&nbsp;
<input type=radio name=dp.im_office_links.active_p value=f[util_decode $active_p f " checked" ""]> No
</td>
</TR>

</table>

<p><center><input type=submit value=\"$page_title\"></center>
</form>
[value_if_exists delete_link]
"

doc_return  200 text/html [im_return_template]
