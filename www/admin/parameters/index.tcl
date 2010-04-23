# /packages/intranet-core/www/admin/parameters/index.tcl
#
# Copyright (C) 2004 ]project-open[
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
  Home page for parameter administration.
  @author frank.bergmann@project-open.com
} {
    { return_url {[ad_conn url]} }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set page_title "Parameters"
set context_bar [im_context_bar $page_title]
set context ""

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

set subsite_name [subsite::get_element -element name]


# ---------------------------------------------------------------
# Flush cache
# ---------------------------------------------------------------

# We flush the cache here, because we want to flush the cache
# _after_ updating parameters. However, we use the OpenACS
# parameter update page, which we can't modify.
# So instead, we flush the cache on this page, where we get
# redirected after the update...

im_permission_flush



# ---------------------------------------------------------------
# Render Module List
# ---------------------------------------------------------------

set sql "
select
	p.package_id,
	p.package_key,
	p.instance_name,
	m.description,
	v.attr_value,
	m.parameter_name
from 
	apm_packages p,
	apm_parameters m,
        apm_parameter_values v
where
	p.package_key = m.package_key
and
        m.parameter_id = v.parameter_id(+)
order by
	p.package_key
"

set old_package_key ""
set ctr 1
set package_html ""
db_foreach packages $sql {
    
    if {![string equal $package_key $old_package_key]} {
	
	append package_html "
	<tr class=rowplain colspan=99><td>&nbsp;</td></tr>
	<tr class=roweven>
	  <td colspan=2>
	    <b><A HREF=/shared/parameters?[export_url_vars package_id return_url]>$package_key</A></b></td>
	  <td><b>$instance_name</b></td>
	</tr>
	"
	
	set old_package_key $package_key
	set ctr 0
    }
    
    if {"" == $parameter_name} { set parameter_name "<i>No parameters</i>" }
    
    append package_html "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>&nbsp;&nbsp;&nbsp;</td>
	  <td><b>$parameter_name</b></td>
	  <td><b>$attr_value</b></td>
	</tr>
    "
    
    if {![string equal description ""]} {
	append package_html "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>&nbsp;&nbsp;&nbsp;</td>
	  <td colspan=3>$description</td>
	</tr>
        "
    }

    incr ctr
}

set parameter_html "
	<table border=0 width=800>
	$package_html
	</table>
"

