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
    { office_id:integer 0}
    { object_id:integer 0}
    { view_name "office_view" }
    { return_url ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set td_class(0) "class=roweven"
set td_class(1) "class=rowodd"

if {"" == $return_url} {
#    set return_url [im_url_with_query]
    set return_url "/intranet/offices/index"
}

if {0 == $office_id} {set office_id $object_id}
if {0 == $office_id} {
    ad_return_complaint 1 "<li>You need to specify a office_id"
    return
}

set company_view_page "/intranet/companies/view"
set user_view_page "/intranet/users/view"
set office_new_page "/intranet/offices/new"

# Get the permissions of the curret user on this object
im_office_permissions $user_id $office_id view read write admin
ns_log Notice "offices/view: view=$view, read=$read, write=$write, admin=$admin"

if {!$read} {
    ad_return_complaint 1 "[_ intranet-core.lt_You_dont_have_permiss]"
    return
}

# Check if the invoices was changed outside of ]po[...
im_audit -object_type "im_office" -object_id $office_id -action before_view


# ---------------------------------------------------------------
# Get everything about the office
# ---------------------------------------------------------------

set result [db_0or1row offices_info_query "
select 
	o.*,
	im_category_from_id(office_status_id) as office_status,
	im_category_from_id(office_type_id) as office_type,
	im_name_from_user_id(o.contact_person_id) as contact_person_name,
	im_email_from_user_id(o.contact_person_id) as contact_person_email,
	c.company_id,
	c.company_name
from
	im_offices o
	LEFT OUTER JOIN im_companies c ON (o.company_id = c.company_id)
where
	o.office_id = :office_id
"]

if { $result != 1 } {
    ad_return_complaint "[_ intranet-core.Bad_Office]" "
    <li>[_ intranet-core.lt_We_couldnt_find_offic]"
    return
} else {
    set address_country [db_string get_country_code "select country_name from country_codes where iso=:address_country_code" -default ""]
}


# Set the title now that the $name is available after the db query
set page_title $office_name
set context_bar [im_context_bar [list /intranet/offices/ "[_ intranet-core.Offices]"] $page_title]

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
<input type=\"hidden\" name=\"form:mode\" value=\"[_ intranet-core.display]\" />
<input type=\"hidden\" name=\"form:id\" value=\"[_ intranet-core.office_info]\" />

<table cellpadding=1 cellspacing=1 border=0>
"

set ctr 1
db_foreach column_list_sql $column_sql {
    set column_name [lang::util::suggest_key $column_name]
    if {"" == $visible_for || [eval $visible_for]} {
	append office_html "
        <tr $td_class([expr $ctr % 2])>
          <td>[_ intranet-core.$column_name] &nbsp;
        </td><td>"
	set cmd "append office_html $column_render_tcl"
	eval "$cmd"
	append office_html "</td></tr>\n"
        incr ctr
    }
}

append office_html "
</table>
</form>"

