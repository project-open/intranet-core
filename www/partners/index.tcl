# /www/intranet/partners/index.tcl
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
    Purpose: Lists all partners with dimensional sliders

    @param type_id
    @param order_by
    @param status_id
    @param view_type
    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id index.tcl,v 3.15.2.8 2000/09/22 01:38:40 kevin Exp
} {
    { type_id:integer "" }
    { order_by "" }
    { status_id "" }
    { view_type "" }
}

# optional: type_id

set user_id [ad_maybe_redirect_for_registration]

if { ![exists_and_not_null order_by] } {
    set order_by "Partner"
}
if { ![exists_and_not_null type_id] } {
    set type_id 0
}
if { ![exists_and_not_null status_id] } {
    set status_id 0
}
if { ![exists_and_not_null view_type] } {
    set view_type "all"
}
set view_types [list "mine" "Mine" "all" "All" "unassigned" "Unassigned"]

# status_types will be a list of pairs of (partner_type_id, partner_status)
set partner_types [im_memoize_list select_partner_types \
	"select partner_type_id, partner_type
           from im_partner_types
          order by lower(partner_type)"]
lappend partner_types 0 All


# status_types will be a list of pairs of (partner_status_id, partner_status)
set status_types [im_memoize_list select_partner_status \
	"select partner_status_id, partner_status
           from im_partner_status
          order by lower(partner_status)"]
lappend status_types 0 All


# Now let's generate the sql query
set criteria [list]



if { ![empty_string_p $type_id] && $type_id != 0 } {
    lappend criteria "p.partner_type_id=:type_id"
}

if { ![empty_string_p $status_id] && $status_id != 0 } {
    lappend criteria "p.partner_status_id=:status_id"
}

set extra_tables [list]
if { [string compare $view_type "mine"] == 0 } {
    lappend criteria "ad_group_member_p ( :user_id, g.group_id ) = 't'"
} elseif { [string compare $view_type "unassigned"] == 0 } {
    lappend criteria "not exists (select user_group_map.group_id from user_group_map where user_group_map.group_id = g.group_id)"
}

set order_by_clause ""
switch $order_by {
    "Partner" { set order_by_clause "order by upper(group_name)" }
    "Type" { set order_by_clause "order by upper(partner_type), upper(group_name)" }
    "Status" { set order_by_clause "order by upper(partner_status), upper(group_name)" }
    "URL" { set order_by_clause "order by upper(url), upper(group_name)" }
    "Contact" { set order_by_clause "order by upper(name), upper(group_name)" }
}

set extra_table ""
if { [llength $extra_tables] > 0 } {
    set extra_table ", [join $extra_tables ","]"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set page_title "Partners"
set context_bar [ad_context_bar $page_title]


set query "select p.*, g.group_name, t.partner_type, s.partner_status,
                ab.last_name||', '||ab.first_names as name, ab.email, ab.phone_work
           from user_groups g, im_partners p, im_partner_types t, im_partner_status s, address_book ab $extra_table
          where p.group_id = g.group_id
            and p.partner_type_id=t.partner_type_id(+) 
            and p.primary_contact_id=ab.address_book_id(+)
            and p.partner_status_id=s.partner_status_id(+) $where_clause $order_by_clause"
            

set results ""
set bgcolor(0) " bgcolor=\"[ad_parameter TableColorOdd Intranet white]\""
set bgcolor(1) " bgcolor=\"[ad_parameter TableColorEven Intranet white]\""
set ctr 0
db_foreach get_group $query {
    if { [empty_string_p $url] } {
	set url "&nbsp;"
    } else {
	set url "<a href=\"[im_maybe_prepend_http $url]\">[im_maybe_prepend_http $url]</a>"
    }
    append results "
<tr$bgcolor([expr $ctr % 2])>
  <td valign=top><a href=view?[export_url_vars group_id]>$group_name</a></td>
  <td valign=top>[util_decode $partner_type "" "&nbsp;" $partner_type]</td>
  <td valign=top>[util_decode $partner_status "" "&nbsp;" $partner_status]</td>
  <td valign=top>$url</td>
"
    if { [string compare $name ", "] == 0 } {
	set prim_contact "&nbsp;"
    } else {
	set prim_contact "$name[util_decode $email "" "" ", <a href=mailto:$email>$email</a>"][util_decode $phone_work "" "" ", $phone_work"]"
    }
    append results "
  <td valign=top>$prim_contact</td>
</tr>
"
    incr ctr
}


if { [empty_string_p $results] } {
    set results "<ul><li><b> There are currently no partners</b></ul>\n"
} else {
    set column_headers [list Partner Type Status URL Contact]
    set url "index.tcl"
    set query_string [export_ns_set_vars url [list order_by]]
    if { [empty_string_p $query_string] } {
	append url "?"
    } else {
	append url "?$query_string&"
    }
    set table "
<table width=100% cellpadding=1 cellspacing=2 border=0>
<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
"
    foreach col $column_headers {
	if { [string compare $order_by $col] == 0 } {
	    append table "  <th>$col</th>\n"
	} else {
	    append table "  <th><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></th>\n"
	}
    }
    set results "
<br>
$table
</tr>
$results
</table>
"
}




set page_body "
<table border=0 cellspacing=0 cellpadding=0>
  <tr>
    <td valign=top><font size=-1>
           View:
    </font></td>
    <td valign=top><font size=-1>
           [im_slider view_type $view_types]
    </font></td>
  </tr>
  <tr>
    <td valign=top><font size=-1>
           Partner status: 
    </font></td>
    <td valign=top><font size=-1>
           [im_slider status_id $status_types]
    </font></td>
  </tr>
  <tr>
    <td valign=top><font size=-1>
           Partner type:
    </font></td>
    <td valign=top><font size=-1>
           [im_slider type_id $partner_types]
    </font></td>
  </tr>
</table>

<p>
$results

<p><a href=ae>Add a partner</a>
"



 
doc_return  200 text/html [im_return_template]


