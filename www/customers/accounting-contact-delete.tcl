# /www/intranet/customers/accounting-contact-delete.tcl

ad_page_contract {
    Removes customer's accounting contact

    @param group_id customer's group id
    @param return_url where to go once we're done

    @author Frank Bergmann (fraber@fraber.de)
    @creation-date Jan 2000

} {
    group_id:integer
    return_url
}

ad_maybe_redirect_for_registration

db_dml customers_delete_accounting_contact \
	"update im_customers
            set accounting_contact_id=null
          where group_id=:group_id" 

db_release_unused_handles

ad_returnredirect $return_url
