# /packages/intranet-core/www/admin/testing/redirect.tcl
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
    Test the redirect function.
    Just redirects to /intranet/.
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/" }
}

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

ad_returnredirect $return_url
