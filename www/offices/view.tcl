# /packages/intranet-core/www/offices/view.tcl
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
    Display information about one office

    @author unknown@arsdigita.com
    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com
} {
    office_id:integer
    { view_name "office_view" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set td_class(0) "class=roweven"
set td_class(1) "class=rowodd"

set customer_view_page "/intranet/customers/view"
set user_view_page "/intranet/users/view"
set office_new_page "/intranet/offices/new"

# Get the permissions of the curret user on this object
im_office_permissions $user_id $office_id view read write admin

if {!$read} {
    ad_return_complaint 1 "You don't have permissions to view this page"
    return
}

# ---------------------------------------------------------------
# Get everything about the office
# ---------------------------------------------------------------

set result [db_0or1row offices_info_query "
select 
	o.*,
	im_category_from_id(office_status_id) as office_status,
	im_category_from_id(office_type_id) as office_type,
	cc.country_name as address_country_name,
	im_name_from_user_id(o.contact_person_id) as contact_person_name,
	im_email_from_user_id(o.contact_person_id) as contact_person_email,
	c.customer_id,
	c.customer_name,
	cc.country_name as address_country
from
	im_offices o,
	im_customers c,
	country_codes cc
where
	o.office_id = :office_id
	and o.office_id = c.main_office_id(+)
	and o.address_country_code = cc.iso(+)
"]

if { $result != 1 } {
    ad_return_complaint "Bad Office" "
    <li>We couldn't find office #$office_id; perhaps this office was nuked?"
    return
}


# Set the title now that the $name is available after the db query
set page_title $office_name
set context_bar [ad_context_bar [list /intranet/offices/ "Offices"] $page_title]

# ---------------------------------------------------------------
# Show Basic Office Information
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#
set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name"]

set column_sql "
select
	column_name,
	column_render_tcl,
	visible_for
from
	im_view_columns
where
	view_id=:view_id
	and group_id is null
order by
	sort_order"


set office_html "
<form method=POST action=\"$office_new_page\">
[export_form_vars office_id return_url]
<input type=\"hidden\" name=\"form:mode\" value=\"display\" />
<input type=\"hidden\" name=\"form:id\" value=\"office_info\" />

<table cellpadding=1 cellspacing=1 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>Office Information</td>
  </tr>
"

set ctr 1
db_foreach column_list_sql $column_sql {
    if {[eval $visible_for]} {
	append office_html "
        <tr $td_class([expr $ctr % 2])>
          <td>$column_name &nbsp;
        </td><td>"
	set cmd "append office_html $column_render_tcl"
	eval $cmd
	append office_html "</td></tr>\n"
        incr ctr
    }
}

append office_html "
</table>
</form>"

