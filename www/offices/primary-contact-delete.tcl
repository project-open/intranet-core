# /www/intranet/offices/primary-contact-delete.tcl

ad_page_contract {
    Removes primary contact from office

    @param group_id The group_id of the office.
    @param return_url The url to go to.

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id primary-contact-delete.tcl,v 3.3.2.5 2000/08/16 21:24:55 mbryzek Exp
} {
    group_id:notnull,integer
    return_url:notnull
}

set user_id [ad_maybe_redirect_for_registration]

set facility_id [db_string intranet_offices_get_facility_id "select facility_id from im_offices where group_id=:group_id"]

db_dml intranet_offices_delete_primary_contace \
	"update im_facilities 
            set contact_person_id=null
          where facility_id=:facility_id"

db_release_unused_handles

ad_returnredirect $return_url
