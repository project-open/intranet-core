# /tcl/intranet-groups-permissions.tcl

ad_library {
    Compatibility library for a fast port of Project/Open
    (ACS 3.4 Intranet) to OpenACS
    @author Frank Bergmann (fraber@fraber.de)
}

# ------------------------------------------------------------------
# ad_user_group_member 

ad_proc -public ad_user_group_member { group_id user_id} {

} {
    set member_count [util_memoize "db_string member_count \"select count(*) from group_member_map where member_id=$user_id and group_id=$group_id\""]
    if {$member_count > 0} { return 1 }
    return 0
}


ad_proc -public ad_partner_upvar { var {levels 2} } {
    incr levels
    set return_value ""
    for { set i 1 } { $i <= $levels } { incr i } {
        catch {
            upvar $i $var value
            if { ![empty_string_p $value] } {
                set return_value $value
                return $return_value
            }
        } err_msg
    }
    return $return_value
}


ad_proc -public im_new_object_id { } {
    Create a new project and and setup a new administration group
} {
    db_nextval "acs_object_id_seq"
}


proc_doc im_state_widget { {default ""} {select_name "usps_abbrev"}} "Returns a state selection box" {

    set widget_value "<select name=\"$select_name\">\n"
    if { $default == "" } {
        append widget_value "<option value=\"\" selected=\"selected\">Choose a State</option>\n"
    }

    db_foreach all_states {
	select state_name, abbrev from us_states order by state_name
    } {
        if { $default == $abbrev } {
            append widget_value "<option value=\"$abbrev\" selected=\"selected\">$state_name</option>\n" 
        } else {            
            append widget_value "<option value=\"$abbrev\">$state_name</option>\n"
        }
    }
    append widget_value "</select>\n"
    return $widget_value
}

proc_doc im_country_widget { {default ""} {select_name "country_code"} {size_subtag "size=4"}} "Returns a country selection box" {

    set widget_value "<select name=\"$select_name\" $size_subtag>\n"
    if { $default == "" } {
	append widget_value "<option value=\"\" selected=\"selected\">Choose a Country</option>\n"
    }
    db_foreach all_countries {
	select country_name, iso from country_codes order by country_name 
    } {
        if { $default == $iso } {
            append widget_value "<option value=\"$iso\" selected=\"selected\">$country_name</option>\n" 
        } else {            
            append widget_value "<option value=\"$iso\">$country_name</option>\n"
        }
    }
    append widget_value "</select>\n"
    return $widget_value
}

