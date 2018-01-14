# Receives a login from ASP.net script

ad_page_contract {
    Check credentials transferred from ASP.net

    # https://calpms.mnet.moravia-it.com/moravia-login?
    # username=MNet\FBergmann&date=2009-11-26&time=15-12-51&sha1=d2894cbf43e0c81c7736a60a5d4b3d3b35fce6c4

    @cvs-id $Id$
} {
    {username ""}
    {date ""}
    {time ""}
    {sha1 ""}
    {critical ""}
    {return_url "/intranet/"}
}

# Shared Secret
set local_secret "<enter_same_random_string_as_in_localstart.asp>"

# sCritical = sSecret+sUser+sDate+sTime
set local_crit "$local_secret$username$date$time"
set local_crit_sha1 [ns_sha1 $local_crit]

# Calculate the deviation from the timestamp time to the local time.
set date_time "$date-$time"
set date_time_diff [db_string date_diff "select round(abs(extract(epoch from to_timestamp(:date_time, 'YYYY-MM-DD-HH-MI-SS')) - extract(epoch from now())))"]

# Massage the username. Make it lower case and cut of any preceeding "domain\" or "domain/" prefix.
set username [string tolower $username]
if {[regexp {^([a-zA-Z0-9_]*)\\(.*)$} $username match domain main_name]} { 

    # Check for username including domain
    set username $main_name
    set user_id [db_list uid "
	select	user_id
	from	users
	where	lower(username) = :username and
		authority_id in (select authority_id from auth_authorities where lower(short_name) = :domain)
    "]

} else {

    # Check for the username without domain
    set user_id [db_list uid "select user_id from users where lower(username) = :username"]

}

# Check for errors
set errors [list]
if {$sha1 != $local_crit_sha1} { lappend errors "Hash keys don't match" }
if {$date_time_diff > 600.0} { lappend errors "Timestamp outdated or mismatch between server clocks.<br>Difference: $date_time_diff seconds" }
if {[llength $user_id] == 0} { lappend errors "Didn't find user '$username'" }
if {[llength $user_id] > 1} { lappend errors "Found multiple users with name '$username'" }

# ad_return_complaint 1 "<pre>$sha1\n$local_crit_sha1\n</pre>"

if {[llength $errors] > 0} {
    ad_return_complaint 1 "<ul><li>[join $errors "\n<li>\n"]</ul>"
    ad_script_abort
} else {
    ad_user_login $user_id
    ad_returnredirect $return_url
}