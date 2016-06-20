ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id$
} {
    {authority_id ""}
    {username ""}
    {email ""}
    {return_url "/intranet/"}
}

set email_org $email
set username_org $username

set demo_server 1

# ------------------------------------------------------
# Multirow
# Users defined in the database
# ------------------------------------------------------

set query "
        select	p.*,
		u.*,
		pa.*,
		p.person_id as sort_order,
		im_name_from_user_id(p.person_id) as user_name
        from	persons p,
		parties pa,
		users u
        where	p.person_id = pa.party_id
		and p.person_id = u.user_id
		and demo_password is not null
        order by
		sort_order,
		u.user_id
	LIMIT 20
"

set old_demo_group ""
db_multirow -extend {view_url} users users_query $query {
    set view_url ""
}

# ------------------------------------------------------
# Get current user email

set current_user_id [ad_conn untrusted_user_id]
set username $username_org
set email $email_org

if {"" == $email} {
    set email [db_string email "select email from parties where party_id = :current_user_id and party_id > 0" -default ""]
}

if {"" == $username} {
    set username [db_string username "select username from users where user_id = :current_user_id and user_id > 0" -default ""]
}

# ------------------------------------------------------
# Gather some information about the current system

set ip_address "undefined"
catch {set ip_address [exec /bin/bash -c "/sbin/ifconfig | grep 'inet' | grep 'netmask' | head -1 | cut -d: -f2 | awk '{ print \$2}'"]} ip_address

set total_memory "undefined"
catch {set total_memory [expr {[exec /bin/bash -c "grep MemTotal /proc/meminfo | awk '{print \$2}'"] / 1024}]} total_memory

set url "<a href=\"http://$ip_address/\" target=_new>http://$ip_address/</a>\n"

set debug ""
set result ""
set header_vars [ns_conn headers]
for { set i 0 } { $i < [ns_set size $header_vars] } { incr i } {
    set key [ns_set key $header_vars $i]
    set val [ns_set value $header_vars $i]
    
    append debug "<tr><td>$key</td><td>$val</td></tr>\n"
    
    if {"Cookie" == $key} { continue }
    if {"Connection" == $key} { continue }
    if {"Cache-Control" == $key} { continue }
    if {"User-Agent" == $key} { continue }
    if {[regexp {^Accept} $key match]} { continue }
    append result "<tr><td>$key</td><td>$val</td></tr>\n"
}
