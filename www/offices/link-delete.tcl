# /packages/intranet-core/www/offices/link-delete.tcl
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
    Deletes a link

    @param group_id The group from which to delete the link.
    @param link_id The link to delete.

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    group_id:notnull,integer
    link_id:notnull,integer
}


db_dml intranet_offices_delete_office_link "delete from im_office_links where link_id=:link_id"

db_release_unused_handles

ad_returnredirect view?[export_url_vars group_id]
