# /www/intranet/customers/accounting-contact-users-2.tcl

ad_page_contract {
    Allows you to have a accounting contact that references the users
    table. We don't use this yet, but it will indeed be good once all
    customers are in the users table

    @param group_id customer's group id
    @param user_id_from_search user we're setting as the accounting contact

    @author Frank Bergmann (fraber@fraber.de)
    @creation-date Jan 2000
} {
    group_id:integer
    user_id_from_search
}


ad_maybe_redirect_for_registration


db_dml customers_set_accounting_contact \
	"update im_customers 
            set accounting_contact_id=:user_id_from_search
          where group_id=:group_id" 
db_release_unused_handles


ad_returnredirect view?[export_url_vars group_id]










