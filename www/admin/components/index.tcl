# /packages/intranet-core/www/admin/categories/index.tcl
#
# Copyright (C) 2004 Project/Open
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
  Home page for component administration.

  @author alwin.egger@gmx.net
} {
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set page_title "Components"
set context_bar [ad_context_bar $page_title]
set context ""

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

# Render Component List

set component_list_html "
<table border=0>
<tr>
  <td class=rowtitle>Package</td>
  <td class=rowtitle>Name</td>
  <td class=rowtitle>Location</td>
  <td class=rowtitle>URL</td>
  <td class=rowtitle>&nbsp;</td>
</tr>"

# Generate the sql query
set criteria [list]
set bind_vars [ns_set create]

set component_select_sql "
select
	c.plugin_id, c.plugin_name, c.package_name, c.location, c.page_url
from 
	im_component_plugins c
order by
	package_name,
	plugin_name
"

set ctr 1
db_foreach all_component_of_type $component_select_sql {

append component_list_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>$plugin_name</td>
  <td>$package_name</td>
  <td>$location</td>
  <td>$page_url</td>
  <td><a href=\"edit.tcl?[export_url_vars plugin_id]\">change</a></td>
</tr>"
    incr ctr
}

append component_list_html "</table>"

