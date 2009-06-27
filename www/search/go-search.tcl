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
	if {![im_permission $user_id search_intranet]} {
	    ad_return_complaint 1 "Permission Error:<br>You don't have sufficient privileges to search for Intranet Contents."
	    return
	}
	ad_returnredirect "/intranet-search/search?type=all&q=$query_string"
    }
    "users" {
	if {![im_permission $user_id search_intranet]} {
	    ad_return_complaint 1 "Permission Error:<br>You don't have sufficient privileges to search for Intranet Users."
	    return
	}
	ad_returnredirect "/intranet-search/search?type=user&q=$query_string"
    }
    "htsearch" {
	if {![im_permission $user_id search_intranet]} {
	    ad_return_complaint 1 "Permission Error:<br>You don't have sufficient privileges to search for Intranet Content."
	    return
	}
	ad_returnredirect "/intranet-search/search?type=im_document&q=$query_string"
    }
    "google" {
	ad_returnredirect "http://www.google.com/search?q=$query_string&hl=es"
    }
    default {
	ad_return_complaint 1 "Error:<br>You have chosen to search for target '$target' that doesn't exist."
    }
}

