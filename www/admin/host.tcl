# host.tcl,v 3.1 2000/05/23 08:15:24 jsc Exp
# host.tcl
# created by philg@mit.edu on March 1, 1999
# displays as much as we can know about activity from a particular IP address

set_the_usual_form_variables

# ip 

ReturnHeaders 

ns_write "[ad_admin_header $ip]

<h2>$ip</h2>

[ad_admin_context_bar "One Host"]

<hr>

The first thing we'll do is try to look up the ip address ... 

"

set hostname [ns_hostbyaddr $ip]

ns_write "$hostname.

(If it is just the number again, that means the reverse DNS lookup failed.)

"

set db [ns_db gethandle]
set selection [ns_db select $db "select user_id, first_names, last_name, email 
from users
where registration_ip = '$QQip'"]

set items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li><a href=\"/admin/users/one?[export_url_vars user_id]\">$first_names $last_name</a> ($email)\n"
}

if ![empty_string_p $items] {
    ns_write "<h3>User Registrations from $hostname</h3>

<ul>
$items
</ul>

"
}

set selection [ns_db select $db "select msg_id, one_line 
from bboard 
where originating_ip = '$QQip'"]

set items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li>$one_line\n"
}

if ![empty_string_p $items] {
    ns_write "<h3>BBoard postings from $hostname</h3>

<ul>
$items
</ul>

"
}


ns_write [ad_admin_footer]
