# /www/intranet/offices/public.tcl

ad_page_contract {

    Lists all public offices with their public information    
    @param none 
    @author mbryzek@arsdigita.com
    @creation-date Apr 2000

    @cvs-id public.tcl,v 3.6.2.8 2000/09/22 01:38:39 kevin Exp
} {}

proc_doc im_web_map_url { street city state zip { default "" } } {
    Returns a url to a web map for the specified address. If there is
    not enough information in the arguments passed, returns $default.
} {
    set street [string trim $street]
    set line_2 ""
    if { ![empty_string_p $state] } {
        set line_2 $state
    }
    if { ![empty_string_p $zip] } {
        append line_2 " $zip"
    }
    if { ![empty_string_p $city] } {
        if { [empty_string_p $line_2] } {
            set line_2 $city
        } else {
            set line_2 "$city, $line_2"
        }
    }
    set line_2 [string trim $line_2]
    if { [empty_string_p $line_2] } {
	return $default
    }
    # make sure we don't have a po box
    set temp_street [string tolower [string trim $street]]
    regsub -all {[^a-z]} $temp_street "" temp_street
    if { [regexp {^pobox} $temp_street] } {
	return $default
    }
    return "http://maps.yahoo.com/py/maps.py?addr=[ad_urlencode $street]&csz=[ad_urlencode $line_2]"
}

set sql_query "
	 select ug.group_id, ug.group_name, f.*, 
                u.first_names || ' ' || u.last_name as name, u.email
           from im_offices o, user_groups ug, users u, im_facilities f
          where o.group_id=ug.group_id
            and o.facility_id=f.facility_id(+)
            and o.public_p='t'
            and o.facility_id=f.facility_id
            and f.contact_person_id=u.user_id(+)"

set office_string ""
db_foreach intranet_offices_get_info_loop $sql_query {
    append office_string "  <li> <b><a href=view?[export_url_vars group_id]>$group_name</a></b>: "
    if { ![empty_string_p $name] } {
	append office_string "contact $name, <a href=mailto:$email>$email</a>\n"
    }
    append office_string "<br>[im_format_address $address_line1 $address_line2 $address_city $address_state $address_postal_code]"
    set web_map_url [im_web_map_url "$address_line1 $address_line2" $address_city $address_state $address_postal_code]
    if { ![empty_string_p $web_map_url] } {
	append office_string " (<a href=$web_map_url>map</a>)"
    }
    set tel_list [list]
    if { ![empty_string_p $phone] } {
	lappend tel_list "tel: $phone"
    }
    if { ![empty_string_p $fax] } {
	lappend tel_list "fax: $fax"
    }
    if { [llength $tel_list] > 0 } {
	append office_string "<br>[join $tel_list "; "]\n"
    }
    append office_string "\n"
}

if { [empty_string_p $office_string] } {
    set page_body " <b>There are no offices with public information.</b>"
} else {
    set page_body "
<ul>
$office_string
</ul>
"
}

set page_title "Offices with public information"
set context_bar [ad_context_bar [list ./ "Offices"] "Public offices"]

doc_return  200 text/html [im_return_template]
