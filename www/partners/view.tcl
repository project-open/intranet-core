# /www/intranet/partners/view.tcl
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
    Purpose: Lists info about one partner

    @param group_id user GROUP ID

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id view.tcl,v 3.15.2.8 2000/09/22 01:38:41 kevin Exp
} {
    group_id:integer
}


set user_id [ad_maybe_redirect_for_registration]

set return_url [im_url_with_query]



# We need to know if the user belongs to the group to be able to do things
# through scoping. If not, we add an intermedia page to ask the user if s/he
# wants to join the group before continuing
set user_belongs_to_group_p [ad_user_group_member $group_id $user_id]


# Admins and Employees can administer partners
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if { $user_admin_p == 0 } {
    set user_admin_p [im_user_is_employee_p $user_id]
}

# set user_admin_p [im_can_user_administer_group $group_id $user_id]

if { $user_admin_p > 0 } {
    # Set up all the admin stuff here in an array
    set admin(basic_info) "  <p><li> <a href=ae?[export_url_vars group_id return_url]>Edit this information</a>"
    set admin(contact_info) "<p><li><a href=[im_group_scope_url $group_id $return_url "/address-book/record-add.tcl" $user_belongs_to_group_p]>Add a contact</a>"
} else {
    set admin(basic_info) ""
    set admin(contact_info) ""
}

if {![db_0or1row get_group \
	"select g.group_name, g.registration_date, g.modification_date, p.note, p.url, g.short_name,
                nvl(t.partner_type,'&lt;-- not specified --&gt;') as partner_type,
                nvl(s.partner_status,'&lt;-- not specified --&gt;') as partner_status,
                nvl(im_category_from_id(annual_revenue_id),'&lt;-- not specified --&gt;') as annual_revenue,
                nvl(referral_source,'&lt;-- not specified --&gt;') as referral_source,
                ab.first_names||' '||ab.last_name as primary_contact_name, p.primary_contact_id
	   from user_groups g, im_partners p, im_partner_types t, im_partner_status s, address_book ab
	  where g.group_id=:group_id
	    and g.group_id=p.group_id
	    and p.partner_type_id=t.partner_type_id(+)
	    and p.partner_status_id=s.partner_status_id(+)
and p.primary_contact_id=ab.address_book_id(+)"]} {
    ad_return_complaint 1 "Can't find the partner with group id of $group_id"
    return
}

set page_title $group_name
set context_bar [ad_context_bar [list ./ "Partners"] "One partner"]

set primary_contact_text ""
if { [empty_string_p $primary_contact_id] } {
    if { $user_admin_p } {
	set primary_contact_text "<a href=primary-contact?[export_url_vars group_id limit_to_users_in_group_id]>Add primary contact</a>\n"
    } else {
	set primary_contact_text "<i>none</i>"
    }
} else {

    append primary_contact_text "<a href=[im_group_scope_url $group_id $return_url "/address-book/record.tcl?address_book_id=$primary_contact_id"]>$primary_contact_name</a>"
    
    if { $user_admin_p } {
	append primary_contact_text "    (<a href=primary-contact?[export_url_vars group_id limit_to_users_in_group_id]>change</a> |
	<a href=primary-contact-delete?[export_url_vars group_id return_url]>remove</a>)\n"
    }
}

set left_column "
<ul> 
  <li> Type: $partner_type
  <li> Status: $partner_status
  <li> Primary contact: $primary_contact_text
  <li> Added on [util_AnsiDatetoPrettyDate $registration_date]
  <li> Referral source: $referral_source
  <li> Annual Revenue: $annual_revenue
[im_email_aliases $short_name]
" 

if { ![empty_string_p $url] } {
    set url [im_maybe_prepend_http $url]
    append left_column "  <li> URL: <a href=\"$url\">$url</a>\n"
}

if { ![empty_string_p $modification_date] } {
    append left_column "  <li> Last modified on [util_AnsiDatetoPrettyDate $modification_date]\n"
}

if { ![empty_string_p $note] } {
    append left_column "  <li> Notes: <font size=-1>$note</font>\n"
}


append left_column "
$admin(basic_info)
</ul>
"



# Print out the address book
set contact_info ""

set query "select   ab.address_book_id, ab.first_names, ab.last_name, ab.email, ab.email2,
                    ab.line1, ab.line2, ab.city, ab.country, ab.birthmonth, ab.birthyear,
                    ab.phone_home, ab.phone_work, ab.phone_cell, ab.phone_other, ab.notes,
                    ab.usps_abbrev, ab.zip_code
           from     address_book ab
           where    ab.group_id=:group_id
           order by lower(ab.last_name)"

db_foreach get_contact_info $query {
    set address_book_info [ad_tcl_vars_to_ns_set address_book_id first_names last_name email email2 line1 line2 city country birthmonth birthyear phone_home phone_work phone_cell phone_other notes usps_abbrev zip_code]
    append contact_info "<p><li>[address_book_display_one_row]\n"
    if { $user_admin_p > 0 } {
	append contact_info "
<br>
\[<a href=[im_group_scope_url $group_id $return_url "/address-book/record-edit?[export_url_vars address_book_id]" $user_belongs_to_group_p]>edit</a> | 
<a href=[im_group_scope_url $group_id $return_url "/address-book/record-delete?[export_url_vars address_book_id]" $user_belongs_to_group_p]>delete</a>\]
"
    }
} 

if { [empty_string_p $contact_info] } {
    set contact_info "  <li> <i>None</i>\n"
}

append left_column "
<b>Contact Information</b>
<ul>
$contact_info
$admin(contact_info)
</ul>

<em>Contact correspondence and strategy reviews:</em>
[ad_general_comments_summary $group_id user_groups $group_name]
<ul>
<p><a href=\"/general-comments/comment-add?group_id=$group_id&scope=group&on_which_table=user_groups&on_what_id=$group_id&item=[ns_urlencode $group_name]&module=intranet&[export_url_vars return_url]\">Add a correspondance</a>
</ul>

"

set page_body "
<table width=100% cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
$left_column
  </td>
  <td valign=top>
[im_table_with_title "[ad_parameter SystemName] Employees" "<ul>[im_group_member_component $group_id $user_id "are working with $group_name" $user_admin_p $return_url [im_employee_group_id]]</ul>"]
  </td>
</tr>
</table>

"


doc_return  200 text/html [im_return_template]





