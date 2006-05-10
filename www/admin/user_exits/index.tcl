ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-05
    @cvs-id $Id$

} {

}

# ******************************************************
# Default & Security
# ******************************************************

set page_title "Widgets"
set context_bar [im_context_bar [list /intranet-dynfield/ "DynField"] $page_title]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ******************************************************
# Create the list of Widgets
# ******************************************************

set query "
	select	*,
		im_category_from_id(storage_type_id) as storage_type
	from im_dynfield_widgets
"

db_multirow widgets widgets_query $query


ad_return_template
