# /www/intranet/offices/view.tcl

ad_page_contract {
    Shows all info about a specified office

    @param group_id The group_id of the office.
    @param show_all_links_p A boolean to show all links.

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id view.tcl,v 3.19.2.9 2000/10/30 20:50:24 tony Exp
} {
    group_id:notnull,integer
    { show_all_links_p 0 }
}

set caller_user_id [ad_maybe_redirect_for_registration]

set caller_group_id $group_id

set return_url [im_url_with_query]

set empty_string_p [db_0or1row intranet_offices_get_office_info \
	"select 
             g.group_name, 
             g.short_name, 
             f.facility_id,
             f.facility_name,
             f.fax,
             f.phone,
             f.address_line1,
             f.address_line2,
             f.address_city,
             f.address_state,
             f.address_postal_code,
             f.address_country_code,
             f.landlord,
             f.security,
             f.note,
             f.contact_person_id as facility_contact_person_id,
             uf.first_names || ' ' || u.last_name as facility_contact_name,
             f.contact_person_id,
             o.public_p,
             u.first_names || ' ' || u.last_name as name
         from 
             im_offices o, 
             user_groups g, 
             users u, 
             users uf,
             im_facilities f
         where 
             g.group_id = :caller_group_id
             and o.facility_id=f.facility_id
             and g.group_id=o.group_id(+)
             and f.contact_person_id=u.user_id(+)
             and f.contact_person_id=uf.user_id(+)" ]
    
if { $empty_string_p==0 } {
    # Office user group exists, but we might not have created the
    # office information. Tell the user what has happened if this if the case
    set group_exists_p [db_string group_exists_p \
	    "select decode(count(ug.group_id),0,0,1) 
	       from user_groups ug
  	      where ug.group_id=:group_id"]
    if { $group_exists_p } {	
	set context_bar [ad_context_bar [list ./ "Offices"] "One office"]
	doc_return  200 text/html "
[im_header "No office information"]
You have to enter <a href=new?[export_url_vars group_id]>office specific information</a> to continue.
[im_footer]
"
        return
    }
    ad_return_error "Error" "Office doesn't exist"
    return
}

if { $public_p == "t" } {
    set public_status "Yes"
} else {
    set public_status "No"
}

set page_title "$group_name"
set context_bar [ad_context_bar [list ./ "Offices"] "One office"]
set page_body ""

append page_body "
<table cellpadding=3>
<tr>
  <th valign=top align=right>Public?</th>
  <td valign=top>$short_name</td>
</tr>
<tr>
  <th valign=top align=right>Public?</th>
  <td valign=top>$public_status</td>
</tr>
<tr>
  <th valign=top align=right>Facility:</th>
  <td valign=top>$facility_name</td>
</tr>
<tr>
  <th></th>
  <td valign=top>(<a href=new?group_id=$caller_group_id&[export_url_vars return_url]>edit</A>)</td>
</tr>

<tr>
  <th valign=top align=right>Business contact:</TH>
  <td valign=top>
"
if { [empty_string_p $contact_person_id] } {
    append page_body "    <a href=primary-contact?group_id=$caller_group_id&limit_to_users_in_group_id=[im_employee_group_id]>Add business contact</a>\n"
} else {
    append page_body "
    <a href=../users/view?user_id=$contact_person_id>$name</a>
    (<a href=primary-contact?group_id=$caller_group_id>change</a> |
    <a href=primary-contact-delete?[export_url_vars group_id return_url]>remove</a>)
"
}
append page_body "
</table>
<h4>Facility Information</h4>
<table cellpadding=3>
<tr>
  <th valign=top align=right>Address:</th>
  <td valign=top>[im_format_address $address_line1 $address_line2 $address_city $address_state $address_postal_code]</td>
</tr>

<tr>
  <th valign=top align=right>Phone:</TH>
  <td valign=top>$phone</td>
</tr>

<tr>
  <th valign=top align=right>Fax:</TH>
  <td valign=top>$fax</td>
</tr>
"

if { ![empty_string_p $facility_contact_person_id] } {
    append page_body "

<tr>
  <th valign=top align=right>Facility contact:</TH>
  <td valign=top>
    <a href=../users/view?user_id=$facility_contact_person_id>$facility_contact_name</a>
"
}

append page_body "
  </td>
</tr>

<tr>
  <th align=right valign=top>Landlord:</TH>
  <td valign=top>$landlord</td>
</tr>

<tr>
  <th align=right valign=top>Security:</TH>
  <td valign=top>$security</td>
</tr>

<tr>
  <th align=right valign=top>Public:</TH>
  <td valign=top>[util_PrettyBoolean $public_p]</td>
</tr>

<tr>
  <th align=right valign=top>Other<Br> information:</TH>
  <td valign=top>$note</td>
</tr>

<tr>
  <th></th>
  <td align=center>(<a href=/intranet/facilities/new?facility_id=$facility_id&[export_url_vars return_url]>edit</A>)</td>
</tr>

</table>

"

# Display any links for this office

set sql_query \
	"select url, link_title, link_id, active_p
           from im_office_links
          where group_id=:group_id [util_decode $show_all_links_p 0 " and active_p='t'" ""]
          order by active_p desc, lower(link_title)"

set last_link_type ""
set links ""
set ctr 0

db_foreach intranet_offices_get_links_loop $sql_query {
    incr ctr
    set url [im_maybe_prepend_http $url]
    if { $show_all_links_p && [string compare $last_link_type $active_p] != 0 } {
	append links "<p><b>[util_decode $active_p "t" "Active links" "Inactive links"]</b>\n"
	set last_link_type $active_p
    }
    append links "  <li> <a href=\"$url\">$link_title</a> (<a href=link-new?[export_url_vars group_id link_id]>edit</a>)\n"
}

if { $show_all_links_p } {
    set num_links $ctr
} else {
    # Need to know if there are more links to display
    set num_links [db_string intranet_offices_get_more_links \
	    "select count(1) from im_office_links where group_id=:group_id" ]
}

if { [empty_string_p $links] } {
    set links "<li><em>none</em>\n"
}

append page_body "
<h4>Links</h4>
<ul>
$links

<p><li><a href=link-new?[export_url_vars group_id]>Add a link</a>
"

if { $num_links > $ctr } {
    append page_body " | <a href=view?show_all_links_p=1&[export_ns_set_vars url [list show_all_links_p]]>Show all links</a>"
}

append page_body "</ul>\n"

# Decide in advance if we're going to show all the employees or just a link
set number_employees [db_string intranet_offices_get_number_employess \
	"select count(*) from im_employees_active emp
	  where ad_group_member_p(emp.user_id, :group_id)='t'" ]

if { $number_employees > [ad_parameter NumberResultsPerPage intranet 50] } {
    set employees "  <li> <a href=../employees/index?viewing_group_id=$group_id>View all employees ($number_employees)</a>\n"
} else {


    set employee_list_sql \
	    "select u.user_id, u.first_names || ' ' || u.last_name as name
               from im_employees_active u
              where ad_group_member_p ( u.user_id, :caller_group_id ) = 't'
           order by upper(name)"

    set employees ""

    db_foreach intranet_offices_get_active_loop $employee_list_sql {
	append employees "  <li><a href=../users/view?[export_url_vars user_id]>$name</a>\n"
	append employees " (<a href=../member-remove-2?[export_url_vars group_id user_id return_url]>remove</a>)\n"
    }
    
}    

if { [empty_string_p $employees] } {
    set employees "<li><i>No employees listed</i>\n"
}

append page_body "
<h4>Employees</h4>

<ul>
$employees
<p>
"

if { [im_is_user_site_wide_or_intranet_admin $caller_user_id] } {
    set group_id $caller_group_id
    append page_body "
  <li><a href=../member-add?limit_to_users_in_group_id=[im_employee_group_id]&role=member&[export_url_vars group_id return_url]>Add an employee</a>
"
}

append page_body "
   <li><a href=/groups/[ad_urlencode $short_name]/spam?sendto=all>Send email to this office</a>
</ul>
"

if [ad_permission_p site_wide "" "" $caller_user_id] {
    append page_body "
    <h4>Action</h4>
    <ul><li><a href=delete?[export_url_vars group_id]>delete this office</a></li>
    </ul>
    "
}	

doc_return  200 text/html [im_return_template]
