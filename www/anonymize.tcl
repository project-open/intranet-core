# /packages/intranet-core/www/anonymize.tcl
#
# Copyright (C) 1998-2004 Project/Open
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


ad_page_contract {
    Changes all clients, users, prices etc to allow
    to convert a productive system into a demo.

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

if {![ad_parameter -package_id [im_package_core_id] TestDemoDevServer "" 0]} {
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

ad_proc random_char {} {
    Return a random character
} {
    return [pick_char "abcdefghijklmnopqrstuvwxyz"]
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
	project_id,
	project_name,
	project_path,
	project_nr,
	description,
	note,
	customer_project_nr,
	final_customer
from
	im_projects"

db_foreach im_projects_select $im_projects_sql {

    set im_projects_update_sql "
	update im_projects set
	project_name = '[anonymize_name $project_name]',
	project_nr = '[anonymize_name $project_nr]',
	project_path = '[anonymize_name $project_path]',
        description='[anonymize_name $description]',
        note='[anonymize_name $note]',
        customer_project_nr='[anonymize_name $customer_project_nr]',
        final_customer='[anonymize_name $final_customer]'
	where project_id=:project_id"

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
	customer_id,
	customer_name,
	customer_path,
	referral_source,
	site_concept,
	vat_number,
	note
from
	im_customers"

db_foreach im_customers_select $im_customers_sql {

    set im_customers_update_sql "
	update im_customers set
        customer_name='[anonymize_name $customer_name]',
        customer_path='[anonymize_name $customer_path]',
        referral_source='[anonymize_name $referral_source]',
        site_concept='[anonymize_name $site_concept]',
        vat_number='[anonymize_name $vat_number]',
        note='[anonymize_name $note]'
	where customer_id=:customer_id"

    db_dml im_customers_update $im_customers_update_sql
}


# ---------------------- im_offices -------------------------------


set im_offices_sql "
select
	office_id,
	office_name,
	office_path,
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
	im_offices"

db_foreach im_offices_select $im_offices_sql {

    if {[string length $office_path] < 5} {
	append office_path "[random_char][random_char][random_char][random_char]"
    }

    set im_offices_update_sql "
	update im_offices set
	office_name='[anonymize_name $office_name]',
	office_path='[anonymize_name $office_path]',
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
    	where office_id=:office_id"

    db_dml im_offices_update $im_offices_update_sql
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
	u.user_id,
	pa.email,
	pe.first_names,
	pe.last_name,
	pa.url
from
	users u,
	persons pe,
	parties pa
where
	u.user_id = pe.person_id
	and u.user_id = pa.party_id
	and u.user_id > 2
	and email != 'fraber@fraber.de'
	and not (email like '%@project-open.com')
"

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

#    db_dml user_update $user_update_sql

    set person_update_sql "
	update persons
	set
		first_names=:first_names_mod,
		last_name=:last_name_mod
	where person_id=:user_id"
    db_dml user_update $person_update_sql

    set party_update_sql "
	update parties
	set
		email=:email_mod,
		url=:url_mod
	where party_id=:user_id"
    db_dml user_update $party_update_sql
}


#    set user_password_update_sql "
#	update users
#	set password='xxx'
#    "
#
#    db_dml user_password_update $user_password_update_sql




if {"" != $return_url} {
    ad_return_redirect $return_url
} else {
    set page_body "<H1>Anonymize</H1>Successfully finished"
    doc_return  200 text/html [im_return_template]
}