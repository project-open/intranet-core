# /packages/intranet-core/www/intranet/spam/cancel.tcl
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
    Purpose: Cancels action to send spam

    @param return_url The url to go to.

    @author mbryzek@arsdigita.com
    @frank.bergmann@project-open.com
} {
    {return_url [im_url_stub]}
}

ad_returnredirect $return_url
