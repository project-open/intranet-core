# /packages/intranet-core/www/go-search.tcl
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
    Purpose: Standard form to search for a user (through /user-search.tcl)

    @param target Where to link to.
    @param query_string What to search.

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    target
    query_string
}

set user_id [ad_maybe_redirect_for_registration]

set query_string [ad_urlencode $query_string]

switch $target {
    "content" {
	ad_returnredirect "/search/search?sections=im_customers&sections=bboard&sections=im_facilities&sections=im_offices&sections=im_partners&sections=im_projects&sections=static_pages&sections=comments&sections=wp_slides&query_string=$query_string"
    }
    "users" {
	ad_returnredirect "/intranet/user-search?keyword=$query_string"
    }
    "htsearch" {
	ad_returnredirect "/search/search?sections=im_customers&sections=bboard&sections=im_facilities&sections=im_offices&sections=im_partners&sections=im_projects&sections=static_pages&sections=comments&sections=wp_slides&query_string=$query_string"
    }
    "google" {
	ad_returnredirect "http://www.google.com/search?q=$query_string&hl=es"
    }
}

