# /www/intranet/partners/primary-contact-delete.tcl

ad_page_contract {
    Removes partner's primary contact

    @param group_id 
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date 4/5/2000

    @cvs-id primary-contact-delete.tcl,v 3.3.2.5 2000/08/16 21:24:57 mbryzek Exp
} {
    group_id:integer
    return_url
}

ad_maybe_redirect_for_registration




db_dml update_partner_to_null \
	"update im_partners
            set primary_contact_id=null
          where group_id=:group_id"

db_release_unused_handles


ad_returnredirect $return_url