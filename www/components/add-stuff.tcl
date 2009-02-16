# /packages/intranet-core/www/admin/components/add-stuff.tcl
#
# Copyright (C) 2006 - 2009 ]project-open[
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

  @author frank.bergmann@project-open.com
} {
    { return_url ""}
    { page_url "" }
}

set user_id [ad_maybe_redirect_for_registration]

set page_title [lang::message::lookup "" intranet-core.Add_Stuff "Add Stuff"]
set context_bar [im_context_bar $page_title]
set context ""

if {"" == $return_url} { set return_url [ad_conn url] }

set component_url "/intranet/admin/menus/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"


# ------------------------------------------------------
# Multirow - No way to format this using list::create...
# ------------------------------------------------------

set page_url_where ""
if {"" != $page_url} { set page_url_where "and c.page_url = :page_url" }

set query "
        select
		c.plugin_id,
                c.plugin_name,
		c.package_name,
                m.location
        from
                im_component_plugin_user_map m,
                im_component_plugins c
        where
                m.plugin_id = c.plugin_id
                and m.user_id = :user_id
                and m.location = 'none'
		$page_url_where
        order by
                lower(c.plugin_name)
"

db_multirow components component_query $query

ad_return_template
