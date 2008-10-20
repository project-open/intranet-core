---------------------------------------------------------------------------------
-- Comments
---------------------------------------------------------------------------------

Limits:

- Field Sizes:
  LTC Organizer and ]project-open[ have different field
  sizes. This should´t lead to issues with normal data,
  but exceptionally long fields may caus an error.

- Countries:
  LTC Organizier allows the user to specified country
  names as a text field, while ]project-open[ requires 
  unique country_code.
  So spelling errors or non-English named countries will 
  lead to empty country fields in ]project-open[.
  

- Contact_type: 
  1-User, 2-Provider, 3-Customer, 4-Other
  is converted into 1-Registered User, 2-Freelancer,
  3-Customer. These contact types are hard coded and 
  can´t easily be changed.

- Employees and Senior managers are not fully treated.
  You need to add manually additional privileges to these
  user classes.

- Conversion of workload_units to Unit or Measure:
  LTC "Lines" are translated into "Target-Lines" on ]po[,
  while LTC "Words" are translated into "Source-Words"
  because this is what we have seem most with our customers.
  Week, page, fixed price, and other units are translated
  into the ]po[ "unit".

- Skipped:
  The following tables are not (yet) imported into ]po[:
	- Translator_Details: Few entries
	- Translator_Software: Few entries
	- Trans_Soft: Defines the types of Software 
	  that a translator can install
	- Trans_Soft_Source & Trans_Soft_Target:
	  Source- and target language information for
	  Trans_Soft. May be used to describe automatic
	  translation software in more detail.



---------------------------------------------------------------------------------
-- Country Code Conversion Function
---------------------------------------------------------------------------------

-- Returns a ]po[ Country Code ("us", "de", ...) for LTC country names
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


---------------------------------------------------------------------------------
-- Language Conversion Function
---------------------------------------------------------------------------------

-- Returns a ]po[ catagory_id for a LTC language_id
-- The conversion goes LTC-Name -> ISO Locale -> Category
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


create table im_ltc_languages (
	ltc_language_id	 integer,
	ltc_name  varchar(100),
	category  varchar(100),
	constraint im_ltc_lang_un
	unique (ltc_language_id)
);

drop table im_ltc_languages;
select * from im_ltc_languages;

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


INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'so','Intranet Translation Language','Somali');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'tr','Intranet Translation Language','Turkish');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sv','Intranet Translation Language','Swedish');

insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (10,'Chinese, Traditional','zh_tw');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (11,'Portugiesisch  (ltc_language_id, ltc_name, category) values  (Pt)','pt');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (12,'Slovakisch','sk');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (14,'Ungarisch','hu');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (16,'Russisch','ru');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (17,'Polnisch','pl');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (18,'Niederländisch','nl');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (19,'Arabisch','ar');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sk','Intranet Translation Language','Slovak');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'hu','Intranet Translation Language','Hungarian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'pl','Intranet Translation Language','Polish');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ar','Intranet Translation Language','Arabic');


insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (24,'Catalan','ca');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (25,'Norwegisch','no');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (26,'Dänisch','da');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (27,'Rumänisch','ro');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (28,'Swahili','sw');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (29,'Japanisch','jp');


INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sw','Intranet Translation Language','Swahili');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ca','Intranet Translation Language','Catalan');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'no','Intranet Translation Language','Norwegian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ro','Intranet Translation Language','Romanian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'jp','Intranet Translation Language','Japanese');


insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (30,'Mandarin','zh_cn');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (31,'Kantonesisch','zh_cn');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (32,'Finnisch','fi');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (33,'Estonian','et');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (34,'Afrikaans','af');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (35,'Portugiesisch (Br)','pt_BR');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (36,'Monolingual',null);
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (37,'Koreanisch','ko');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (39,'Indonesian','in');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'fi','Intranet Translation Language','Finnish');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'et','Intranet Translation Language','Estonian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'af','Intranet Translation Language','Afrikaans');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ko','Intranet Translation Language','Korean');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'in','Intranet Translation Language','Indonesian');


insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (40,'Hebräisch','iw');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (41,'Thai','th');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (42,'Vietnamesisch','vi');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (43,'Latvian','lv');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (44,'Slovenisch','sl');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (46,'Serbisch','sr');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (47,'Lithuanian','lt');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (48,'Filipino','tl');
insert into im_ltc_languages (ltc_language_id, ltc_name, category) values  (49,'Farsi','fa');

 
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'iw','Intranet Translation Language','Hebrew');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'th','Intranet Translation Language','Thai');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'vi','Intranet Translation Language','Vietnamese');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'lv','Intranet Translation Language','Latvian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sl','Intranet Translation Language','Slovenian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sr','Intranet Translation Language','Serbian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'lt','Intranet Translation Language','Lithuanian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'tl','Intranet Translation Language','Tagalog');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'fa','Intranet Translation Language','Farsi');


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

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'cs','Intranet Translation Language','Czech');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'hr','Intranet Translation Language','Croatian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'nl_BE','Intranet Translation Language','Flamish');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sh','Intranet Translation Language','Serbo-Croatian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'mk','Intranet Translation Language','Macedonian');

INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'bg','Intranet Translation Language','Bulgarian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'bs','Intranet Translation Language','Bosnian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'mo','Intranet Translation Language','Moldavian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ru_UA','Intranet Translation Language','Ukrainian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'be','Intranet Translation Language','Byelorussian');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'sq','Intranet Translation Language','Albanian');



INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'is','Intranet Translation Language','Islandic');
INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'ms_MY','Intranet Translation Language','Malaysian');


---------------------------------------------------------------------------------
-- Contacts
---------------------------------------------------------------------------------


-- Insert Client_Type into the categories table
-- and make these type subtypes of "Customer".
insert into im_categories (
	category_id,
	category,
	category_type
) select 
	nextval('im_categories_seq') as category_id,
	ct.type as category,
	'Intranet Company Type' as category_type
from
	"CLIENT_TYPE" ct
;

-- Make the CLIENT_TYPEs subtype of "Customer"
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
	and c.category_type = 'Intranet Company Type'
;

-- Make the CLIENT_TYPEs subtype of "CustOrIntl"
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
	and c.category_type = 'Intranet Company Type'
;



---------------------------------------------------------------------------------
-- Client / Customer Conversion Function
---------------------------------------------------------------------------------

alter table im_companies add ltc_company_id integer;

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
		vat = row."VAT_rate",
		ltc_company_id = row.client_id
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




-- Checkout the "LIST_CONTACT" function from LTC.
-- I guess that it has to do with who should be able
-- to see a contact? But it doesn't seem to be used
-- much though...
select
	cc.client_id,
	cc.organisation_name,
	lc.*,
	c.firstname,
	c.surname,
	c.organisation_name
from
	"CLIENT" cc,
	"LIST_CONTACT" lc,
	"CONTACT" c
where 
	cc.list_contact_id = lc.list_contact_id
	and lc.contact_id = c.contact_id
;

-- Retro-Fit the companies with a "ltc_company_id" so that we can use
-- them as a base to setup the company-user relationship
update im_companies 
set ltc_company_id = (
	select client_id
	from "CLIENT" c
	where organisation_name = company_name
	and trim(lower(organisation_name)) not in (
		'ahr service gmbh & co. kg',
		'ls language services gmbh'
	)
);




---------------------------------------------------------------------------------
-- Contacts Converion Functionality
---------------------------------------------------------------------------------

-- Inquire about the email address for a contact
select
	c.*,
	coalesce (comm_email, default_email) as email
from
	( select
		c.*,
		c.firstname || ' ' || surname as name,
		cc.email as comm_email,
		c.firstname || ' ' || surname || '@' || c.firstname || ' ' || surname as default_email
	from
		"CONTACT" c
		left outer join (
			select	max(value) as email,
				contact_id
			from	"CONTACT_COMMUNICATION"
			where	com_type_id = 3
			group by 
				contact_id
		) cc on (c.contact_id = cc.contact_id)
	) c
where
	c.contact_id = 813
;

alter table persons add ltc_contact_id integer;


-- Import Contacts
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



-- Contact Communication - fax, tel and mobile
create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
BEGIN
    FOR row IN
	select	cc.*,
		c.firstname, c.surname,
		p.person_id
	from	"CONTACT_COMMUNICATION" cc
		left outer join persons p on (cc.contact_id = p.ltc_contact_id),
		"CONTACT" c
	where	cc.contact_id = c.contact_id
    LOOP
	IF row.person_id is null THEN
		RAISE NOTICE ''Relationship: Person=% % does not enter'', row.firstname, row.surname;
	ELSE
		IF row.com_type_id = 1 THEN
			update users_contact
			set work_phone = row.value
			where user_id = row.person_id;
		ELSIF row.com_type_id = 2 THEN
			update users_contact
			set fax = row.value
			where user_id = row.person_id;
		ELSIF row.com_type_id = 4 THEN
			update users_contact
			set cell_phone = row.value
			where user_id = row.person_id;
		END IF;
	END IF;
    END LOOP;

    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();








Old Telephone numbers
 user_id |    work_phone
---------+-------------------
   12882 | +56 32 83 93 70
   12872 | 3456345
   12670 | +49 8104 888811
   13146 | +49 2203 44153
   15793 | 0711 6566840
   15967 | +39 0583462055
   14456 | 09905 707395
   18249 | 0221/2812999
   16903 | 05619219403
   12623 | +49 89 581480 00
   15817 | 04298697172
   13127 | +49 2203 44 464
   15952 | 0039019813300
   15400 | +49 69 2690 0747
   16696 | (030) 30 20 18 76
   15121 | +49.8104.888733


 user_id |   cell_phone
---------+-----------------
   12670 | +49 173 3690601
   13146 | +49 173 2553252
   15793 | 0172 9468035
   15967 | +39 3280589605
   14456 | 0151 15565905
   18249 | 0176/23273207
   14411 | 0415523273
   15817 | 01732013042
   15952 | 3485929020
   16696 | 0177-3 19 11 64
   15121 | +49.1728619938


 user_id |       fax
---------+------------------
   12670 | +49 8104 888812
   13146 | +49 2203 44200
   15793 | 0711 6566850
   14456 | 09905 707396
   18249 | 06221/323278
   16903 | 05619219404
   12623 | +49 89 581480 01
   13127 | +49 2203 44 200
   15952 | 003902700535034
   15121 | +49.8104.888734




---------------------------------------------------------------------------------
-- Translators Converion Functionality
---------------------------------------------------------------------------------

alter table persons add ltc_translator_id integer;

-- TRANSLATOR -> im_freelancers
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



-- TRANSLATOR_TARGET -> im_freelance_skill target languages
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



-- TRANSLATOR_SOURCE -> im_freelance_skill source languages
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



---------------------------------------------------------------------------------
-- Price Conversion Function
---------------------------------------------------------------------------------

-- Returns a ]po[ UoM ID (Hour, S-Word, ...) for LTC "Workload_unit"
create or replace function im_uom_from_ltc_workload_unit (integer)
returns integer as '
DECLARE
	p_unit		alias for $1;
BEGIN
    -- 1000 Words
    IF p_unit = 1 THEN return (select category_id from im_categories where category = ''1000 W'');
    -- Page
    ELSIF p_unit = 2 THEN return 323;
    -- Hour
    ELSIF p_unit = 3  THEN return 320;
    -- LTC-Line -> T-Line
    ELSIF p_unit = 4  THEN return 327;
    -- LTC-World -> S-Word
    ELSIF p_unit = 5 THEN return 324;
    -- Day
    ELSIF p_unit = 6 THEN return 321;
    -- Everything else -> Unit
    ELSE
	return 322;
    END IF;
END;' language 'plpgsql';

select im_category_from_id(im_uom_from_ltc_workload_unit(2));



INSERT INTO im_categories (category_id, category, category_type,category_description) VALUES
(nextval('im_categories_seq'),'1000 W','Intranet UoM','1000 Words');



-- Create a provider for each translator
create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
        rel_row		RECORD;

	v_user_id	integer;
	v_office_id	integer;
	v_company_id	integer;
	v_organisation_name	varchar;
	v_organisation_path	varchar;
	v_duplicate_p	integer;

	v_user_exists_p	integer;
	v_users_contact_count	integer;
	v_member_p	integer;
BEGIN
    FOR row IN
	select	t.*,
		uc.*,
		p.*
	from
		"TRANSLATOR" t
		left outer join persons p on (t.contact_id = p.ltc_contact_id)
		left outer join users_contact uc on (p.person_id = uc.user_id)
		left outer join cc_users u on (u.user_id = p.person_id)
	where
		t.translator_id >= 0
    LOOP
	RAISE NOTICE ''Translator->Freelance Start: %'', row.contact_id;

	v_organisation_name = ''Freelance '' || im_name_from_user_id(row.person_id);
	v_organisation_path = translate(lower(v_organisation_name), '' '', ''_'');

	IF v_organisation_name is null THEN
		RAISE NOTICE ''Translator: Found null organisation name'';
	ELSE

	select count(*)
	into v_duplicate_p
	from im_companies c
	where lower(trim(c.company_name)) = lower(trim(v_organisation_name));

	IF v_duplicate_p = 0 THEN

		RAISE NOTICE ''Translator: New Org: %'', v_organisation_name;

		-- First create a new Main Office
		select im_office__new (
			null, ''im_office'',
			now()::date, 0, ''0.0.0.0'', null,
			v_organisation_name || '' Main Office '',
			v_organisation_path,
			170, 160, null
		) into v_office_id;

		-- Then create the Comany (needs the Main Office)
		select im_company__new (
			null, ''im_company'', now()::date,
			0, ''0.0.0.0'', null, 
			v_organisation_name,
			v_organisation_path,
			v_office_id,
			58,
			46
		) into v_company_id;
	ELSE
		RAISE NOTICE ''Translator: Existing Org: %'', v_organisation_name;

		select office_id
		into v_office_id
		from im_offices
		where lower(trim(office_path)) = lower(trim(v_organisation_path));

		select company_id
		into v_company_id
		from im_companies
		where lower(trim(company_path)) = lower(trim(v_organisation_path));

	END IF;

	-- Copy over all of the other fields
	update im_companies set 
		vat = row.vat_rate,
		primary_contact_id = row.person_id,
		accounting_contact_id = row.person_id
	where company_id = v_company_id;

	-- Copy over all fields for the main office
	update im_offices set
		address_line1 = row.wa_line1,
		address_line2 = row.wa_line2,
		address_city = row.wa_city,
		address_state = row.wa_state,
		address_postal_code = row.wa_postal_code,
		address_country_code = row.wa_country_code
	where office_id = v_office_id;

	IF v_company_id is null THEN
		RAISE NOTICE ''Translator: v_company_id is NULL'';
	ELSE

	RAISE NOTICE ''Translator: Delete previous relationships'';
	for rel_row in
                select
                        object_id_one as object_id,
                        object_id_two as user_id
                from
                        acs_rels r
                where   r.object_id_one = v_company_id
                        and r.object_id_two = row.person_id
        loop
                PERFORM im_biz_object_member__delete(rel_row.object_id, rel_row.user_id);
        end loop;

	RAISE NOTICE ''Translator: Add rel between % and %'', v_company_id, row.person_id;
	PERFORM im_biz_object_member__new (
          null,
          ''im_biz_object_member'',
          v_company_id,
          row.person_id,
          1300,
          null,
          ''0.0.0.0''
	);

	END IF;

	END IF;

    END LOOP;

    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- Insert translation prices into price list
create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
BEGIN
    FOR row IN

	select
		c.company_id,
		tf.translator_id,
		tf.unit_value,
		tf.source_lang_id::integer as ltc_source_lang_id,
		tf.target_lang_id::integer as ltc_target_lang_id,
		tf.workload_unit_id::integer as ltc_workload_unit_id,
		wt.type as ltc_work_type,
		im_language_id_from_ltc(tf.source_lang_id::integer) as source_lang_id,
		im_language_id_from_ltc(tf.target_lang_id::integer) as target_lang_id,
		im_uom_from_ltc_workload_unit(tf.workload_unit_id::integer) as uom_id,
		p.*
	from
		im_companies c,
		"WORK_TYPE" wt,
		"TRANSLATOR_FEE" tf
		LEFT OUTER JOIN persons p on (tf.translator_id = p.ltc_translator_id)
	where
		tf.work_type_id = wt.work_type_id
		and c.primary_contact_id = p.person_id
		and unit_value is not null

    LOOP
	RAISE NOTICE ''Price: Person=%, Source=%, Target=%, Unit=%, Value=%'', row.person_id, row.source_lang_id, row.target_lang_id, row.uom_id, row.unit_value;

	insert into im_trans_prices (
		price_id,
		uom_id,
		company_id,
		task_type_id,
		target_language_id,
		source_language_id,
		subject_area_id,
		valid_from,
		valid_through,
		currency,
		price,
		note
	) values (
		nextval(''im_trans_prices_seq''),
		row.uom_id,
		row.company_id,
		null,
		row.target_lang_id,
		row.source_lang_id,
		null,
		null,
		null,
		''EUR'',
		row.unit_value,
		row.ltc_work_type
	);
	
    END LOOP;

    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();







---------------------------------------------------------------------------------
-- Company - User relationship
---------------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        row		RECORD;
BEGIN
    FOR row IN

	select
		ic.company_id,
		ic.company_name,
		p.person_id,
		c.firstname,
		c.surname
	from
		"CLIENT" cc,
		"LIST_CONTACT" lc,
		"CONTACT" c,
		im_companies ic,
		persons p
	where 
		cc.list_contact_id = lc.list_contact_id
		and lc.contact_id = c.contact_id
		and ic.ltc_company_id = cc.client_id
		and c.contact_id = p.ltc_contact_id

    LOOP
	RAISE NOTICE ''Relationship: Person=% % %, Company=% %'', row.person_id, row.firstname, row.surname, row.company_id, row.company_name;
	
	perform im_biz_object_member__delete(
		row.company_id, 
		row.person_id
	);

	perform im_biz_object_member__new (
          null,
          ''im_biz_object_member'',
          row.company_id,
          row.person_id,
          1300,
          0, ''0.0.0.0''
      );

    END LOOP;

    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


