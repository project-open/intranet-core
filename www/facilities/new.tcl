# /www/intranet/facilities/new.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Adds or edits office information
    @param office_id
    @param return_url
    
    @author Mark C (markc@arsdigita.com)
    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date May 2000
    @cvs-id new.tcl,v 1.4.2.10 2000/09/22 01:38:35 kevin Exp
} {
    office_id:integer,optional
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]

if { [exists_and_not_null office_id] } {
    set caller_office_id $office_id
    db_1row select_office "select  f.*
                              from im_offices f
                              where f.office_id = :office_id"
    set page_title "Edit office"
    set context_bar [ad_context_bar [list ./ "Offices"] [list "view?office_id=$caller_office_id" "One office"] $page_title]

} else {
    set page_title "Add office"
    set context_bar [ad_context_bar [list ./ "Offices"] $page_title]
    set public_p f
    set caller_office_id [db_nextval im_offices_seq]
 

}

set page_body "
<form method=post action=new-2>
<input type=hidden name=office_id value=$caller_office_id>
[export_form_vars return_url dp.im_offices.creation_ip_address dp.im_offices.creation_user]

<table border=0 cellpadding=3 cellspacing=0 border=0>

<TR>
<TD ALIGN=RIGHT>Office name:</TD>
<TD><INPUT NAME=office_name SIZE=30 value=\"$office_name\" MAXLENGTH=100></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Phone:</TD>
<TD><INPUT NAME=dp.im_offices.phone.phone value=\"$phone\" SIZE=14 MAXLENGTH=50></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Fax:</TD>
<TD><INPUT NAME=dp.im_offices.fax.phone value=\"$fax\" SIZE=14 MAXLENGTH=50></TD>
</TR>

<TR><TD COLSPAN=2><BR></TD></TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>Address:</TD>
<TD><INPUT NAME=dp.im_offices.address_line1 value=\"$address_line1\"  SIZE=30 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT></TD>
<TD><INPUT NAME=dp.im_offices.address_line2 value=\"$address_line2\" SIZE=30 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>City:</TD>
<TD><INPUT NAME=dp.im_offices.address_city value=\"$address_city\" SIZE=30 MAXLENGTH=80></TD>
</TR>


<TR>
<TD VALIGN=TOP ALIGN=RIGHT>State:</TD>
<TD>
"

# checks if address_state is a province
if { [string tolower [value_if_exists address_country_code]] == "us" } {
    set province_value ""
    append page_body "[state_widget [value_if_exists address_state] "dp.im_offices.address_state"]"
} else {
    set province_value "[value_if_exists address_state]"
    append page_body "[state_widget "" "dp.im_offices.address_state"]"
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
<TD><INPUT NAME=dp.im_offices.address_postal_code value=\"$address_postal_code\" SIZE=10 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>Country:</TD>
<TD>
[country_widget [value_if_exists address_country_code] "dp.im_offices.address_country_code"]
</TD>
</TR>

</TABLE>

<H4>Landlord information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_offices.landlord COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists landlord]]</TEXTAREA>
</BLOCKQUOTE>

<H4>Security information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_offices.security COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists security]]</TEXTAREA>
</BLOCKQUOTE>

<H4>Other information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_offices.note COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists note]]</TEXTAREA>
</BLOCKQUOTE>

<P>

<p><center><input type=submit value=\"$page_title\"></center>
</form>
"



doc_return  200 text/html [im_return_template]




