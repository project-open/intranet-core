ad_page_contract {
    Permissions for the subsite itself.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
}

set page_title "Profiles"
set context [list "Permissions"]
set subsite_id [ad_conn subsite_id]
set context_bar [ad_context_bar_ws $page_title]
set url_stub [im_url_with_query]

# The list of Core privileges
set privs [im_core_privs]
# set privs { read write admin }