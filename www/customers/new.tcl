# /www/intranet/customers/new.tcl

ad_page_contract {
    Lets users add/modify information about our customers

    @param customer_id if specified, we edit the customer with this customer_id
    @param return_url Return URL

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id new.tcl,v 3.9.2.11 2000/09/22 01:38:27 kevin Exp

} {
    { customer_id:integer 0 }
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"


# Make sure the user has the privileges, because this
# pages shows the list of customers etc.
#
if {![im_permission $user_id "add_customers"]} { 
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to add a new client."
}

if {$customer_id > 0} {

    # Called with an existing customer_id => Edit the customer
    #

    if {![db_0or1row customer_get_info "
select
	c.customer_name, 
	c.customer_path, 
	c.customer_status_id, 
	c.customer_type_id, 
	c.billable_p,
	c.note, 
	c.annual_revenue_id, 
	c.referral_source,
	c.vat_number,
	c.facility_id,
	nvl(c.manager_id,$user_id) as manager, 
	c.site_concept, 
	nvl(c.contract_value,600) as contract_value,
	to_char(nvl(c.start_date,sysdate),'YYYY-MM-DD') as start_date,
	f.facility_name,
	f.phone,
	f.fax,
	f.address_line1,
	f.address_line2,
	f.address_city,
	f.address_postal_code,
	f.address_country_code
from 
	im_customers c, 
	im_facilities f
where 
	c.customer_id=:customer_id
	and c.facility_id=f.facility_id(+)
" 
    ]} {
	ad_return_error "Client #customer_id doesn't exist" "Please back up, and try again"
	return
    }

    set page_title "Edit customer"
    set context_bar [ad_context_bar [list index "Clients"] [list "view?[export_url_vars customer_id]" "One customer"] $page_title]



    # Make sure the Facility exists,
    # in case an error has occured previously

    # Make sure the facility exists to be able to store the 
    # Address data
    if {0 == $facility_id || "" == $facility_id} {

	set facility_name "$customer_name Main Facility"

	set facility_id [group::new \
	  -context_id [ad_conn package_id] \
	  -creation_user $user_id \
	  -group_name "$facility_name Admin Group" \
	  -creation_ip [ad_conn peeraddr]]

	set sql "insert into im_facilities 
		(facility_id, facility_name) values 
		(:facility_id, :facility_name)
        "


        if { [catch {
	    db_dml facility_insert $sql
        } err_msg] } {
	    # don't show the error to the user. Let's asume the facility exists...
	    ns_log Error "/customers/new: $err_msg"
        }

	set facility_id [db_string main_facility "select facility_id from im_facilities where facility_name like :facility_name" -default 0]

	set customer_update_sql "
		update im_customers
		set facility_id=:facility_id
		where customer_id=:customer_id"
	db_dml customer_update $customer_update_sql
    }


    
} else {

    # Completely new customer. Set some reasonable defaults:
    set page_title "Add customer"
    set context_bar [ad_context_bar [list index "Clients"] $page_title]
    set customer_name ""
    set customer_path ""
    # Grab today's date
    set start_date [lindex [split [ns_localsqltimestamp] " "] 0]
    set note ""
    set phone ""
    set fax ""
    set address_line1 ""
    set address_line2 ""
    set address_postal_code ""
    set address_city ""
    set site_concept ""
    set vat_number ""

    # 41=Potential Client
    set customer_status_id "41"
    # 51=Translation Agency
    set customer_type_id "51"
    set annual_revenue_id "224"
    set referral_source "How did we get in contact with the client?"
    set billable_p "t"
    set "creation_ip_address" [ns_conn peeraddr]
    set "creation_user" $user_id
    set customer_id [im_new_object_id]
    set address_country_code ""

    set facility_name ""
    set facility_id 0
}

set customer_defaults [ns_set create]
ns_set put $customer_defaults billable_p $billable_p


set page_body "
<form method=get action=new-2>
[export_form_vars return_url customer_id creation_ip_address creation_user]
<input type=hidden name=facility_name value='$facility_name'>
<input type=hidden name=facility_id value=$facility_id>

		  <table border=0>
		    <tr> 
		      <td colspan=2 class=rowtitle align=center>Add New Client Project</td>
		    </tr>
		    <tr> 
		      <td>Client Name</td>
		      <td> 
<input type=text size=30 name=customer_name value=\"$customer_name\">
		      </td>
		    </tr>
		    <tr> 
		      <td>Client Short Name<BR><font size=-2>(directory path)</font></td>
		      <td> 
<input type=text size=10 name=customer_path value=\"$customer_path\">
		      </td>
		    </tr>
		    <tr> 
		      <td>Referral Source</td>
		      <td> 
<input type=text size=30 name=referral_source value=\"$referral_source\">
		      </td>
		    </tr>
		    <tr> 
		      <td>Client Status</td>
		      <td> 
[im_customer_status_select "customer_status_id" $customer_status_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/admin/categories/?select_category_type=Intranet+Customer+Status'>
	[im_gif new {Add a new customer status}]</A>"
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td>Client Type</td>
		      <td> 
[im_customer_type_select "customer_type_id" $customer_type_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/admin/categories/?select_category_type=Intranet+Customer+Type'>
	[im_gif new {Add a new customer type}]</A>"
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td>Phone</td>
		      <td> 
<input type=text size=15 name=phone value=\"$phone\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>Fax</td>
		      <td> 
<input type=text size=15 name=fax value=\"$fax\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>Address 1</td>
		      <td> 
<input type=text size=30 name=address_line1 value=\"$address_line1\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>Address 2</td>
		      <td> 
<input type=text size=30 name=address_line2 value=\"$address_line2\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>ZIP and City</td>
		      <td> 
<input type=text size=5 name=address_postal_code value=\"$address_postal_code\" >
<input type=text size=30 name=address_city value=\"$address_city\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>Country</td>
		      <td> 
[im_country_select address_country_code $address_country_code]
		      </td>
		    </tr>
		    <tr> 
		      <td>Web Site</td>
		      <td> 
<input type=text size=30 name=site_concept value=\"$site_concept\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>VAT Number</td>
		      <td> 
<input type=text size=20 name=vat_number value=\"$vat_number\" >
		      </td>
		    </tr>


		    <tr> 
		      <td>(Expected) Annual Revenue</td>
		      <td> 
[im_category_select "Intranet Annual Revenue" annual_revenue_id $annual_revenue_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/admin/categories/?select_category_type=Intranet+Annual+Revenue'>
	[im_gif new {Add a new annual revenue measure}]</A>"
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td>Is this a billable customer?</td>
		      <td> 

<input type=radio name=billable_p value=t> Yes &nbsp;</input>
<input type=radio name=billable_p value=f> No </input>

		      </td>
		    </tr>
		    <tr> 
		      <td>Key Account Manager</td>
		      <td> 
<select name=manager_id size=8>
[im_employee_select_optionlist [value_if_exists manager_id]]
</select>
		      </td>
		    </tr>
		    <tr> 
		      <td>Notes</td>
		      <td> 
<textarea name=note rows=6 cols=30 wrap=soft>[philg_quote_double_quotes $note]</textarea>
		      </td>
		    </tr>

</table>

<p><center><input type=submit value=\"$page_title\"></center>
</form>
"

doc_return  200 text/html [im_return_template]
