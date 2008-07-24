# /packages/intranet-core/tcl/intranet-groups-permissions.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
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

ad_library {
    Compatibility library for a fast port of ]project-open[
    (ACS 3.4 Intranet) to OpenACS

    @author unknown@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
}

# ------------------------------------------------------------------
# ad_user_group_member 

ad_proc -public ad_user_group_member { group_id user_id} {
    Frequently used procedure to determine if a user is a 
    member of a group
} {
    set member_p [util_memoize "ad_user_group_member_helper $group_id $user_id" 60]
    return $member_p
}


ad_proc -public ad_user_group_member_helper {group_id user_id} {
    Helper-functionn for:
    Frequently used procedure to determine if a user is a 
    member of a group.
} {

    set member_count [db_string member_count "
	select 
		count(*) 
	from 
		acs_rels ar,
		membership_rels mr
	where 
		ar.rel_id = mr.rel_id
		and ar.object_id_two = $user_id 
		and ar.object_id_one = $group_id
		and mr.member_state = 'approved'
    "]

    if {$member_count > 0} { return 1 }
    return 0
}





ad_proc -public ad_user_group_name_member { group_name user_id} {

} {
    set member_count [util_memoize "db_string member_count \"select count(*) from acs_rels r, groups g where r.object_id_two = $user_id and r.object_id_one = g.group_id and g.group_name='$group_name'\""]

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
        append widget_value "<option value=\"\" selected=\"selected\">[_ intranet-core.Choose_a_State]</option>\n"
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
	append widget_value "<option value=\"\" selected=\"selected\">[_ intranet-core.Choose_a_Country]</option>\n"
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

