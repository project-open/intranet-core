# /www/intranet/anonymize.tcl

ad_page_contract {
    Changes all clients, users, prices etc to allow
    to convert a productive system into a demo.
} {
    { return_url "" }
}

if {![string equal "true" [ad_parameter TestDemoDevServer "" false]]} {
    ad_return_complaint 1 "<LI>This is not a Test/Demo/Development server.<BR>
    So you probably don't want to destroy all data, right?!?<br>&nbsp;<br>
    If this IS a Test/Demo/Development server, then check '/parameters/*.ini'
    and set the TestDemoDevServer flag to 'true'."
    return
}

set user_id [ad_maybe_redirect_for_registration]

ad_proc anonymize_name { org_string } {
    Replace org string letter with random letter to
    anonymize names.
    Returns the anonymized string.
} {
    set word_list [split $org_string " "]
    set result_list [list]
    foreach word $word_list {
	lappend result_list [anonymize_word $word]
    }
    return [join $result_list " "]
}

ad_proc anonymize_email { org_email } {
    Replace the email with an anonymized version
} {
    if {[regexp {([^@]*)\@(.*)} $org_email match name domain]} {
	set name_mod [anonymize_word $name]
	set domain_mod [anonymize_word $domain]
	return "$name_mod@$domain_mod"
    } else {
	ns_log Notice "bad email: $org_email"
	return "nobody@nowhere.com"
    }
}

ad_proc anonymize_url { org_url } {
    Replace the url with an anonymized version
} {
    return [anonymize_word $org_url]
}

ad_proc anonymize_word { org_word } {
    Anonymizes a single word. This allows to
    preserve "Inc.", "S.L." etc
} {
    set len [string length $org_word]
    set result ""
    for {set i 0} {$i < $len} {incr i} {
	set org_char [string range $org_word $i $i]
	set anon_char [anonymize_char $org_char]
	set result "$result$anon_char"
    }
#    ns_log Notice "anonymize_word: $org_word => $result"
    return $result
}

ad_proc anonymize_char { org_char } {
    Anonymizes a single character
} {
    # 0123456789 -> 0123456789
    # aeiouy -> aeiouy
    # bdgkpqt -> bdgkpqt
    # cjsxz -> cjsxz
    # mn -> mn
    # fvw -> fvw
    # h -> {}
    # lr -> lr

    set pos [string last $org_char "ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
    if {$pos >= 0} {
	set org_char [string range "abcdefghijklmnopqrstuvwxyz" $pos $pos]
    }

    set res $org_char
    if {[string last $org_char {'"}]>=0} {set res ""}
    if {[string last $org_char "0123456789"]>=0} {set res [pick_char "0123456789"]}
    if {[string last $org_char "aeiouy"]>=0} {set res [pick_char "aeiouy"]}
    if {[string last $org_char "bdgkpqt"]>=0} {set res [pick_char "bdgkpqt"]}
    if {[string last $org_char "cjsxz"]>=0} {set res [pick_char "cjsxz"]}
    if {[string last $org_char "mn"]>=0} {set res [pick_char "mn"]}
    if {[string last $org_char "fvw"]>=0} {set res [pick_char "fvw"]}
    if {[string last $org_char "lr"]>=0} {set res [pick_char "lr"]}

    if {$pos >= 0} {
	set pos [string last $res "abcdefghijklmnopqrstuvwxyz"]
	set res [string range "ABCDEFGHIJKLMNOPQRSTUVWXYZ" $pos $pos]
    }

    return $res
}

ad_proc pick_char { char_set } {
    Picks a random char from char_set
} {
    set len [string length $char_set]
    set pos [expr round(1000*rand()) % $len]
    set result [string range $char_set $pos $pos]
    return $result
}

# ---------------------- im_projects -------------------------------

set im_projects_sql "
select
	group_id,
	description,
	note,
	customer_project_nr,
	final_customer
from
	im_projects"

db_foreach im_projects_select $im_projects_sql {

    set im_projects_update_sql "
	update im_projects set
        description='[anonymize_name $description]',
        note='[anonymize_name $note]',
        customer_project_nr='[anonymize_name $customer_project_nr]',
        final_customer='[anonymize_name $final_customer]'
	where group_id=:group_id"

    db_dml im_projects_update $im_projects_update_sql
}

# ---------------------- im_trans_tasks -------------------------------

set im_trans_tasks_sql "
select
	task_id,
	task_name,
	description
from
	im_trans_tasks"

db_foreach im_trans_tasks_select $im_trans_tasks_sql {

    set im_trans_tasks_update_sql "
	update im_trans_tasks set
        task_name='[anonymize_name $task_name]',
        description='[anonymize_name $description]'
	where task_id=:task_id"

    db_dml im_trans_tasks_update $im_trans_tasks_update_sql
}

# ---------------------- im_invoice_items -------------------------------

set im_invoice_items_sql "
select
	item_id,
	item_name,
	price_per_unit,
	description
from
	im_invoice_items"

db_foreach im_invoice_items_select $im_invoice_items_sql {

    set new_price "0.[expr round(100*rand())]"
    set im_invoice_items_update_sql "
	update im_invoice_items set
        item_name='[anonymize_name $task_name]',
        description='[anonymize_name $description]',
        price_per_unit=:new_price
	where item_id=:item_id"

    db_dml im_invoice_items_update $im_invoice_items_update_sql
}

# ---------------------- im_prices -------------------------------

set im_prices_sql "
select
	price_id
from
	im_prices"

db_foreach im_prices_select $im_prices_sql {

    set new_price [expr round(100*rand()) / 100]
    set im_prices_update_sql "
	update im_prices set
        price=:new_price
	where price_id=:price_id"

    db_dml im_prices_update $im_prices_update_sql
}

# ---------------------- im_customers -------------------------------

set im_customers_sql "
select
	group_id,
	referral_source,
	site_concept,
	vat_number,
	note
from
	im_customers"

db_foreach im_customers_select $im_customers_sql {

    set im_customers_update_sql "
	update im_customers set
        referral_source='[anonymize_name $referral_source]',
        site_concept='[anonymize_name $site_concept]',
        vat_number='[anonymize_name $vat_number]',
        note='[anonymize_name $note]'
	where group_id=:group_id"

    db_dml im_customers_update $im_customers_update_sql
}

# ---------------------- im_facilities -------------------------------

set im_facilities_sql "
select
	facility_id,
	facility_name,
	phone,
	fax,
	address_line1,
	address_line2,
	address_city,
	address_state,
	address_postal_code,
	landlord,
	security,
	note
from
	im_facilities"

db_foreach im_facilities_select $im_facilities_sql {

    set im_facilities_update_sql "
	update im_facilities set
	facility_name='[anonymize_name $facility_name]',
	phone='[anonymize_name $phone]',
	fax='[anonymize_name $fax]',
	address_line1='[anonymize_name $address_line1]',
	address_line2='[anonymize_name $address_line2]',
	address_city='[anonymize_name $address_city]',
	address_state='[anonymize_name $address_state]',
	address_postal_code='[anonymize_name $address_postal_code]',
	landlord='[anonymize_name $landlord]',
	security='[anonymize_name $security]',
	note='[anonymize_name $note]'
    	where facility_id=:facility_id"

    db_dml im_facilities_update $im_facilities_update_sql
}


# ---------------------- user_groups -------------------------------

set user_groups_sql "
select
	group_id,
	group_name,
	short_name
from
	user_groups
where
	group_id > 18"

db_foreach user_groups_select $user_groups_sql {
    set group_name_mod [anonymize_name $group_name]
    set short_name_mod [anonymize_name $short_name]

    set user_groups_update_sql "
	update user_groups
	set
		group_name=:group_name_mod,
		short_name=:short_name_mod
	where group_id=:group_id"

    db_dml user_groups_update $user_groups_update_sql
}


# ---------------------- users_contact -------------------------------

set users_contact_sql "
select
	user_id,
	home_phone,
	work_phone,
	cell_phone,
	pager,
	fax,
	aim_screen_name,
	icq_number,
	m_address,
	ha_line1,
	ha_line2,
	ha_city,
	ha_state,
	ha_postal_code,
	wa_line1,
	wa_line2,
	wa_city,
	wa_state,
	wa_postal_code,
	note,
	current_information	
from
	users_contact"

db_foreach users_contact_select $users_contact_sql {

    set users_contact_update_sql "
	update users_contact set
	home_phone='[anonymize_name $home_phone]',
	work_phone='[anonymize_name $work_phone]',
	cell_phone='[anonymize_name $cell_phone ]',
	pager='[anonymize_name $pager]',
	fax='[anonymize_name $fax ]',
	aim_screen_name='[anonymize_name $aim_screen_name ]',
	icq_number='[anonymize_name $icq_number ]',
	m_address='[anonymize_name $m_address ]',
	ha_line1='[anonymize_name $ha_line1 ]',
	ha_line2='[anonymize_name $ha_line2 ]',
	ha_city='[anonymize_name $ha_city ]',
	ha_state='[anonymize_name $ha_state ]',
	ha_postal_code='[anonymize_name $ha_postal_code ]',
	wa_line1='[anonymize_name $wa_line1 ]',
	wa_line2='[anonymize_name $wa_line2 ]',
	wa_city='[anonymize_name $wa_city ]',
	wa_state='[anonymize_name $wa_state ]',
	wa_postal_code='[anonymize_name $wa_postal_code ]',
	note='[anonymize_name $note ]',
	current_information='[anonymize_name $current_information ]'
    	where user_id=:user_id"

    db_dml users_contact_update $users_contact_update_sql
}


# ---------------------- users -------------------------------

set user_sql "
select
	user_id,
	email,
	first_names,
	last_name,
	url
from
	users
where
	user_id > 2"

db_foreach user_select $user_sql {
    set first_names_mod [anonymize_name $first_names]
    set last_name_mod [anonymize_name $last_name]
    set email_mod [anonymize_email $email]
    set url_mod [anonymize_url $url]
    ns_log Notice "user_id=$user_id, first_names=$first_names, last_name=$last_name, email=$email, url=$url"
    ns_log Notice "user_id=$user_id, first_names=$first_names_mod, last_name=$last_name_mod, email=$email_mod, url=$url_mod"

    # Skip the default roles
    if {[regexp {client.contact@} $email]} { continue }
    if {[regexp {freelance@} $email]} { continue }
    if {[regexp {administrator@} $email]} { continue }
    if {[regexp {employee@} $email]} { continue }
    if {[regexp {project.manager@} $email]} { continue }
    if {[regexp {accounting@} $email]} { continue }

    set user_update_sql "
	update users
	set
		first_names=:first_names_mod,
		email=:email_mod,
		last_name=:last_name_mod,
		url=:url_mod
	where user_id=:user_id"

    db_dml user_update $user_update_sql
}


    set user_password_update_sql "
	update users
	set password='xxx'
    "

    db_dml user_password_update $user_password_update_sql




if {"" != $return_url} {
    ad_return_redirect $return_url
} else {
    set page_body "<H1>Anonymize</H1>Successfully finished"
    doc_return  200 text/html [im_return_template]
}