# /www/intranet/customers/primary-contact-2.tcl

ad_page_contract {
    Writes customer's primary contact to the db

    @param customer_id customer's group id
    @param address_book_id id of the address_book record to set as the primary contact

    @author Frank Bergmann (fraber@fraber.de)
    @creation-date Jan 2000

} {
    customer_id:integer,notnull
    user_id:integer,notnull
}

ad_maybe_redirect_for_registration

db_dml customers_set_primary_contact "
update 
	im_customers 
set
	primary_contact_id=:user_id
where
	customer_id=:customer_id" 

db_release_unused_handles

ad_returnredirect view?[export_url_vars customer_id]