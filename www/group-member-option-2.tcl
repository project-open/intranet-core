# /www/intranet/group-member-option-2.tcl

ad_page_contract {
    Redirects the user to the appropriate place based on whether they
    do or do not want to join the indicated group

    @param group_id group id we're joining
    @param continue_url where to go when we're done
    @param cancel_url where to go if we've answered no on the previous page
    @param role role in which to add the user
    @param operation YES or NO (case insensitive...) If yes, we add the user to the group. Default is No

    @author mbryzek@arsdigita.com
    @creation-date 4/4/2000

    @cvs-id group-member-option-2.tcl,v 3.3.2.4 2000/08/16 21:24:27 mbryzek Exp
} {
    group_id:integer,notnull
    continue_url:notnull
    cancel_url:notnull
    { operation "NO" }
    { role "administrator" }
}


set user_id [ad_maybe_redirect_for_registration]

set operation [string toupper [string trim $operation]]

if { [string compare $operation "NO"] == 0 } {
    # Cancelled...
    ad_returnredirect $cancel_url
    return
}


# Let's make sure the group is an intranet group :)
set group_type [ad_parameter IntranetGroupType intranet intranet]

set intranet_group_type_p [db_string group_type_check \
	"select count(*) from user_groups where group_id = :group_id and group_type = :group_type"]

if { !$intranet_group_type_p } {
    ad_return_error "Invalid group type" "The group you selected is not of type [ad_parameter IntranetGroupType intranet intranet]. You cannot add yourself to this group through this interface"
    return
}

ad_user_group_user_add $user_id $role $group_id

db_release_unused_handles

ad_returnredirect $continue_url
