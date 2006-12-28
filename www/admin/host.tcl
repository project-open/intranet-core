# host.tcl,v 3.1 2000/05/23 08:15:24 jsc Exp
# host.tcl
# created by philg@mit.edu on March 1, 1999
# displays as much as we can know about activity from a particular IP address

ad_page_contract {
    Shows everything we know about a specific IP

    @author unknown@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    ip
}

set page_title "Everything about IP #$ip"

set page_body "
<h3>Hostname</H3>
<ul>
<li>IP-Address: \"$ip\"
<li>Hostname: "

set hostname $ip

catch {set hostname [ns_hostbyaddr $ip]} err_msg

append page_body "\"$hostname\".<br>
(If this is just the number again, that means the reverse DNS lookup failed.)
</ul>
"

# Check for user registrations from the IP
set users_from_ip_sql "
	select	user_id, 
		email,
		im_name_from_user_id(user_id) as user_name
	from	cc_users
	where	creation_ip = :ip
"
set items ""
db_foreach users_from_ip $users_from_ip_sql {
    append items "<li><a href=\"/intranet/users/view?[export_url_vars user_id]\">$user_name</a> ($email)\n"
}
if ![empty_string_p $items] {
    append page_body "
    <h3>User Registrations from $hostname</h3>
    <ul>
	$items
    </ul>"
}

