# /www/intranet/offices/primary-contact-2.tcl

ad_page_contract {
    stores primary contact id for the office

    @param group_id The group_id of the office.
    @param user_id_from_search The user_id to add as the primary contact.

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id primary-contact-2.tcl,v 3.3.2.5 2000/08/16 21:24:55 mbryzek Exp
} {
    group_id:notnull,integer
    user_id_from_search:notnull,integer
}

set user_id [ad_maybe_redirect_for_registration]

db_dml update_im_facilities \
	"update im_facilities
            set contact_person_id=:user_id_from_search
          where facility_id = (select facility_id 
                              from im_offices where 
                              group_id=:group_id)"

db_release_unused_handles

ad_returnredirect view?[export_url_vars group_id]











