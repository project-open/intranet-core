ad_page_contract {
    ask user whether they're sure they want to erase their portrait

    @cvs-id erase.tcl,v 1.1.2.4 2000/09/22 01:36:30 kevin Exp
    @param user_id
} {
    user_id:naturalnum,notnull
}

set page_title "Erase Portrait"
set context_bar [ad_context_bar [list "index.tcl" "Your Portrait"] "Erase"]

set page_body "
Are you sure that you want to erase your portrait?

<center>
<form method=POST action=\"erase-2\">
[export_form_vars user_id]
<input type=submit value=\"Yes, I'm sure\">
</form>
</center>
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]
