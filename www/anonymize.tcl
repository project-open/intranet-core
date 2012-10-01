# /packages/intranet-core/www/anonymize.tcl
#
# Copyright (C) 1998-2008 ]project-open[
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
    ad_return_complaint 1 "<LI>[_ intranet-core.lt_This_is_not_a_TestDem]<BR>
    [_ intranet-core.lt_So_you_probably_dont_]<br>&nbsp;<br>
    [_ intranet-core.lt_If_this_IS_a_TestDemo]"
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
	select	p.*
	from	im_projects p
"

#
# Fraber 120227: We need the _nr and _path for SOR
#		project_nr = '[anonymize_name $project_nr]',
#		project_path = '[anonymize_name $project_path]',


db_foreach im_projects_select $im_projects_sql {
    db_dml im_projects_update "
	update im_projects set
		project_name = '[anonymize_name $project_name]',
		description = '[anonymize_name $description]',
		note = '[anonymize_name $note]',
		company_project_nr = '[anonymize_name $company_project_nr]',
		final_company = '[anonymize_name $final_company]'
	where 
		project_id = :project_id
    "
}


# ---------------------- im_trans_tasks -------------------------------
if {[im_table_exists im_trans_tasks]} {
    set im_trans_tasks_sql "
	select	task_id,
		task_name,
		description
	from	im_trans_tasks
   "

    db_foreach im_trans_tasks_select $im_trans_tasks_sql {
	db_dml im_trans_tasks_update "
	update im_trans_tasks set
		task_name='[anonymize_name $task_name]',
		description='[anonymize_name $description]'
	where task_id=:task_id
        "
    }
}

# ---------------------- im_invoice_items -------------------------------
set im_invoice_items_sql "
    	select	item_id,
		item_name,
		price_per_unit,
		description
	from	im_invoice_items
"

db_foreach im_invoice_items_select $im_invoice_items_sql {
    set new_price "0.[expr round(100*rand())]"
    db_dml im_invoice_items_update "
	update im_invoice_items set
		item_name = '[anonymize_name $item_name]',
		price_per_unit = :new_price
	where item_id = :item_id
    "
}


# ---------------------- im_trans_prices -------------------------------
if {[im_table_exists im_trans_prices]} {
    set im_trans_prices_sql "
    	select	price_id
	from	im_trans_prices
    "
    db_foreach im_prices_select $im_trans_prices_sql {
	set new_price [expr round(100*rand()) / 100]
	db_dml im_trans_prices_update "
	update im_trans_prices set
		price = :new_price
	where price_id = :price_id
        "
    }
}


# ---------------------- im_companies -------------------------------
set im_companies_sql "
	select	c.*
	from	im_companies c
	where	company_path != 'internal'
"

db_foreach im_companies_select $im_companies_sql {
    db_dml im_companies_update "
	update im_companies set
		company_name='[anonymize_name $company_name]',
		company_path='[anonymize_name $company_path]',
		referral_source='[anonymize_name $referral_source]',
		site_concept='[anonymize_name $site_concept]',
		vat_number='[anonymize_name $vat_number]',
		note='[anonymize_name $note]'
	where 
		company_id = :company_id
    "
}

# Special treatment for the "Internal" company
set im_companies_sql "
	select	c.*
	from	im_companies c
	where	company_path = 'internal'
"

db_foreach im_companies_select $im_companies_sql {
    db_dml im_companies_update "
	update im_companies set
		company_name='[anonymize_name $company_name]',
		referral_source='[anonymize_name $referral_source]',
		site_concept='[anonymize_name $site_concept]',
		vat_number='[anonymize_name $vat_number]',
		note='[anonymize_name $note]'
	where 
		company_id = :company_id
    "
}

# ---------------------- im_offices -------------------------------


set im_offices_sql "
	select	o.*
	from	im_offices o
"
db_foreach im_offices_select $im_offices_sql {

    if {[string length $office_path] < 5} {
	append office_path "[random_char][random_char][random_char][random_char]"
    }

    db_dml im_offices_update "
	update im_offices set
		office_name = '[anonymize_name $office_name]',
		office_path = '[anonymize_name $office_path]',
		phone = '[anonymize_name $phone]',
		fax = '[anonymize_name $fax]',
		address_line1 = '[anonymize_name $address_line1]',
		address_line2 = '[anonymize_name $address_line2]',
		address_city = '[anonymize_name $address_city]',
		address_state = '[anonymize_name $address_state]',
		address_postal_code = '[anonymize_name $address_postal_code]',
		landlord = '[anonymize_name $landlord]',
		security = '[anonymize_name $security]',
		note = '[anonymize_name $note]'
    	where
		office_id = :office_id
    "
}

# ---------------------- users_contact -------------------------------

set users_contact_sql "
	select	u.*
	from	users_contact u"

db_foreach users_contact_select $users_contact_sql {

    db_dml users_contact_update "
	update users_contact set
		home_phone = '[anonymize_name $home_phone]',
		work_phone = '[anonymize_name $work_phone]',
		cell_phone = '[anonymize_name $cell_phone ]',
		pager = '[anonymize_name $pager]',
		fax = '[anonymize_name $fax ]',
		aim_screen_name = '[anonymize_name $aim_screen_name ]',
		icq_number = '[anonymize_name $icq_number ]',
		ha_line1 = '[anonymize_name $ha_line1 ]',
		ha_line2 = '[anonymize_name $ha_line2 ]',
		ha_city = '[anonymize_name $ha_city ]',
		ha_state = '[anonymize_name $ha_state ]',
		ha_postal_code = '[anonymize_name $ha_postal_code ]',
		wa_line1 = '[anonymize_name $wa_line1 ]',
		wa_line2 = '[anonymize_name $wa_line2 ]',
		wa_city = '[anonymize_name $wa_city ]',
		wa_state = '[anonymize_name $wa_state ]',
		wa_postal_code = '[anonymize_name $wa_postal_code ]',
		note = '[anonymize_name $note ]',
		current_information = '[anonymize_name $current_information ]'
    	where
		user_id = :user_id
    "
}


# ---------------------- users -------------------------------


set user_sql "
	select
		u.user_id,
		u.username,
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
		and not(email like 'sysadmin%')
"

db_foreach user_select $user_sql {
    set first_names_mod [anonymize_name $first_names]
    set last_name_mod [anonymize_name $last_name]
    set username_mod [anonymize_name $username]
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

    db_dml user_update "
	update users set
		username = :username_mod
	where user_id=:user_id
   "

    db_dml person_update "
	update persons set
		first_names=:first_names_mod,
		last_name=:last_name_mod
	where person_id = :user_id
    "
    db_dml party_update "
	update parties set
		email=:email_mod,
		url=:url_mod
	where party_id=:user_id
   "
}

ad_returnredirect $return_url
