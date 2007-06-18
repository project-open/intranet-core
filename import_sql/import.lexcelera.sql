
---------------------------------------------------------------------------------
-- Companies and Offices
---------------------------------------------------------------------------------

-- Check for duplicate Company Names
--
select * from (select count(*) as cnt, "CompNm" from "tblCompMaster" group by "CompNm") t where cnt > 1;


create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;

	v_office_postfix	varchar;
	v_office_name		varchar;
	v_office_id		integer;
	v_office_status_id	integer;
	v_office_type_id	integer;
	v_country_code		varchar;

	v_company_id		integer;
	v_company_status_id	integer;
	v_company_type_id	integer;
	v_company_sector_id	integer;
	v_sales_potential_id	integer;
	v_company_referral_source_id	integer;
BEGIN
    for row in
        select	*,
		a."CompID" as company_id,
		a."AddNum" as address_num,
		m."CompNm" as company_name,
		a."Active" as office_active_p,
		m."Active" as company_active_p
	from
		"tblCompMaster" m
		LEFT OUTER JOIN "tblCompAdd" a ON (m."CompID" = a."CompID")
	where
		m."CompNm" is not NULL
	LIMIT 0
    loop
	IF row.address_num is NULL OR row.address_num = 1 
	THEN v_office_postfix := '' Main Office ''; 
	ELSE v_office_postfix := '' Office #'' || row.address_num || '' ''; 
	END IF;

	v_office_name := row.company_name || v_office_postfix;

	RAISE NOTICE ''office_name = %, company=%, postfix=%'', v_office_name, row.company_name, v_office_postfix;

        select office_id into v_office_id
        from im_offices o where lower(trim(o.office_name)) = lower(trim(v_office_name));

        select company_id into v_company_id
        from im_companies c where lower(trim(c.company_name)) = lower(trim(row.company_name));

        IF v_office_id is NULL THEN
	        select im_office__new (
	                null, ''im_office'',
	                now()::date, 0, ''0.0.0.0'', null,
	                v_office_name,
			lower(trim(replace(v_office_name, '' '', ''_''))),
	                170, 160, null
	        ) into v_office_id;
        END IF;

        IF v_company_id is NULL THEN
		select im_company__new (
			null, ''im_company'', now()::date,
			0, ''0.0.0.0'', null, 
			row.company_name,
			lower(trim(replace(row.company_name, '' '', ''_''))),
			v_office_id,
			57,
			46
		) into v_company_id;
        END IF;

	v_company_status_id := 46;
	IF false = row.company_active_p THEN v_company_status_id := 48; END IF;
	v_company_type_id := 57;

	v_office_status_id := 160;
	IF false = row.office_active_p THEN v_office_status_id := 161; END IF;
	v_office_type_id := 170;
	IF false = row."IsMain" THEN v_office_type_id := 171; END IF;

	select	iso into v_country_code
	from	country_codes cc,
		"lktblCountry" lc
	where	lower(cc.country_name) = lower(lc."CountryNmDisplay")
		and lc."CountryID" = row. "CountryID";

	select	category_id into v_company_sector_id
	from	im_categories 
	where	category_type = ''Intranet Company Sector''
		and aux_int1 = row."CompSectorID";

	select	category_id into v_sales_potential_id
	from	im_categories 
	where	category_type = ''Intranet Company Sales Potential''
		and aux_int1 = row."ClassificationID";

	select	category_id into v_company_referral_source_id
	from	im_categories 
	where	category_type = ''Intranet Company Referral Type''
		and aux_int1 = row."CompSourceID";

	RAISE NOTICE ''Cli:%, Addr:%, Off:%, Comp:%, oid:%, cid:%, cc:%, sales:%'', 
	row.company_id, row.address_num, v_office_postfix, row.company_name, v_office_id, v_company_id,
	v_country_code, v_sales_potential_id;

	update im_companies set
		note =	coalesce(row."CompDesc", '''') || '' '' || 
			coalesce(row."RefFileDir", ''''),
		company_status_id = v_company_status_id,
		vat_number = row."VATNumber",
		provider_number = row."SupplierNumber",
		company_sector_id = v_company_sector_id,
		sales_potential_id = v_sales_potential_id,
		referral_type_id = v_company_referral_source_id,
		lxc_company_id = row."CompID"
	where	company_id = v_company_id;

	update im_offices set
		company_id = v_company_id,
		note = trim(
			coalesce(row."AddressTo", '''') || '' '' || 
			coalesce(row."AddInfo", '''') || '' '' || 
			coalesce(row."StProv", '''')
		),
		office_status_id = v_office_status_id,
		office_type_id = v_office_type_id,
		address_line1 = row."Add",
		address_line2 = row."Add2",
		address_city = row."City",
		address_postal_code = row."CodePost",
		address_country_code = v_country_code
	where	office_id = v_office_id;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Not Used: CompMaster
--  IsSubclient			boolean
--  DeactivateReasonID		smallint	
--  SpecID			integer
--  MainContCompID		integer
--  SourceRefID			integer
--  SpokenLangID		smallint	
--  PrintLangGrpID		smallint	
--  RequirePurchaseOrder	boolean
--  BlockInactive		boolean
--  MatUserID			smallint	
--  MatDte			timestamp without time zone
-- 
-- 
-- Not Used: CompAdd
--  Ced				boolean	
--  CedNum			smallint
--  CompTypeID			smallint	-- 0=general, 1=individual, 2=tran: Not very useful...
--  CoordTypeID			smallint	
--  UseDataGrpNmInAddressTo	boolean
--  ForCompAcctIDOnly		integer
--  MatUserID			smallint	
--  MatDte			timestamp without time zone
--  JobDir			varchar		-- company_path = replace(row."JobDir", ''/'', ''''),





---------------------------------------------------------------------------------
-- tblCon* - Contacts
---------------------------------------------------------------------------------


create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_contact_name		varchar;
	v_contact_email		varchar;
	v_user_id		integer;
	v_member_p		integer;
	v_ucont_exists_p	integer;
BEGIN
    for row in
	select	*
	from	"tblContMaster"
	where	"FirstNm" is not null and "LastNm" is not null
	LIMIT 1000000
    loop
	v_contact_name = row."FirstNm"|| '' '' ||row."LastNm";
	v_contact_email := lower(row."FirstNm"||''.''||row."LastNm"||''@nowhere.com'');

	select	person_id into v_user_id from persons p
	where	lower(trim(p.first_names)) = lower(trim(row."FirstNm")) and
		lower(trim(p.last_name)) = lower(trim(row."LastNm"));

	-- Create User or get the existing user based on email
	IF v_user_id is NULL THEN
	    -- Create the new user without a reasonable password
	    select acs__add_user(
		null, ''user'', now(), null, ''0.0.0.0'', null,
		row."FirstNm" || '' '' || row."LastNm" || ''.'' || row."ContID",
		v_contact_email, null, row."FirstNm", row."LastNm",
		''password'', ''salt'',
		row."FirstNm" || '' '' || row."LastNm" || ''.'' || row."ContID",
		''f'', ''approved''
	    ) into v_user_id;

	    select count(*) into v_ucont_exists_p from users_contact
	    where user_id = v_user_id;
	    IF 0 = v_ucont_exists_p THEN 
		insert into users_contact(user_id) values (v_user_id);
	    END IF;

	    select count(*) into v_member_p from group_distinct_member_map 
	    where member_id = v_user_id and group_id=461;
            IF 0 = v_member_p THEN
                PERFORM membership_rel__new(461, v_user_id);
            END IF;

	    RAISE NOTICE ''Created the customer contact: %'', v_user_id;
	END IF;	

	-- Update the person contact_id to find it later.
	update persons set
		lxc_contact_id = row."ContID"
	where person_id = v_user_id;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Relationship between company and contact
create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_user_id		integer;
	v_company_id		integer;
	v_rel_exists_p		integer;
BEGIN
    for row in
	select	*
	from	"tblContComp" cc,
		"tblContMaster" m
	where	
		cc."ContID" != 0
		and cc."ContID" = m."ContID"
		and m."FirstNm" is not null
		and m."LastNm" is not null
    loop
	select	person_id into v_user_id
	from	persons where lxc_contact_id = row."ContID";

        select  company_id into v_company_id
        from    im_companies
        where	lxc_company_id = row."CompID";

	select	count(*) into v_rel_exists_p
	from	acs_rels
	where	object_id_one = v_company_id
		and object_id_two = v_user_id;

	IF 0 = v_rel_exists_p AND v_user_id is not NULL THEN
	    RAISE NOTICE ''Create new rel: comp=%, user=%/% '', v_company_id, row."ContID", v_user_id;
	    perform im_biz_object_member__new (
		null,
		''im_biz_object_member'',
		v_company_id,
		v_user_id,
		1300,
		0, ''0.0.0.0''
	    );
	END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






---------------------------------------------------------------------------------
-- tblCompWeb - Attach items to company as im_note
---------------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_company_id		integer;
	v_note_id		integer;
	v_note_type_id		integer;
	v_note_text		text;
BEGIN
    for row in
        select	*
	from	"tblCompWeb"
	LIMIT 0
    loop
	select	company_id into v_company_id
	from	im_companies 
	where lxc_company_id = row."CompID";

	select	category_id into v_note_type_id
	from	im_categories 
	where	aux_int1 = row."CoordTypeID"
		and category_type = ''Intranet Notes Type'';

	RAISE NOTICE ''Note: comp=%, cid=%, type=%, tid=%'', 
	row."CompID", v_company_id, row."CoordTypeID", v_note_type_id;

	v_note_text :=	replace(coalesce(row."WebAdd", ''''), '' '', ''_'') || '' '' || 
			coalesce(row."WebNotes", '''');

	select	note_id into v_note_id
	from	im_notes
	where	object_id = v_company_id
		and note = v_note_text;

	IF v_note_id is NULL THEN
	    v_note_id := im_note__new(
		null, ''im_note'', now(),
		624, ''0.0.0.0'', null, 
		v_note_text,
		v_company_id,
		v_note_type_id, 11400
	    );
	END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




---------------------------------------------------------------------------------
-- tblCompPhone - Phone Numbers
---------------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_company_id		integer;
	v_note_id		integer;
	v_note_type_id		integer;
	v_note_text		text;
BEGIN
    for row in
        select	*
	from	"tblCompPhon"
	where	"CoordTypeID" != 0
	LIMIT 100000
    loop
	select	company_id into v_company_id
	from	im_companies 
	where lxc_company_id = row."CompID";

	select	category_id into v_note_type_id
	from	im_categories 
	where	aux_int1 = row."CoordTypeID"
		and category_type = ''Intranet Notes Type'';

	RAISE NOTICE ''Note: comp=%, cid=%, type=%, tid=%'', 
	row."CompID", v_company_id, row."CoordTypeID", v_note_type_id;

	v_note_text :=	row."Phone" || '' '' || coalesce(row."PhonNotes", '''');

	select	note_id into v_note_id
	from	im_notes
	where	object_id = v_company_id and note = v_note_text;

	IF v_note_id is NULL THEN
	    v_note_id := im_note__new(
		null, ''im_note'', now(),
		624, ''0.0.0.0'', null, 
		v_note_text,
		v_company_id,
		v_note_type_id, 11400
	    );
	END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






---------------------------------------------------------------------------------
-- tblCompNotes - Notes for companies
---------------------------------------------------------------------------------



create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_company_id		integer;
	v_topic_id		integer;
	v_note_text		text;
	v_subject		text;
	v_person_id		integer;
BEGIN
    for row in
        select	*
	from	"tblCompNote"
    loop
	select	company_id into v_company_id
	from	im_companies where lxc_company_id = row."CompID";

	select	person_id into v_person_id
	from	persons where lxc_user_id = row."MatUserID";
	IF v_person_id is NULL THEN v_person_id = 624; END IF;

	v_note_text :=	coalesce(row."Note", ''Note ''||row."NoteID"::varchar);

	select	topic_id into v_topic_id
	from	im_forum_topics
	where	object_id = v_company_id
		and message = v_note_text;

	RAISE NOTICE ''Note: comp=%, cid=%'', 
	row."CompID", v_company_id;

	IF v_topic_id is NULL THEN
	    insert into im_forum_topics (
		topic_id, object_id,
		topic_type_id, topic_status_id,
		posting_date,
		owner_id,
		scope,
		subject,
		message,
		due_date
	    ) values (
		nextval(''im_forum_topics_seq''), v_company_id,
		1108, 1200,
		row."MatDte"::date,
		v_person_id,
		''group'',
		substring(v_note_text for 60),
		v_note_text,
		row."FollowUpDte"
	    );
	END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






---------------------------------------------------------------------------------
-- tblUsers - in-house users
---------------------------------------------------------------------------------

-- Employees
create or replace function inline_0 ()
returns integer as '
DECLARE
	row				RECORD;
	v_user_id			integer;
	v_user_email			varchar;
	v_ucont_exists_p		integer;
	v_member_p			integer;
BEGIN
    for row in
	select	*
	from	"tblUsers"
	where	"LastNm" is not NULL and "FirstNm" is not NULL
	LIMIT 1000
    loop
	select	party_id into v_user_id from parties pa
	where	lower(trim(pa.email)) = lower(trim(row."UserEmail"));

	IF v_user_id is NULL THEN
		select	person_id into v_user_id from persons p
		where	lower(trim(p.first_names)) = lower(trim(row."FirstNm")) and
			lower(trim(p.last_name)) = lower(trim(row."LastNm"));
	END IF;

	v_user_email := row."UserEmail";
	IF v_user_email is NULL OR '''' = v_user_email THEN
		v_user_email := lower(row."FirstNm"||''.''||row."LastNm"||''@nowhere.com'');
	END IF;

	-- Create User or get the existing user based on email
	IF v_user_id is NULL THEN
	    -- Create the new user without a reasonable password
	    select acs__add_user(
		null, ''user'', now(), null, ''0.0.0.0'', null,
		row."FirstNm" || '' '' || row."LastNm" || ''.'' || row."UserID",
		v_user_email, null, row."FirstNm", row."LastNm",
		''password'', ''salt'',
		row."FirstNm" || '' '' || row."LastNm" || ''.'' || row."UserID",
		''f'', ''approved''
	    ) into v_user_id;

	    select count(*) into v_ucont_exists_p from users_contact
	    where user_id = v_user_id;
	    IF 0 = v_ucont_exists_p THEN 
		insert into users_contact(user_id) values (v_user_id);
	    END IF;

	    RAISE NOTICE ''Created the user => %'', v_user_id;
	END IF;	

	-- Make user a member of Freelancers
	select count(*) into v_member_p from group_distinct_member_map where member_id=v_user_id and group_id=463;
	IF 0 = v_member_p THEN
	    PERFORM membership_rel__new(463, v_user_id);
	END IF;

	update persons set
		lxc_user_id = row."UserID"
	where person_id  = v_user_id;

	update users_contact set
		work_phone = row."UserPhone",
		fax = row."UserFax"
	where user_id = v_user_id;

	RAISE NOTICE ''Users: uid:%, name=% %'', v_user_id, row."FirstNm", row."LastNm";
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- Translators
create or replace function inline_0 ()
returns integer as '
DECLARE
	row				RECORD;
	v_user_id			integer;
	v_user_email			varchar;
	v_ucont_exists_p		integer;
	v_member_p			integer;

	v_office_postfix		varchar;
	v_office_name			varchar;
	v_office_id			integer;
	v_office_status_id		integer;
	v_office_type_id		integer;
	v_country_code			varchar;

	v_company_id			integer;
	v_company_name			varchar;
	v_company_status_id		integer;
	v_company_type_id		integer;
	v_company_sector_id		integer;
	v_sales_potential_id		integer;
	v_company_referral_source_id	integer;
BEGIN
    for row in
	select	*,
		a."Active" as office_active_p,
		t."Active" as company_active_p
	from	"tblTranMaster" t,
		"tblTranAdd" a
	where
		t."TranID" = a."TranID"
		and "LastNm" is not NULL 
		and "FirstNm" is not NULL
	LIMIT 0
    loop
	v_user_email := lower(row."FirstNm"||''.''||row."LastNm"||''@nowhere.com'');

	select	person_id into v_user_id from persons p
	where	lower(trim(p.first_names)) = lower(trim(row."FirstNm")) and
		lower(trim(p.last_name)) = lower(trim(row."LastNm"));

	-- Create User or get the existing user based on email
	IF v_user_id is NULL THEN
	 -- Create the new user without a reasonable password
	 select acs__add_user(
		null, ''user'', now(), null, ''0.0.0.0'', null,
		row."FirstNm" || '' '' || row."LastNm" || ''.'' || row."TranID",
		v_user_email, null, row."FirstNm", row."LastNm",
		''password'', ''salt'',
		row."FirstNm" || '' '' || row."LastNm" || ''.'' || row."TranID",
		''f'', ''approved''
	 ) into v_user_id;

	 select count(*) into v_ucont_exists_p from users_contact
	 where user_id = v_user_id;
	 IF 0 = v_ucont_exists_p THEN 
		insert into users_contact(user_id) values (v_user_id);
	 END IF;
	 RAISE NOTICE ''Created the user => %'', v_user_id;
	END IF;	

	-- Make user a member of "Freelancers"
	select count(*) into v_member_p from group_distinct_member_map where member_id=v_user_id and group_id=465;
	IF 0 = v_member_p THEN
	    PERFORM membership_rel__new(465, v_user_id);
	END IF;

	IF ''t'' = row."IsMain" THEN

	    select  iso into v_country_code
	    from    country_codes cc,
		    "lktblCountry" lc
	    where   lower(cc.country_name) = lower(lc."CountryNmDisplay")
		    and lc."CountryID" = row. "CountryID";

	    update users_contact set
		wa_line1 = row."Add",
		wa_line2 = row."Add2",
		wa_postal_code = row."CodePost",
		wa_city = row."City",
		wa_country_code = v_country_code,
		note = 	''AddressTo: '' || coalesce(row."AddressTo", '''') || 
			''\nStProv: '' || coalesce(row."StProv", '''') || 
			''\nAddInfo: '' || coalesce(row."AddInfo", '''')
	    where user_id = v_user_id;
	END IF;

	IF ''t'' = row."IsMain"
	THEN v_office_postfix := '' Main Office '';
	ELSE v_office_postfix := '' Office #'' || row."AddNum" || '' '';
	END IF;

	v_company_name := ''Freelance '' || row."FirstNm" || '' '' || row."LastNm";
	v_office_name := v_company_name || '' '' || v_office_postfix;

	select office_id into v_office_id
	from im_offices o where lower(trim(o.office_name)) = lower(trim(v_office_name));

	select company_id into v_company_id
	from im_companies c where lower(trim(c.company_name)) = lower(trim(v_company_name));

	IF v_office_id is NULL THEN
		select im_office__new (
			null, ''im_office'',
			now()::date, 0, ''0.0.0.0'', null,
			v_office_name,
			lower(trim(replace(v_office_name, '' '', ''_''))),
			170, 160, null
		) into v_office_id;
	END IF;

	IF v_company_id is NULL THEN
		select im_company__new (
			null, ''im_company'', now()::date,
			0, ''0.0.0.0'', null,
			v_company_name,
			lower(trim(replace(v_company_name, '' '', ''_''))),
			v_office_id,
			58, 46
		) into v_company_id;
	END IF;

	v_company_status_id := 46;
	IF false = row.company_active_p THEN v_company_status_id := 48; END IF;
	v_company_type_id := 58;

	v_office_status_id := 160;
	IF false = row.office_active_p THEN v_office_status_id := 161; END IF;
	v_office_type_id := 170;
	IF false = row."IsMain" THEN v_office_type_id := 171; END IF;

	select	iso into v_country_code
	from	country_codes cc,
		"lktblCountry" lc
	where	lower(cc.country_name) = lower(lc."CountryNmDisplay")
		and lc."CountryID" = row. "CountryID";

	RAISE NOTICE ''Tran:%, Addr:%, Off:%, Comp:%, oid:%, cid:%, cc:%, sales:%'', 
	row."TranID", row."AddNum", v_office_postfix, v_company_name, v_office_id, v_company_id,
	v_country_code, v_sales_potential_id;

	update im_companies set
		note = 	''TranComp: '' || coalesce(row."TranComp", '''') || 
			''\nUrsaff: '' || coalesce(row."Ursaff", '''') || 
			''\nTransSource: '' || coalesce(row."TranSource", '''') || 
			''\nAvailNotes: '' || coalesce(row."AvailNotes", '''') || 
			''\nTempAvail: ''|| coalesce(row. "TempAvail", '''') || 
			''\nScreenExtras: '' || coalesce(row."ScreenExtras", ''''),
		company_status_id = v_company_status_id,
		accounting_contact_id = v_user_id,
		primary_contact_id = v_user_id,
		main_office_id = v_office_id
	where	company_id = v_company_id;

	update im_offices set
		company_id = v_company_id,
		note = trim(
			''AddressTo: '' || coalesce(row."AddressTo", '''') || '' '' || 
			''\nAddInfo: '' || coalesce(row."AddInfo", '''') || '' '' || 
			''\nStProv: '' || coalesce(row."StProv", '''')
		),
		office_status_id = v_office_status_id,
		office_type_id = v_office_type_id,
		address_line1 = row."Add",
		address_line2 = row."Add2",
		address_city = row."City",
		address_postal_code = row."CodePost",
		address_country_code = v_country_code
	where	office_id = v_office_id;


	select count(*) into v_member_p
	from	acs_rels
	where	object_id_two = v_user_id
		and object_id_one = v_company_id;

	IF 0 = v_member_p THEN
		RAISE NOTICE ''Translator: Add rel between % and %'', v_company_id, v_user_id;
		PERFORM im_biz_object_member__new (
			null, ''im_biz_object_member'',
			v_company_id, v_user_id,
			1300, null, ''0.0.0.0''
		);
	END IF;

	RAISE NOTICE ''Users: uid:%, name=% %'', v_user_id, row."FirstNm", row."LastNm";

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Translator
-- "tblTranAdd";
-- "tblTranEvaluation";
-- "tblTranFileType";
-- "tblTranHardware";
-- "tblTranLang";
-- "tblTranMaster";
-- "tblTranMaster_TranNm";
-- "tblTranNote";
-- "tblTranPhon";
-- "tblTranPhon_CountryID";
-- "tblTranRate";
-- "tblTranReview";
-- "tblTranReviewEvaluation";
-- "tblTranService";
-- "tblTranSpec";
-- "tblTranWeb";


