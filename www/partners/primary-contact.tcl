# /www/intranet/partners/primary-contact.tcl

ad_page_contract {
    Lets you select a primary contact from the group's address book

    @param group_id 

    @author mbryzek@arsdigita.com
    @creation-date 4/5/2000

    @cvs-id primary-contact.tcl,v 3.6.2.7 2000/09/22 01:38:41 kevin Exp
} {
    group_id:integer
}

set user_id [ad_maybe_redirect_for_registration]

set group_name [db_string get_group_name \
	"select g.group_name
           from im_partners p, user_groups g
          where p.group_id = :group_id
            and p.group_id=g.group_id"]

set contact_info ""
set query "select   ab.address_book_id, ab.first_names, ab.last_name, ab.email, ab.email2,
                    ab.line1, ab.line2, ab.city, ab.country, ab.birthmonth, ab.birthyear,
                    ab.phone_home, ab.phone_work, ab.phone_cell, ab.phone_other, ab.notes,
                    ab.usps_abbrev, ab.zip_code
           from     address_book ab
           where    ab.group_id=:group_id
           order by lower(ab.last_name)"

db_foreach get_from_address_book $query {
    set address_book_info [ad_tcl_vars_to_ns_set address_book_id first_names last_name email email2 line1 line2 city country birthmonth birthyear phone_home phone_work phone_cell phone_other notes]
    append contact_info "<p><li>[address_book_display_one_row]</a><br>(<a href=primary-contact-2?[export_url_vars group_id address_book_id]>make primary contact</a>) \n"
}

db_release_unused_handles

set return_url "[im_url_stub]/partners/primary-contact?[export_url_vars group_id]"

if { [empty_string_p $contact_info] } {
    ad_return_error "No contacts listed" "Before you can select a primary contact, you must <a href=/address-book/record-add?scope=group&[export_url_vars group_id return_url]>add at least 1 person to the address book</a>"
    return
}

set page_title "Select primary contact for $group_name"
set context_bar [ad_context_bar [list ./ "Partners"] [list view?[export_url_vars group_id] "One partner"] "Select contact"]

set page_body "
<ul>
$contact_info
</ul>
"


doc_return  200 text/html [im_return_template]

