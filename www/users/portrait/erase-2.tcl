ad_page_contract {
    erase a user's portrait (NULLs out columns in the database)

    the key here is to null out portrait_upload_date, which is used by
    pages to determine portrait existence

    @cvs-id erase-2.tcl,v 1.1.2.3 2000/08/25 23:56:49 minhngo Exp
    @author philg@mit.edu

    @param user_id
} {
    user_id:naturalnum,notnull
    { return_url ""}
}

ad_maybe_redirect_for_registration

db_dml erase_portrait {
   delete from general_portraits
    where on_what_id = :user_id
      and upper(on_which_table) = 'USERS'
}

if {"" == $return_url} {
    set return_url "/intranet/users/view?[export_url_vars user_id]"
}

ad_returnredirect $return_url
