# /packages/intranet-core/www/admin/user_matrix/one.tcl
#
# Copyright (C) 2004 various parties
# The code is based on OpenACS 5.0
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
    Permissions for the subsite itself.
    
    @author Lars Pind (lars@collaboraid.biz)
    @author frank.bergmann@project-open.com
} {
    group_id:integer
}

set page_title "[db_string group_name "select group_name from groups where group_id=:group_id"]"
set context [list $page_title]
set subsite_id [ad_conn subsite_id]
set context_bar [im_context_bar $page_title]
set url_stub [im_url_with_query]

set privs { read create write admin }