# /www/intranet/facilities/primary-contact-delete.tcl

ad_page_contract {
    Removes primary contact from facility
    @param facility_id:integer
    @param return_url:notnull

    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id primary-contact-delete.tcl,v 1.2.2.8 2000/08/16 21:24:52 mbryzek Exp
} {
    facility_id:integer,notnull
    return_url:notnull
}
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration



db_dml remove_contact \
	"update im_facilities 
            set contact_person_id=null
          where facility_id=:facility_id"

db_release_unused_handles

ad_returnredirect $return_url

