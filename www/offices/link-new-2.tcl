# /www/intranet/offices/link-new-2.tcl

ad_page_contract {
    Saves changes to links

    @param dp.im_office_links.link_id 
    @param dp.im_office_links.group_id 
    @param dp.im_office_links.url 
    @param dp.im_office_links.link_title 
    @param dp.im_office_links.user_id
    @param dp.im_office_links.active_p 

    @author mbryzek@arsdigita.com
    @creation-date 4/6/2000

    @cvs-id link-new-2.tcl,v 3.2.6.9 2000/08/16 21:24:55 mbryzek Exp
} {
    dp.im_office_links.link_id:integer
    dp.im_office_links.group_id:integer
    {dp.im_office_links.url ""}
    {dp.im_office_links.link_title ""}

    dp.im_office_links.user_id:optional
    {dp.im_office_links.active_p "f"}


}

set user_id [ad_verify_and_get_user_id]


set exception_text ""
set exception_count 0

if { [empty_string_p ${dp.im_office_links.link_title}] } {
    append exception_text "<li> You have to enter a title for the link\n"
    incr exception_count
}

if { [empty_string_p ${dp.im_office_links.url}] } {
    append exception_text "<li> You have to enter a url for the link\n"
    incr exception_count
} elseif { [philg_url_valid_p ${dp.im_office_links.url}] != 1 } {
    append exception_text "<li> Your url doesn't seem to be properly formed.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set form [ns_getform]
ns_set put $form dp.im_office_links.user_id $user_id

dp_process -where_clause "link_id = :link_id"

ad_returnredirect view?group_id=${dp.im_office_links.group_id}




