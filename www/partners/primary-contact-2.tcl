# /www/intranet/partners/primary-contact-2.tcl

ad_page_contract {
    Writes partner's primary contact to the db

    @param group_id 
    @param address_book_id 

    @author mbryzek@arsdigita.com
    @creation-date 4/5/2000

    @cvs-id primary-contact-2.tcl,v 3.3.2.5 2000/08/16 21:24:57 mbryzek Exp
} {
    group_id:integer
    address_book_id:integer
}

ad_maybe_redirect_for_registration




db_dml update_partner \
	"update im_partners
            set primary_contact_id=:address_book_id
          where group_id=:group_id"

db_release_unused_handles


ad_returnredirect view?[export_url_vars group_id]