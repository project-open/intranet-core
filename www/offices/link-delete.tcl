# /www/intranet/offices/link-delete.tcl

ad_page_contract {
    Deletes a link

    @param group_id The group from which to delete the link.
    @param link_id The link to delete.

    @author mbryzek@arsdigita.com
    @creation-date 4/6/2000

    @cvs-id link-delete.tcl,v 3.2.6.5 2000/08/16 21:24:55 mbryzek Exp
} {
    group_id:notnull,integer
    link_id:notnull,integer
}


db_dml intranet_offices_delete_office_link "delete from im_office_links where link_id=:link_id"

db_release_unused_handles

ad_returnredirect view?[export_url_vars group_id]
