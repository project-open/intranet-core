---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- tblTranMaster - Translators
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

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
	from	"tblTranMaster" t
		LEFT OUTER JOIN "tblTranAdd" a ON (t."TranID" = a."TranID")
    loop
	v_user_email := lower(row."FirstNm"||''.''||row."LastNm"||''@nowhere.com'');

	select	person_id into v_user_id from persons p
	where	lower(trim(p.first_names)) = lower(trim(row."FirstNm")) and
		lower(trim(p.last_name)) = lower(trim(row."LastNm"));

	-- Create User or get the existing user based on email
	IF v_user_id is NULL THEN
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
	
	update persons set
		lxc_trans_id = row."TranID"
	where person_id = v_user_id;
	
	-- Make user a member of "Freelancers"
	select count(*) into v_member_p 
	from group_member_map 
	where member_id=v_user_id and group_id=465;

	IF 0 = v_member_p THEN
	   RAISE NOTICE ''Adding to freelancers: uid=%, fn=%, ln=%'', v_user_id, row."FirstNm", row."LastNm";
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
		ELSE v_office_postfix := '' Office #'' || coalesce(row."AddNum", row."TranID") || '' '';
	END IF;

	v_company_name := ''Freelance '' || row."FirstNm" || '' '' || row."LastNm";
	v_office_name := v_company_name || '' '' || v_office_postfix;

	RAISE NOTICE ''company_name=%, office_name=%'', v_company_name, v_office_name;

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
		main_office_id = v_office_id,
		lxc_trans_id = row."TranID"
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

	RAISE NOTICE ''Trans: uid:%, name=% %'', v_user_id, row."FirstNm", row."LastNm";

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

