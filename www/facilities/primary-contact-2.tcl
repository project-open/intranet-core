# /www/intranet/facilities/primary-contact-2.tcl

ad_page_contract {
    Stores primary contact id for the facility
    @param facility_id:integer,notnull
    @param user_id_from_search:integer,notnull

    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id primary-contact-2.tcl,v 1.3.2.7 2000/08/16 21:24:52 mbryzek Exp
} {
    
    user_id_from_search:integer,notnull
    facility_id:integer,notnull
}
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


db_dml update_facility \
	"update im_facilities 
            set contact_person_id=:user_id_from_search
          where facility_id=:facility_id" 

db_release_unused_handles

ad_returnredirect view?[export_url_vars facility_id]


