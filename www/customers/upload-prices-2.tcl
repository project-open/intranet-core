ad_page_contract {
    /intranet/customers/upload-prices-2.tcl
    Read a .csv-file with header titles exactly matching
    the data model and insert the data into im_prices
} {
    return_url
    customer_id:integer
    upload_file
} 

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "Upload New File/URL"
set page_body "<PRE>\n<A HREF=$return_url>Return to Customer Page</A>\n"
set context_bar [ad_context_bar [list "/intranet/cusomers/" "Clients"] "Upload CSV"]

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter MaxNumberOfBytes fs]
set tmp_filename [ns_queryget upload_file.tmpfile]
if { ![empty_string_p $max_n_bytes] && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match customer_filename] {
    # couldn't find a match
    set customer_filename $upload_file
}

if {[regexp {\.\.} $customer_filename]} {
    set error "Filename contains forbidden characters"
    ad_returnredirect "/error.tcl?[export_url_vars error]"
}

if {![file readable $tmp_filename]} {
    set err_msg "Unable to read the file '$tmp_filename'. 
Please check the file permissions or price your system administrator.\n"
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

db_dml delete_old_prices "delete from im_prices where customer_id=:customer_id"

for {set i 1} {$i < $csv_files_len} {incr i} {
    set csv_line [string trim [lindex $csv_files $i]]
    set csv_fields [split $csv_line ";"]

    append page_body "$csv_line\n"

    # Preset values, defined by CSV sheet:
    set uom ""
    set customer ""
    set task_type ""
    set target_language ""
    set source_language ""
    set subject_area ""
    set valid_from ""
    set valid_through ""
    set price ""
    set currency ""

    for {set j 0} {$j < $header_len} {incr j} {
	set var_name [lindex $header_csv_fields $j]
	set var_value [lindex $csv_fields $j]
	set cmd "set $var_name "
	append cmd "\""
	append cmd $var_value
	append cmd "\""
	ns_log Notice "cmd=$cmd"

	if { [catch {	
	    set result [eval $cmd]
	} err_msg] } {
	    append page_body \n<font color=red>$err_msg</font>\n";
        }
	append page_body "set $var_name '$var_value' : $result\n"
    }

    set uom_id ""
    set task_type_id ""
    set source_language_id ""
    set target_language_id ""
    set subject_area_id ""

    set errmsg ""
    if {![string equal "" $uom]} {
        set uom_id [db_string get_uom_id "select category_id from categories where category_type='Intranet UoM' and category=:uom" -default 0]
        if {$uom_id == 0} { append errmsg "<li>Didn't find UoM '$uom'\n" }
    }

    if {![string equal "" $customer]} {
         set price_customer_id [db_string get_customer_id "select group_id from user_groups where short_name=:customer" -default 0]
         if {$price_customer_id == 0} { append errmsg "<li>Didn't find Customer '$customer'\n" }
         if {$price_customer_id != $customer_id} { append errmsg "<li>Uploading prices for the wrong customer ('$price_customer_id' instead of '$customer_id')" }
    }

    if {![string equal "" $task_type]} {
        set task_type_id [db_string get_uom_id "select category_id from categories where category_type='Intranet Project Type' and category=:task_type"  -default 0]
        if {$task_type_id == 0} { append errmsg "<li>Didn't find Task Type '$task_type'\n" }
    }

#    set source_language_id [db_string get_uom_id "select category_id from categories where category_type='SLS Language' and category=:source_language"  -default 0]
#    set target_language_id [db_string get_uom_id "select category_id from categories where category_type='SLS Language' and category=:target_language"  -default 0]
#    set subject_area_id [db_string get_uom_id "select category_id from categories where category_type='SLS Subject Area' and category=:subject_area"  -default 0]

#    if {$target_language_id == 0} { append errmsg "<li>Didn't find Target Language '$target_language'\n" }
#    if {$source_language_id == 0} { append errmsg "<li>Didn't find Source Language '$source_language'\n" }

    regsub {,} $price {.} price

    append page_body "\n"
    append page_body "uom_id=$uom_id\n"
    append page_body "customer_id=$customer_id\n"
    append page_body "task_type_id=$task_type_id\n"
    append page_body "source_language_id=$source_language_id\n"
    append page_body "target_language_id=$target_language_id\n"
    append page_body "subject_area_id=$subject_area_id\n"
    append page_body "valid_from=$valid_from\n"
    append page_body "valid_through=$valid_through\n"
    append page_body "price=$price\n"
    append page_body "currency=$currency\n"

    set insert_price_sql "INSERT INTO im_prices (
       price_id, uom_id, customer_id, task_type_id,
       target_language_id, source_language_id, subject_area_id,
       valid_from, valid_through, currency, price
    ) VALUES (
       im_prices_seq.nextval, :uom_id, :customer_id, :task_type_id,
       :target_language_id, :source_language_id, :subject_area_id,
       :valid_from, :valid_through, :currency, :price
    )"

    if {[string equal "" $errmsg]} {
        if { [catch {
             db_dml insert_price $insert_price_sql
        } err_msg] } {
	    append page_body \n<font color=red>$err_msg</font>\n";
        }
    } else {
	append page_body $errmsg
    }
}

append page_body "\n<A HREF=$return_url>Return to Project Page</A>\n"
doc_return  200 text/html [im_return_template]
