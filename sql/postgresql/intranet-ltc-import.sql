-- /packages/intranet/sql/postgres/intranet-ltc-import.sql
--
-- Copyright (C) 1999-2005 ]project-open[
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author      frank.bergmann@project-open.com


---------------------------------------------------------------------------------
-- Comments
---------------------------------------------------------------------------------

-- Limits:
-- 
-- - Field Sizes:
--   LTC Organizer and ]project-open[ have different field
--   sizes. This should´t lead to issues with normal data,
--   but exceptionally long fields may caus an error.
-- 
-- - Countries:
--   LTC Organizier allows the user to specified country
--   names as a text field, while ]project-open[ requires 
--   unique country_code.
--   So spelling errors or non-English named countries will 
--   lead to empty country fields in ]project-open[.
--   
-- 
-- - Contact_type: 
--   1-User, 2-Provider, 3-Customer, 4-Other
--   is converted into 1-Registered User, 2-Freelancer,
--   3-Customer. These contact types are hard coded and 
--   can´t easily be changed.
-- 
-- - Employees and Senior managers are not fully treated.
--   You need to add manually additional privileges to these
--   user classes.
-- 
-- - Skipped:
--   The following tables are not (yet) imported into ]po[:
-- 	- Translator_Details: Few entries
-- 	- Translator_Software: Few entries
-- 	- Trans_Soft: Defines the types of Software 
-- 	  that a translator can install
-- 	- Trans_Soft_Source & Trans_Soft_Target:
-- 	  Source- and target language information for
-- 	  Trans_Soft. May be used to describe automatic
-- 	  translation software in more detail.

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
