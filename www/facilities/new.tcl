# /www/intranet/facilities/new.tcl

ad_page_contract {
    Adds or edits facility information
    @param facility_id
    @param return_url
    
    @author Mark C (markc@arsdigita.com)
    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date May 2000
    @cvs-id new.tcl,v 1.4.2.10 2000/09/22 01:38:35 kevin Exp
} {
    facility_id:integer,optional
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]

if { [exists_and_not_null facility_id] } {
    set caller_facility_id $facility_id
    db_1row select_facility "select  f.*
                              from im_facilities f
                              where f.facility_id = :facility_id"
    set page_title "Edit facility"
    set context_bar [ad_context_bar [list ./ "Facilities"] [list "view?facility_id=$caller_facility_id" "One facility"] $page_title]

} else {
    set page_title "Add facility"
    set context_bar [ad_context_bar [list ./ "Facilities"] $page_title]
    set public_p f
    set caller_facility_id [db_nextval im_facilities_seq]
 

}

set page_body "
<form method=post action=new-2>
<input type=hidden name=facility_id value=$caller_facility_id>
[export_form_vars return_url dp.im_facilities.creation_ip_address dp.im_facilities.creation_user]

<table border=0 cellpadding=3 cellspacing=0 border=0>

<TR>
<TD ALIGN=RIGHT>Facility name:</TD>
<TD><INPUT NAME=facility_name SIZE=30 [export_form_value facility_name] MAXLENGTH=100></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Phone:</TD>
<TD><INPUT NAME=dp.im_facilities.phone.phone [export_form_value phone] SIZE=14 MAXLENGTH=50></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Fax:</TD>
<TD><INPUT NAME=dp.im_facilities.fax.phone [export_form_value fax] SIZE=14 MAXLENGTH=50></TD>
</TR>

<TR><TD COLSPAN=2><BR></TD></TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>Address:</TD>
<TD><INPUT NAME=dp.im_facilities.address_line1 [export_form_value address_line1]  SIZE=30 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT></TD>
<TD><INPUT NAME=dp.im_facilities.address_line2 [export_form_value address_line2] SIZE=30 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>City:</TD>
<TD><INPUT NAME=dp.im_facilities.address_city [export_form_value address_city] SIZE=30 MAXLENGTH=80></TD>
</TR>


<TR>
<TD VALIGN=TOP ALIGN=RIGHT>State:</TD>
<TD>
"

# checks if address_state is a province
if { [string tolower [value_if_exists address_country_code]] == "us" } {
    set province_value ""
    append page_body "[state_widget [value_if_exists address_state] "dp.im_facilities.address_state"]"
} else {
    set province_value "[value_if_exists address_state]"
    append page_body "[state_widget "" "dp.im_facilities.address_state"]"
}

append page_body "
</TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>Province:<br>(if not in U.S.)</TD>
<TD><input name=province size=30 maxlength=80 value=\"$province_value\"></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>Zip:</TD>
<TD><INPUT NAME=dp.im_facilities.address_postal_code [export_form_value address_postal_code] SIZE=10 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>Country:</TD>
<TD>
[country_widget [value_if_exists address_country_code] "dp.im_facilities.address_country_code"]
</TD>
</TR>

</TABLE>

<H4>Landlord information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_facilities.landlord COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists landlord]]</TEXTAREA>
</BLOCKQUOTE>

<H4>Security information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_facilities.security COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists security]]</TEXTAREA>
</BLOCKQUOTE>

<H4>Other information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_facilities.note COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists note]]</TEXTAREA>
</BLOCKQUOTE>

<P>

<p><center><input type=submit value=\"$page_title\"></center>
</form>
"



doc_return  200 text/html [im_return_template]




