ad_page_contract {
    Permissions for the subsite itself.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
} {
    group_id:integer
}

set page_title "[db_string group_name "select group_name from groups where group_id=:group_id"]"
set context [list $page_title]
set subsite_id [ad_conn subsite_id]
set context_bar [ad_context_bar $page_title]
set url_stub [im_url_with_query]

set privs { read create write admin }