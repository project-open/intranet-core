ad_page_contract {
    Displays who's currently online

    @author Peter Marklund

} -properties {
    title:onevalue
    context:onevalue
}

set title "[_ intranet-core.Whos_Online]"
set context [list $title]
set current_user_id [ad_maybe_redirect_for_registration]


set whos_online_interval [whos_online::interval]

template::list::create \
    -name online_users \
    -multirow online_users \
    -no_data "No registered users online" \
    -elements {
        name {
            label "[_ intranet-core.User_name]"
            link_url_col url
        }
        online_time_pretty {
            label "[_ intranet-core.Online_Time]"
            html { align right }
        }
    }

set users [list]
set not_shown 0

foreach user_id [whos_online::user_ids] {
    acs_user::get -user_id $user_id -array user
    set first_request_minutes [expr [whos_online::seconds_since_first_request $user_id] / 60]
    set user_name "$user(first_names) $user(last_name)"
    set user_url "/intranet/users/view?user_id=$user_id"

    set user_style [im_show_user_style $user_id $current_user_id 0]

    if {$user_style==0} {
	incr not_shown
	continue
    }
    if {$user_style==-1} {
	set user_url ""
    }
    lappend users [list $user_name $user_url "$first_request_minutes minutes"]

}

set users [lsort -index 0 $users]

multirow create online_users name url online_time_pretty

foreach elm $users {
    multirow append online_users \
        [lindex $elm 0] \
        [lindex $elm 1] \
        [lindex $elm 2]
}

