# /www/intranet/customers/primary-contact.tcl

ad_page_contract {
    Lets you select a primary contact from users assigned to this group

    @param customer_id customer's group id
    @author mbryzek@arsdigita.com
    @author fraber@fraber.de
    @creation-date Jan 2000
    @modification-date July 2003
} {
    customer_id:integer,notnull
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Add primary contact"
set context_bar [ad_context_bar [list /intranet/customers/ "Clients"] $page_title]

set customer_name [db_string customer_name {
select
	c.customer_name
from 
	im_customers c
where
	c.customer_id = :customer_id
}]

set sql "
select
	u.user_id,
	im_name_from_user_id(u.user_id) as name,
	im_email_from_user_id(u.user_id) as email
from
	users u,
	group_member_map m1,
	group_member_map m2
where
	u.user_id=m1.member_id
	and u.user_id=m2.member_id
	and m1.group_id=:customer_id
	and m2.group_id=[im_customer_group_id]
order by lower(name)
"

set contact_info ""
db_foreach address_book_info $sql  {
    append contact_info "<li>$name, $email  </a>(<a href=primary-contact-2?[export_url_vars customer_id user_id]>make primary contact</a>)"
} 

db_release_unused_handles


if { [empty_string_p $contact_info] } {
    set page_body "
<H3>No Client Employees in our Database</H3>
We have no contacts in our database for $customer_name<BR>
<UL>
  <LI>Please create a <A HREF=/intranet/users/new>new client contact</A>.

  <LI>Make the new client contact a <A HREF=/intranet/customers/view?customer_id=$customer_id>customer employee</A> $customer_name.

  <LI>Finally, revisit this page and an option will appear to add the new client contact.

</UL>

Also, please make sure that the client isn't defined multiple with similar names.
"

    doc_return  200 text/html [im_return_template]
    return
}

set return_url "[im_url_stub]/customers/view?[export_url_vars customer_id]"

set page_title "Select primary contact for $customer_name"
set context_bar [ad_context_bar [list ./ "Clients"] [list view?[export_url_vars customer_id] "One customer"] "Select contact"]

set page_body "
<ul>
$contact_info
</ul>
"

doc_return  200 text/html [im_return_template]
