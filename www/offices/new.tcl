# /www/intranet/offices/new.tcl

ad_page_contract {
    Adds/edits office information

    @param group_id The group_id of the office.
    @param return_url The url to go to.

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id new.tcl,v 3.14.2.6 2000/09/22 01:38:39 kevin Exp
} {
    group_id:optional,integer
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]

if { [exists_and_not_null group_id] } {
    set caller_group_id $group_id
    set sql_query "
             select 
                  g.group_name, 
                  g.short_name, 
                  o.public_p,
                  o.facility_id
             from 
                  im_offices o, 
                  user_groups g
             where 
                  g.group_id=:caller_group_id
                  and g.group_id=o.group_id(+)"
    db_1row intranet_office_get_group_info $sql_query
    set page_title "Edit office"
    set context_bar [ad_context_bar [list ./ "Offices"] [list "view?group_id=$caller_group_id" "One office"] $page_title]

} else {
    set page_title "Add office"
    set context_bar [ad_context_bar [list ./ "Offices"] $page_title]
    set public_p f
    set caller_group_id [db_string intranet_offices_get_user_group_seq_id "select user_group_sequence.nextval from dual"]
 
    # Information about the user creating this office
    set "dp_ug.user_groups.creation_ip_address" [ns_conn peeraddr]
    set "dp_ug.user_groups.creation_user" $user_id

}

#
# get a list of the available facilities
#
set facility_options ""
set sql_query "select facility_id as fid, facility_name from im_facilities"

db_foreach intranet_offices_get_facility_id_name $sql_query {
    append facility_options "<option value=$fid"
    if { [info exists facility_id] && $facility_id == $fid } {
        append facility_options " selected"
    }
    append facility_options ">$facility_name</option>"   
}

db_release_unused_handles

set page_body "
<form method=post action=new-2>
<input type=hidden name=group_id value=$caller_group_id>
[export_form_vars return_url dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]

<table border=0 cellpadding=3 cellspacing=0 border=0>

<TR>
<TD ALIGN=RIGHT>Office name:</TD>
<TD><INPUT NAME=group_name SIZE=30 [export_form_value group_name] MAXLENGTH=100></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Office short name:</TD>
<TD><INPUT NAME=short_name SIZE=30 [export_form_value short_name] MAXLENGTH=100>
  <font size=-1>(To be used for email aliases/nice urls)</font></TD>

</TR>
<TR>
<TD ALIGN=RIGHT>Facility:</TD>
<TD><SELECT NAME=dp.im_offices.facility_id [export_form_value facility_id]>
<option value=\"\"> -- Please select --
$facility_options
</SELECT>
(<a href=../facilities/new?return_url=[ad_urlencode [im_url_with_query]]>add a facility</a>)
</TD>
</TR>


</TABLE>

<h4>Should this office's information be public?</h4>

<BLOCKQUOTE>
<input type=radio name=dp.im_offices.public_p value=t[util_decode $public_p "t" " checked" ""]> Yes &nbsp;&nbsp;
<input type=radio name=dp.im_offices.public_p value=f[util_decode $public_p "f" " checked" ""]> No
</BLOCKQUOTE>

<p><center><input type=submit value=\"$page_title\"></center>
</form>
"

doc_return  200 text/html [im_return_template]






