# /www/intranet/offices/index.tcl

ad_page_contract {

    Lists all offices
    Last Change:
    Added number of employees in parentheses after the office names
    May 3, 2000
    @param none
    @author Mark Dettinger <dettinger@arsdigita.com>
    @creation-date 

    @cvs-id index.tcl,v 3.17.2.7 2000/09/22 01:38:39 kevin Exp
} {}

set user_id [ad_maybe_redirect_for_registration]

set sql_query \
	"select ug.group_id, ug.group_name, nvl(o.public_p,'f') as public_p, 
                nvl(number_users,0) as office_size
           from user_groups ug, im_offices o, 
             --- create a view that has at least one row per office   
             (select count(*) as number_users, o.group_id
                from im_offices o, im_employees_active emp
               where ad_group_member_p(emp.user_id, o.group_id) = 't'
               group by o.group_id) m
          where ug.parent_group_id=[im_office_group_id]
            and ug.group_id=o.group_id(+)
            and ug.group_id=m.group_id(+)
               and o.public_p='t'
          group by ug.group_id, ug.group_name, public_p, number_users
          order by public_p desc, lower(group_name), group_id"

# jruiz 20020604: Added public_p filter, show only public offices


set results ""
set last_public_p ""
set number_public_p 0

db_foreach intranet_offices_get_offices $sql_query {
    if { [string compare $last_public_p $public_p] != 0 } {
	if { ![empty_string_p $last_public_p] } {
	    append results "</ul>\n"
	}
	append results "<p><b>Offices whose information is [util_decode $public_p "t" "public" "not public"]</b>\n<ul>\n"
	set last_public_p $public_p
    }
    if { [string compare $public_p "t"] == 0 } {
	incr number_public_p
    }
    append results "  <li> <a href=view?[export_url_vars group_id]>$group_name</a> ($office_size)\n"
} if_no_rows {
    set results "  <p><ul><b> There are no offices </b>\n" 
}

append results "</ul>\n"

db_release_unused_handles

set page_title "Offices"
set context_bar [ad_context_bar $page_title]

set page_body "
$results
<ul>
<li><a href=ae>Add an office</a>
"

if { $number_public_p > 0 } {
    append page_body "<li><a href=public>View public office information</a>\n"
}

append page_body "</ul>\n"

doc_return  200 text/html [im_return_template]


