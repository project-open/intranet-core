# /packages/intranet-freelance/www/import-skills-tool.tcl
#
# Copyright (c) 2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {

    Checks for the "IdiomaX_Origen", "IdiomaX-Destino" and "IdiomaX-Tarifa"
    fields of persons and convert them into freelance skills.

    @author frank.bergmann@project-open.com
} {
}

# ---------------------------------------------------------------
# Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-freelance.lt_You_have_insufficient_3]"
    return
}

set source_lang_skill_type [db_string source_lang "select category_id from im_categories where category = 'Source Language' and category_type = 'Intranet Skill Type'" -default 0]
set target_lang_skill_type [db_string target_lang "select category_id from im_categories where category = 'Target Language' and category_type = 'Intranet Skill Type'" -default 0]
set subject_area_skill_type [db_string target_lang "select category_id from im_categories where category = 'Subject Type' and category_type = 'Intranet Skill Type'" -default 0]

set skill_medium 2202


# ------------------------------------------------------------
# Render Report Header

ad_return_top_of_page "[im_header][im_navbar]"



for { set i 1} { $i < 13 } { incr i} {

    set sql "
	select	person_id,
		idiomas${i}_origen as source,
		idiomas${i}_destino as target,
		idiomas${i}_tarifa as tarif
	from
		persons
    "

    set cnt 0
    db_foreach sql $sql {
	
	if {$source == "" && $target == "" && $tarif == "" } { continue }

	set src [im_transform_language2iso639 $source]
	set tgt [im_transform_language2iso639 $target]
	
	ns_write "<li>$i: User=$person_id, $src -> $tgt: $tarif\n"

	if {"origen" == $src} { set src "" }
	if {"otros" == $src} { set src "" }
	if {[string length $src] > 5} { 
	    ns_write "<li>$i: User=$person_id, src=$src: skipping\n"
	    set src "" 
	}

	if {"destino" == $tgt} { set tgt "" }
	if {"otros" == $tgt} { set tgt "" }
	if {[string length $tgt] > 5} { 
	    ns_write "<li>$i: User=$person_id, tgt=$tgt: skipping\n"
	    set tgt "" 
	}

	set src_cat [db_string src "select category_id from im_categories where category = :src" -default 0]
	if {0 == $src_cat && $src != ""} { 
		ns_write "<li><font=red>Didn't find '$src'</font>\n"
	}
	set tgt_cat [db_string src "select category_id from im_categories where category = :tgt" -default 0]
	if {0 == $tgt_cat && $tgt != ""} { 
		ns_write "<li><font=red>Didn't find '$tgt'</font>\n"
	}

	set count [db_string cnt "
		select count(*) 
		from im_freelance_skills 
		where 
			user_id = :person_id
			and skill_type_id = $source_lang_skill_type
			and skill_id = :src_cat
	"]
	if {0 != $src_cat && 0 == $count} {
	    db_dml source "
		insert into im_freelance_skills (
			user_id, 
			skill_id, 
			skill_type_id, 
			confirmed_experience_id
		) values (
			:person_id, 
			:src_cat,
			$source_lang_skill_type,
			:skill_medium
		)
	    "
	}


	set count [db_string cnt "
		select count(*) 
		from im_freelance_skills 
		where 
			user_id = :person_id
			and skill_type_id = $target_lang_skill_type
			and skill_id = :tgt_cat
	"]
	if {0 != $tgt_cat && 0 == $count} {
	    db_dml source "
		insert into im_freelance_skills (
			user_id, 
			skill_id, 
			skill_type_id, 
			confirmed_experience_id
		) values (
			:person_id, 
			:tgt_cat,
			$target_lang_skill_type,
			:skill_medium
		)
	    "
	}
	

	if {0 != $src_cat && 0 != $tgt_cat && $tarif != "" && $tarif > 0} {

	    set companies [db_list cid "
		select	c.company_id
		from	im_companies c,
			acs_rels r
		where
			c.company_id = r.object_id_one
			and r.object_id_two = :person_id
	    "]

	    db_dml price_insert "
		insert into im_trans_prices (
		        price_id,
		        uom_id,
		        company_id,
		        task_type_id,
		        target_language_id,
		        source_language_id,
		        subject_area_id,
		        currency,
		        price,
		        note
		) values (
		        nextval('im_trans_prices_seq'),
		        [im_uom_s_word],
		        [lindex $companies 0],
		        null,
		        :tgt_cat,
		        :src_cat,
		        null,
		        'EUR',
		        :tarif,
		        null
	    )"

	}



	incr cnt
    }
}


# ------------------------------------------------------------
# Render Report Footer

ns_write [im_footer]


