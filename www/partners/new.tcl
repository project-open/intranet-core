# /www/intranet/partners/new.tcl
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
    Purpose: Add/edit partner information

    @param group_id
    @param return_url
    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id new.tcl,v 3.9.2.7 2000/09/22 01:38:40 kevin Exp
} {
    { group_id "" }
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]



if { [exists_and_not_null group_id] } {
    db_1row get_group_name \
	    "select g.group_name, g.short_name, p.*
               from im_partners p, user_groups g
              where p.group_id=:group_id
                and p.group_id=g.group_id"
    set page_title "Edit partner"
    set context_bar [ad_context_bar [list ./ "Partners"] [list "view?[export_url_vars group_id]" "One partner"] $page_title]
} else {
    set page_title "Add partner"
    set context_bar [ad_context_bar [list ./ "Partners"] $page_title]
    set "dp_ug.user_groups.creation_ip_address" [ns_conn peeraddr]
    set "dp_ug.user_groups.creation_user" $user_id
    set group_id [db_string get_group_id "select user_group_sequence.nextval from dual"]
    set referral_source ""
}

set page_body "
<form method=post action=new-2>
[export_form_vars return_url group_id dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]

[im_format_number 1] Partner name: 
<br><dd><input type=text size=45 name=dp_ug.user_groups.group_name [export_form_value group_name]>

<p>[im_format_number 2] Partner short name:
<br><dd><input type=text size=45 name=dp_ug.user_groups.short_name [export_form_value short_name]>

<p>[im_format_number 3] Referral Source:
<br><dd><input type=text size=45 name=dp.im_partners.referral_source [export_form_value referral_source]>

<p>[im_format_number 4] Type:
[im_partner_type_select "dp.im_partners.partner_type_id" [value_if_exists partner_type_id]]

<p>[im_format_number 5] Status:
[im_partner_status_select "dp.im_partners.partner_status_id" [value_if_exists partner_status_id]]

<p>[im_format_number 6] Annual Revenue:
[im_category_select "Intranet Annual Revenue" "dp.im_partners.annual_revenue_id" [value_if_exists annual_revenue_id]]

<p>[im_format_number 7] URL:
<br><dd><input type=text size=45 name=dp.im_partners.url [export_form_value url]>

<p>[im_format_number 8] Notes:
<br><dd><textarea name=dp.im_partners.note rows=6 cols=45 wrap=soft>[philg_quote_double_quotes [value_if_exists note]]</textarea>
 
<p><center><input type=submit value=\"$page_title\"></center>
</form>
"



doc_return  200 text/html [im_return_template]






