# /packages/intranet-core/www/customers/upload-customers-2.tcl
#
# Copyright (C) 2004 Project/Open
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    /intranet/customers/upload-2.tcl
    Read a .csv-file with header titles exactly matching
    the data model and insert the data in im_customers
    and im_customer_exts

    @author frank.bergmann@project-open.com
} {
    return_url
    upload_file
} 

set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload New File/URL"
set page_body "<PRE>\n<A HREF=$return_url>Return to Project Page</A>\n"
set context_bar [ad_context_bar [list "/intranet/cusomers/" "Companies"] "Upload CSV"]

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match client_filename] {
    # couldn't find a match
    set client_filename $upload_file
}

ns_log Notice "/intranet/filestorage/upload-2.tcl: tmp_filename=$tmp_filename"
ns_log Notice "/intranet/filestorage/upload-2.tcl: client_filename=$client_filename"
ns_log Notice "/intranet/filestorage/upload-2.tcl: upload_file=$upload_file"

if {[regexp {\.\.} $client_filename]} {
    set error "Filename contains forbidden characters"
    ad_returnredirect "/error.tcl?[export_url_vars error]"
}
  
if {![file readable $tmp_filename]} {
    set err_msg "Unable to read the file '$tmp_filename'. 
Please check the file permissions or contact your system administrator.\n"
    append page_body "\n$err_msg\n"
    doc_return  200 text/html [im_return_template]
    return
}
    
set csv_files_content [exec /bin/cat $tmp_filename]
set csv_files [split $csv_files_content "\n"]
set csv_files_len [llength $csv_files]
set csv_header [lindex $csv_files 1]
set csv_headers [split $csv_header ";"]

# Check the length of the title line 
set header [string trim [lindex $csv_files 0]]
set header_csv_fields [split $header ";"]
set header_len [llength $header_csv_fields]

append page_body "Title-Length=$header_len\n"
append page_body "\n\n"

for {set i 1} {$i < $csv_files_len} {incr i} {
    set csv_line [string trim [lindex $csv_files $i]]
    set csv_fields [split $csv_line ";"]

    append page_body "$csv_line\n"

    # Values for im_customers
    set group_id ""
    set deleted_p "f"
    set customer_status_id ""
    set customer_type_id ""
    set note ""
    set referral_source ""
    set annual_revenue_id ""
    set billable_p "t"
    set manager_id ""
    set contract_value ""
    set primary_contact_id ""
    set facility_id ""
    set vat_number ""

    # Values from im_facilities
    # facility_id defined above
    set facility_name ""
    set phone ""
    set fax ""
    set address_line1 ""
    set address_line2 ""
    set address_city ""
    set address_state ""
    set address_postal_code ""
    set contact_person_id ""
    set landlord ""
    set security ""
    set note ""

    # Values from user_groups
    # group_id defined above
    set short_name ""
    set group_name ""
    set group_type "intranet"
    set admin_email "root@localhost"
    set creation_user $user_id
    set creation_ip_address "0.0.0.0"
    set approved_p "t"
    set active_p "t"
    set existence_public_p "f"
    set new_member_policy "closed"
    set spam_policy "open"
    set email_alert_p "f"
    set multi_role_p "f"
    set group_admin_permissions_p "f"
    set index_page_enabled_p "f"
    set body ""
    set html_p "f"
    set parent_group_id [im_customer_group_id]

    for {set j 0} {$j < $header_len} {incr j} {
	set var_name [lindex $header_csv_fields $j]
	set var_value [lindex $csv_fields $j]
	set cmd "set $var_name "
	append cmd "\""
	append cmd $var_value
	append cmd "\""
	set result [eval $cmd]
	append page_body "set $var_name '$var_value' : $result\n"
    }
    
    # The facilites need a separate name, formed here by adding "Facility"
    # Kinda dirty, but should be better then putting "Facility XXX"
    set facility_name "$group_name Facility"
    
    set insert_group_sql "INSERT INTO user_groups VALUES (
    :group_id, :group_type, :group_name, :short_name, :admin_email,
    sysdate, :creation_user, :creation_ip_address, :approved_p,
    :active_p, :existence_public_p, :new_member_policy, :spam_policy,
    :email_alert_p, :multi_role_p, :group_admin_permissions_p,
    :index_page_enabled_p, :body, :html_p, sysdate, :user_id,
    :parent_group_id)"

    set update_group_sql "UPDATE user_groups SET
    (group_name) = (:group_name) 
    WHERE short_name=:short_name"


    set insert_facility_sql "INSERT INTO im_facilities VALUES (
    :facility_id, :facility_name, :phone, :fax, :address_line1,
    :address_line2, :address_city, :address_state, 
    :address_postal_code, :address_country_code,
    :contact_person_id, :landlord, :security, :note)"

    set update_facility_sql "UPDATE im_facilities SET
    facility_name=:facility_name, phone=:phone, fax=:fax, 
    address_line1=:address_line1, address_line2=:address_line2,
    address_city=:address_city, address_state=:address_state, 
    address_postal_code=:address_postal_code, 
    address_country_code=:address_country_code,
    contact_person_id=:contact_person_id, landlord=:landlord, 
    security=:security, note=:note
    WHERE facility_id=:facility_id"

    set insert_customer_sql "INSERT INTO im_customers VALUES (
    :group_id, :deleted_p, :customer_status_id, :customer_type_id,
    :note, :referral_source, :annual_revenue_id, sysdate, '', :billable_p,
    :site_concept, :manager_id, :contract_value, sysdate,
    :primary_contact_id, :facility_id, :vat_number)"

    set update_customer_sql "UPDATE im_customers SET
    deleted_p=:deleted_p, customer_status_id=:customer_status_id, 
    customer_type_id=:customer_type_id, note=:note, 
    referral_source=:referral_source, annual_revenue_id=:annual_revenue_id, 
    status_modification_date=sysdate, old_customer_status_id='', 
    billable_p=:billable_p, site_concept=:site_concept, manager_id=:manager_id,
    contract_value=:contract_value, start_date=sysdate, 
    primary_contact_id=:primary_contact_id, facility_id=:facility_id, 
    vat_number=:vat_number
    WHERE group_id=:group_id"

	# Values from im_facilities
	ns_log Notice "facility_id=$facility_id"
	ns_log Notice "facility_name=$facility_name"
	ns_log Notice "phone=$phone"
	ns_log Notice "fax=$fax"
	ns_log Notice "address_line1=$address_line1"
	ns_log Notice "address_line2=$address_line2"
	ns_log Notice "address_city=$address_city"
	ns_log Notice "address_state=$address_state"
	ns_log Notice "address_postal_code=$address_postal_code"
	ns_log Notice "contact_person_id=$contact_person_id"
	ns_log Notice "landlord=$landlord"
	ns_log Notice "security=$security"
	ns_log Notice "note=$note"



    # check if the customer already exists, either by short or by
    # full name
    if { [catch {
	set group_id [db_string group_id "select group_id from user_groups where short_name=:short_name or group_name=:group_name"]
    } err_msg] } {
	set group_id ""
    }
    ns_log Notice "group_id=$group_id"
    
    if {[string equal $group_id ""]} {
	# The customer doesn't exist yet:
	# => Setup user_groups, im_customer and im_facility
	#
	db_transaction {
	    set group_id [db_nextval "user_group_sequence"]
	    db_dml insert_group_sql $insert_group_sql
	    set facility_id [db_nextval "im_facilities_seq"]
	    db_dml facility_sql $insert_facility_sql
	    db_dml cusomter_sql $insert_customer_sql
	}
    } else {
	# There is already a customer with this short name.
	# => Update the already existing objects
	#

	# Make sure the cusomer exists
	set customer_count [db_string customer_count "select count(*) from im_customers where group_id=:group_id"]
	if {$customer_count == 0} {
	    ad_return_complaint 1 "<li>There is a customer group without a
            im_customer entry. This is a DB-inconsistency that should never 
            occur. Please contact your system administrator."
	    return
	}
	
	# Make sure the facility exists
	set facility_id [db_string facility_id "select facility_id from im_customers where group_id=:group_id"]
	if {[string equal $facility_id ""]} {
	    # We have to add a new facility
	    set facility_id [db_nextval "im_facilities_seq"]
	    db_dml facility_sql $insert_facility_sql
	    db_dml facility_customer_update "update im_customers set facility_id=:facility_id where group_id=:group_id"
	}
	
	# And finally we can update the customer object:
	# for convenience reasons we also update the other
	# objects again.
	#
	db_transaction {
	    db_dml update_group_sql $update_group_sql
	    set facility_id [db_string facility_id "select facility_id from im_customers where group_id=:group_id"]
	    append page_body "facility_id=$facility_id\n"
	    db_dml facility_sql $update_facility_sql
	    db_dml customer_sql $update_customer_sql
	}
    }
}

append page_body "\n<A HREF=$return_url>Return to Project Page</A>\n"
doc_return  200 text/html [im_return_template]
