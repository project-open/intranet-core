# /www/intranet/go-search.tcl

ad_page_contract {
    Purpose: Standard form to search for a user (through /user-search.tcl)

    @param target Where to link to.
    @param query_string What to search.

    @author mbryzek@arsdigita.com
    @creation-date Juny 2002

    @cvs-id $Id$
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

