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
set page_title "V[string range [im_core_version] 0 5]"

# ------------------------------------------------------
# Multirow
# Users defined in the database
# ------------------------------------------------------

set query "
        select	u.user_id,
		pa.email,
		p.person_id as sort_order,
		p.demo_password,
		p.demo_group,
		p.demo_sort_order,
		im_name_from_user_id(p.person_id) as user_name,
		lower(replace(im_name_from_user_id(p.person_id), ' ', '_')) as lower_name
        from	persons p,
		parties pa,
		users u
        where	p.person_id = pa.party_id
		and p.person_id = u.user_id
		and demo_password is not null
        order by
		p.demo_group,
		u.user_id
	LIMIT 20
"
set last_group ""
set last_group_count 0
set cnt 0
db_multirow -extend {before_html after_html} users users_query $query {
    set after_html ""
    set before_html "</td><td>"
    if {$last_group_count >= 2} {
	set before_html "</td></tr><tr><td>"
	set last_group_count 0
    }
    if {$demo_group ne $last_group} {

	switch $demo_group {
	    Accounting { set group_comment "Accounting - Financial permissions" }
	    Administrators { set group_comment "Administrators - Maximum permissions" }
	    Customers { set group_comment "Customers - Can only see their stuff" }
	    Employees { set group_comment "Employees - Normal permissions" }
	    Freelancers { set group_comment "Freelancers - Can only see their stuff" }
	    "Project Mangers" { set group_comment "Project Managers - Creating projects" }
	    "Senior Managers" { set group_comment "Senior Managers - All permissions except admin" }
	    Sales { set group_comment "Sales - Permissions on presales pipeline" }
	    default { set group_comment $demo_group }
	}

	set before_html "</td></tr></table>"
	append before_html "<br>&nbsp;<br><h1>$group_comment</h1>"
	append before_html "<table border=0 bordercolor=red><tr><td>"
	set last_group_count 0
    }

    incr last_group_count
    set last_group $demo_group
    incr cnt
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

if {0 eq $current_user_id} {
    set email " "
    set username " "
}

# ------------------------------------------------------
# Gather some information about the current system

set ip_address "undefined"
catch {
      set ip_address [im_exec bash -c "/sbin/ifconfig | grep 'inet' | head -1 | cut -d: -f2 | awk '{ print \$2}'"]
} ip_address

set total_memory "undefined"
catch {set total_memory [expr {[im_exec bash -c "grep MemTotal /proc/meminfo | awk '{print \$2}'"] / 1024}]} total_memory

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
