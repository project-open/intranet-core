# /www/intranet/facilities/index.tcl

ad_page_contract {
    Lists all offices
   
    @author Mark C (markc@arsdigita.com)
    @creation-date May 2000
    @cvs-id index.tcl,v 1.4.2.8 2000/09/22 01:38:36 kevin Exp
} {
}
    
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set results ""
db_foreach facility_selected "select facility_id, facility_name 
                              from im_facilities 
                              order by facility_name" {
    if { [empty_string_p $results] } {
        set results "<ul>"
    }
    append results "  <li> <a href=view?[export_url_vars facility_id]>$facility_name</a>\n"
			      
} 

if { [empty_string_p $results] } {
    set results "  <p><b> There are no facilities </b>\n" 
} else {
    append results "</ul>\n"
}

db_release_unused_handles

set page_title "Facilities"
set context_bar [ad_context_bar $page_title]

set page_body "
$results
<ul>
<li><a href=ae>Add a facility</a>
</ul>
"

append page_body "</ul>\n"

doc_return  200 text/html [im_return_template]







