# /packages/intranet-core/www/admin/permissions/permissions.tcl
#
# Copyright (C) 2004 various parties
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
}

set page_title "[ad_conn instance_name] Permissions"
set context [list "Permissions"]
set subsite_id [ad_conn subsite_id]

# The list of Core privileges
set privs [im_core_privs]
