# /packages/intranet-core/www/admin/cleanup-audits/index.tcl
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
    Cleanup big tables in the DB
    @author frank.bergmann@project-open.com
} {
    {audit_object_type ""}
    {limit 1000}
    {iterations 10}
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Cleanup Audits"
set context_bar [im_context_bar $page_title]
set context ""
set return_url [im_url_with_query]

# ------------------------------------------------------
# 
# ------------------------------------------------------

set tables_html [im_ad_hoc_query -format html "
	SELECT	nspname || '.' || relname AS relation,
		'<div align=right>'||pg_size_pretty(pg_total_relation_size(c.oid))||'</div>' AS total_size
	FROM	pg_class c
		LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
	WHERE	nspname NOT IN ('pg_catalog', 'information_schema') AND 
		c.relkind <> 'i' AND 
		nspname !~ '^pg_toast'
	ORDER BY
		pg_total_relation_size(c.oid) DESC
	LIMIT 20
"]

set audit_del_url [export_vars -base "/intranet/admin/cleanup-audits/delete-audits" {return_url limit iterations}]

set audits_html [im_ad_hoc_query -format html "
	select	count(*) as cnt,
		object_type,
		'<a href=$audit_del_url&object_type='||object_type||' class=button>Delete $iterations x $limit</a>' as action
	from	im_audits a,
		acs_objects o
	where	a.audit_object_id = o.object_id
	group by object_type
	order by cnt DESC
	LIMIT 20
"]

