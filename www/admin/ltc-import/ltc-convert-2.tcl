# /packages/intranet-core/www/admin/cleanup-demo/ltc-convert-2.tcl
#
# Copyright (C) 2004 ]project-open[
# The code is based on ArsDigita ACS 3.4
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
    Check that the LTC-Organiser tables are
    present in the curent database

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $return_url} { set return_url [ad_conn url] }

set page_title "LTC-Organiser Import"
set context_bar [im_context_bar $page_title]
set context ""

#------------------------------------------------------
# Country Code Conversion Function
#------------------------------------------------------

# Returns a ]po[ Country Code ("us", "de", ...) for LTC country names

db_dml country_code_ltc {
create or replace function im_country_code_from_ltc_country (varchar)
returns varchar as '
DECLARE
        row		RECORD;
	p_country	alias for $1;
	v_country	varchar;
	v_country_code	varchar;
BEGIN
    v_country = lower(p_country);
    IF v_country = ''germany'' THEN return ''de'';
    ELSIF v_country = ''belgium'' THEN return ''be'';
    ELSIF v_country = ''denmark'' THEN return ''dk'';
    ELSIF v_country = ''deutschland'' THEN return ''de'';
    ELSIF v_country = ''england'' THEN return ''uk'';
    ELSIF v_country = ''frankreich'' THEN return ''fr'';
    ELSIF v_country = ''great britain'' THEN return ''uk'';
    ELSIF v_country = ''liechtenstein'' THEN return ''li'';
    ELSIF v_country = ''luxembourg'' THEN return ''lu'';
    ELSIF v_country = ''niederlande'' THEN return ''nl'';
    ELSIF v_country = ''schweiz'' THEN return ''ch'';
    ELSIF v_country = ''usa'' THEN return ''us'';
    ELSE 
	select iso
	into v_country_code
	from country_codes
	where lower(country_name) = lower(v_country);

	return v_country_code;
    END IF;
END;' language 'plpgsql';
}

# ------------------------------------------------------------------
# Language Conversion Function
# ------------------------------------------------------------------

#  Returns a ]po[ catagory_id for a LTC language_id
# The conversion goes LTC-Name -> ISO Locale -> Category

db_dml language_id_ltc {
create or replace function im_language_id_from_ltc (integer)
returns varchar as '
DECLARE
	p_ltc_lang_id	alias for $1;

        row		RECORD;
	v_iso_locale	varchar;
	v_category_id	integer;
BEGIN
    select category
    into v_iso_locale
    from im_ltc_languages
    where ltc_language_id = p_ltc_lang_id;

    -- RAISE NOTICE ''im_language_id_from_ltc: v_iso_locale=%'', v_iso_locale;

    select category_id
    into v_category_id
    from im_categories
    where category = v_iso_locale
	  and category_type = ''Intranet Translation Language'';

    -- RAISE NOTICE ''im_language_id_from_ltc: category_id=%'', v_category_id;

    RETURN v_category_id;
END;' language 'plpgsql';
}

# Ignore error dropping the table...
catch {db_dml drop_ltc_languges "drop table im_ltc_languages"} errmsg

db_dml create_ltc_languages {
create table im_ltc_languages (
	ltc_language_id	 integer,
	ltc_name  varchar(100),
	category  varchar(100),
	constraint im_ltc_lang_un
	unique (ltc_language_id)
);
}


db_dml insert_ltc_languages {
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (-1,'Alle Sprachen',null);
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (0,'Somali','so');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (1,'Französisch','fr');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (2,'Englisch','en');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (3,'Spanisch','es');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (4,'Italienisch','it');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (5,'Deutsch','de');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (6,'Griechisch','el');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (7,'Türkisch','tr');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (8,'Chinese, Simplified','zh_cn');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (9,'Schwedisch',null);
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (10,'Chinese, Traditional','zh_tw');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (11,'Portugiesisch  (ltc_language_id, ltc_name, category) values  (Pt)','pt');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (12,'Slovakisch','sk');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (14,'Ungarisch','hu');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (16,'Russisch','ru');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (17,'Polnisch','pl');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (18,'Niederländisch','nl');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (19,'Arabisch','ar');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (24,'Catalan','ca');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (25,'Norwegisch','no');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (26,'Dänisch','da');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (27,'Rumänisch','ro');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (28,'Swahili','sw');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (29,'Japanisch','jp');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (30,'Mandarin','zh_cn');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (31,'Kantonesisch','zh_cn');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (32,'Finnisch','fi');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (33,'Estonian','et');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (34,'Afrikaans','af');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (35,'Portugiesisch (Br)','pt_BR');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (36,'Monolingual',null);
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (37,'Koreanisch','ko');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (39,'Indonesian','in');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (40,'Hebräisch','iw');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (41,'Thai','th');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (42,'Vietnamesisch','vi');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (43,'Latvian','lv');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (44,'Slovenisch','sl');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (46,'Serbisch','sr');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (47,'Lithuanian','lt');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (48,'Filipino','tl');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (49,'Farsi','fa');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (50,'Tschechisch','cs');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (51,'Flämisch','nl_BE');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (52,'Kroatisch','hr');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (53,'Serbokroatisch','sh');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (54,'Mazedonisch','mk');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (55,'Bulgarisch','bg');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (56,'Bosnisch','bs');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (57,'Moldawisch','mo');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (58,'Ukrainisch','ru_UA');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (59,'Weißrussisch','be');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (60,'Albanisch','sq');
}


catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'so','Intranet Translation Language','Somali');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'tr','Intranet Translation Language','Turkish');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sv','Intranet Translation Language','Swedish');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sk','Intranet Translation Language','Slovak');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'hu','Intranet Translation Language','Hungarian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'pl','Intranet Translation Language','Polish');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ar','Intranet Translation Language','Arabic');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sw','Intranet Translation Language','Swahili');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ca','Intranet Translation Language','Catalan');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'no','Intranet Translation Language','Norwegian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ro','Intranet Translation Language','Romanian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'jp','Intranet Translation Language','Japanese');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'fi','Intranet Translation Language','Finnish');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'et','Intranet Translation Language','Estonian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'af','Intranet Translation Language','Afrikaans');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ko','Intranet Translation Language','Korean');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'in','Intranet Translation Language','Indonesian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'iw','Intranet Translation Language','Hebrew');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'th','Intranet Translation Language','Thai');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'vi','Intranet Translation Language','Vietnamese');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'lv','Intranet Translation Language','Latvian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sl','Intranet Translation Language','Slovenian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sr','Intranet Translation Language','Serbian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'lt','Intranet Translation Language','Lithuanian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'tl','Intranet Translation Language','Tagalog');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'fa','Intranet Translation Language','Farsi');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'hr','Intranet Translation Language','Croatian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'nl_BE','Intranet Translation Language','Flamish');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sh','Intranet Translation Language','Serbo-Croatian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'mk','Intranet Translation Language','Macedonian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'bg','Intranet Translation Language','Bulgarian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'bs','Intranet Translation Language','Bosnian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'mo','Intranet Translation Language','Moldavian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ru_UA','Intranet Translation Language','Ukrainian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'be','Intranet Translation Language','Byelorussian');
" } errmsg

catch {db_dml insert_ltc_language_categories "
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sq','Intranet Translation Language','Albanian');
" } errmsg



# ----------------------------------------------------------------------------
# Contacts
# ----------------------------------------------------------------------------


#  Insert Client_Type into the categories table
# and make these type subtypes of "Customer".
catch {[db_dml category_client_type {
insert into im_categories (
	category_id,
	category,
	category_type
) select 
	nextval('im_categories_seq') as category_id,
	ct.type as category,
	'Intranet Company Type' as category_type
from
	"CLIENT_TYPE" ct;
} ] } errmsg



# Make the CLIENT_TYPEs subtype of "Customer"
catch {[db_dml category_client_type_customer {
insert into im_category_hierarchy (
	parent_id,
	child_id
) select
	57,
	c.category_id
from
	im_categories c,
	"CLIENT_TYPE" ct
where
	c.category = ct.type
	and c.category_type = 'Intranet Company Type';
} ] } errmsg


# Make the CLIENT_TYPEs subtype of "CustOrIntl"
catch {[db_dml category_client_type_cust_intl {
insert into im_category_hierarchy (
	parent_id,
	child_id
) select
	(select category_id from im_categories where category = 'CustOrIntl'),
	c.category_id
from
	im_categories c,
	"CLIENT_TYPE" ct
where
	c.category = ct.type
	and c.category_type = 'Intranet Company Type';
} ] } errmsg




# -------------------------------------------------------------------------------
# Client / Customer Conversion Function
# -------------------------------------------------------------------------------

catch {[db_dml import_clients {
create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
	v_office_id	integer;
	v_company_id	integer;
	v_organisation_name	varchar;
	v_duplicate_p	integer;
BEGIN
    for row in
        select * 
	from "CLIENT"
    loop
	RAISE NOTICE ''Client: %: %'', row.client_id, row.organisation_name;

	v_organisation_name = row.organisation_name;

	select count(*)
	into v_duplicate_p
	from im_companies c
	where trim(c.company_name) = trim(v_organisation_name);

	IF v_duplicate_p > 0 THEN
	    v_organisation_name = row.organisation_name || ''.'' || row.client_id;
	END IF;

	-- First create a new Main Office
	select im_office__new (
		null, ''im_office'',
		now()::date, 0, ''0.0.0.0'', null,
		v_organisation_name || '' Main Office '' || row.client_id,
		v_organisation_name || ''_office_path_'' || row.client_id,
		170, 160, null
	) into v_office_id;

	-- Then create the Comany (needs the Main Office)
	select im_company__new (
		null, ''im_company'', now()::date,
		0, ''0.0.0.0'', null, 
		v_organisation_name,
		v_organisation_name,
		v_office_id,
		57,
		46
	) into v_company_id;

	select main_office_id
	into v_office_id
	from im_companies
	where company_id = v_company_id;

	-- Set the company type
	update im_companies
	set company_type_id = (
		select category_id
		from	im_categories c,
			"CLIENT_TYPE" ct
		where	row.client_type_id = ct.client_type_id
			and ct.type = c.category)
	where company_id = v_company_id;

	-- Copy over all of the other fields
	update im_companies set 
		vat_number = row."VAT_number",
		note = row.comment,
		vat = row."VAT_rate"
	where company_id = v_company_id;

	-- Copy over all fields for the main office
	update im_offices set
		address_line1 = row.address,
		address_line2 = row.department,
		address_city = row.city,
		address_state = row.state,
		address_postal_code = row.postal_code,
		address_country_code = im_country_code_from_ltc_country (row.country)
	where office_id = v_office_id;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
} ] } errmsg



# -------------------------------------------------------------------------------
# Contacts Converion Functionality
# -------------------------------------------------------------------------------

catch {[db_dml ltc_contact_id "alter table persons add ltc_contact_id integer"]} errmsg


# Import Contacts
catch {[db_dml import_contacts {
create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
	v_user_id	integer;
	v_user_exists_p	integer;
	v_users_contact_count	integer;
	v_member_p	integer;
BEGIN
    for row in

	-- this query is complex because we have to deal with the cases
	-- that a single contact has zero or more the one emails.
	-- The coalesce(..) part build a default fallback logic in
	-- the case that there is no email..
	select	c.*,
		coalesce (comm_email, default_email) as email
	from	( select
			c.*,
			trim(cc.email) as comm_email,
			trim(c.firstname) || '' '' || trim(surname) || ''@'' || trim(c.firstname) || '' '' || trim(surname) as default_email
		from
			"CONTACT" c
			left outer join (
				select	max(value) as email,
					contact_id
				from	"CONTACT_COMMUNICATION"
				where	com_type_id = 3
				group by contact_id
			) cc on (c.contact_id = cc.contact_id)
		) c
	where
		1=1 or c.contact_id in (804, 813)
    loop

	RAISE NOTICE ''Start Loop: % %'', row.default_email, row.email;

	select count(*) 
	into v_user_exists_p
	from parties p
	where lower(trim(p.email)) = lower(trim(row.email));

	RAISE NOTICE ''Exists: %: %'', v_user_id, v_user_exists_p;

	-- Create User or get the existing user based on email
	IF v_user_exists_p = 0 THEN
	    -- Create the new user without a reasonable password
	    select acs__add_user(
                null,
                ''user'',
                now(),
                null,
                ''0.0.0.0'',
                null,
                row.firstname || '' '' || row.surname || ''.'' || row.contact_id,
                row.email,
                null,
                row.firstname,
                row.surname,
                ''password'',
                ''salt'',
                row.firstname || '' '' || row.surname || ''.'' || row.contact_id,
                ''f'',
                ''approved''
	    ) into v_user_id;

	    RAISE NOTICE ''Created the user => %'', v_user_id;

	ELSE

	    select party_id 
	    into v_user_id
	    from parties p
	    where lower(trim(p.email)) = lower(trim(row.email));

	    RAISE NOTICE ''Found existing user => %'', v_user_id;

	END IF;

	-- Add a reference to the LTC CONTACT table to persons
	update persons set
		ltc_contact_id = row.contact_id
	where
		person_id = v_user_id;

	select count(*)
	into v_users_contact_count
	from users_contact
	where user_id = v_user_id;

	RAISE NOTICE ''v_users_contact_count => %'', v_users_contact_count;

	RAISE NOTICE ''Treating contact_id % -> %: %'', row.contact_id, v_user_id, row.default_email;

	IF v_users_contact_count = 0 THEN
	    insert into users_contact (
		user_id
	    ) values (
		v_user_id
	    );
	END IF;

	update users_contact set
		wa_line1 = row.address,
		wa_line2 = row.building,
		wa_city = row.city,
		wa_state = row.state,
		wa_postal_code = row.postal_code,
		wa_country_code = im_country_code_from_ltc_country(row.country),
		note =	''Title: '' || row.title || 
			''\nOrganisation: '' || row.organisation_name ||
			''\nSalutation: '' || row.salutation
	where user_id = v_user_id;


	IF row.contact_type_id = 2 THEN

	    RAISE NOTICE ''Adding % to Freelancers, v_member_p=%'', v_user_id, v_member_p;

	    IF 0 = v_user_exists_p THEN
		PERFORM membership_rel__new(465, v_user_id);
	    END IF;

	ELSIF row.contact_type_id = 3 THEN

	    -- Customer
	    RAISE NOTICE ''Adding % to Customers, v_member_p=%'', v_user_id, v_member_p;

	    IF 0 = v_user_exists_p THEN
		PERFORM membership_rel__new(461, v_user_id);
	    END IF;

	END IF;

	-- Fields not treated yet:              
	-- web_password      | character varying(12)

	RAISE NOTICE ''End Loop'';

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
} ] } errmsg



# -------------------------------------------------------------------------------
# Translators Converion Functionality
# -------------------------------------------------------------------------------

catch {[db_dml alter_persons "alter table persons add ltc_translator_id integer"]} errmsg

# TRANSLATOR -> im_freelancers
catch {[db_dml translator_mother_tongue {
create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
	v_user_id	integer;
	v_mother_tongue_category_id	integer;
BEGIN
    FOR row IN
	select	t.*,
		p.person_id
	from	"TRANSLATOR" t
		left outer join persons p on (t.contact_id = p.ltc_contact_id)
    LOOP
	v_mother_tongue_category_id = im_language_id_from_ltc(row.mother_tongue_lang_id::integer);
	RAISE NOTICE ''Translator Start: %: mother_tongue=%/%'', row.contact_id, row.mother_tongue_lang_id, v_mother_tongue_category_id;
	IF row.person_id is not null AND v_mother_tongue_category_id is not null THEN
		insert into im_freelance_skills (
		    user_id, skill_id, skill_type_id
		) values (
		    row.person_id, v_mother_tongue_category_id, 2000
		);
		insert into im_freelance_skills (
		    user_id, skill_id, skill_type_id
		) values (
		    row.person_id, v_mother_tongue_category_id, 2002
		);
	END IF;
	-- ToDo: vat_rate -> freelance company
	-- Add a reference to "persons" to the ltc_translator_id
	-- for reverse lookup (slow but convenient)
	update persons 
	set ltc_translator_id = row.translator_id
	where person_id = row.person_id;
    END LOOP;

    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
} ] } errmsg



# TRANSLATOR_TARGET -> im_freelance_skill target languages

catch {[db_dml translator_target {
create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
	v_user_id	integer;
	v_lang_category_id	integer;
	v_entry_exists_p	integer;
BEGIN
    FOR row IN
	select	t.*,
		p.person_id
	from
		"TRANSLATOR_TARGET" t
		left outer join persons p on (t.translator_id = p.ltc_translator_id)
    LOOP
	v_lang_category_id = im_language_id_from_ltc(row.lang_id::integer);
	RAISE NOTICE ''Translator Target: %: target=%/%'', row.person_id, row.lang_id, v_lang_category_id;
	IF row.person_id is not null AND v_lang_category_id is not null THEN
		select count(*)
		into v_entry_exists_p
		from im_freelance_skills
		where	user_id = row.person_id
			and skill_id = v_lang_category_id
			and skill_type_id = 2002;
		IF 0 = v_entry_exists_p THEN
			insert into im_freelance_skills (
				user_id, skill_id, skill_type_id
			) values (
				row.person_id, v_lang_category_id, 2002
			);
		END IF;
		update im_freelance_skills set 
			claimed_experience_id = 2203,
			confirmed_experience_id = 2203,
			confirmation_user_id = 0
		where	user_id = row.person_id
			and skill_id = v_lang_category_id
			and skill_type_id = 2002;
	END IF;
    END LOOP;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
} ] } errmsg




# TRANSLATOR_SOURCE -> im_freelance_skill source languages
catch {[db_dml translator_source {
create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
	v_user_id	integer;
	v_lang_category_id	integer;
	v_entry_exists_p	integer;
BEGIN
    FOR row IN
	select	t.*,
		p.person_id
	from
		"TRANSLATOR_SOURCE" t
		left outer join persons p on (t.translator_id = p.ltc_translator_id)
    LOOP
	v_lang_category_id = im_language_id_from_ltc(row.lang_id::integer);
	RAISE NOTICE ''Translator Target: %: source=%/%'', row.person_id, row.lang_id, v_lang_category_id;
	IF row.person_id is not null AND v_lang_category_id is not null THEN
		select count(*)
		into v_entry_exists_p
		from im_freelance_skills
		where	user_id = row.person_id
			and skill_id = v_lang_category_id
			and skill_type_id = 2000;
		IF 0 = v_entry_exists_p THEN
			insert into im_freelance_skills (
				user_id, skill_id, skill_type_id
			) values (
				row.person_id, v_lang_category_id, 2000
			);
		END IF;
		update im_freelance_skills set 
			claimed_experience_id = 2203,
			confirmed_experience_id = 2203,
			confirmation_user_id = 0
		where	user_id = row.person_id
			and skill_id = v_lang_category_id
			and skill_type_id = 2000;
	END IF;
    END LOOP;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
} ] } errmsg


ad_return_complaint 1 OK
return



