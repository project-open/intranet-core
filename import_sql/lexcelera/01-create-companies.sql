

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
	v_company_path		text;
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

	-- Replace funny characters with _
	v_company_path := lower(trim(translate(row.company_name, ''.-(),!/&+'''' '', ''___________'')));
	v_company_path := replace(v_company_path, ''___'', ''_'');
	v_company_path := replace(v_company_path, ''__'', ''_'');

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
			v_company_path,
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

	RAISE NOTICE ''Cli:%, Addr:%, Off:%, Comp:%, oid:%, cid:%, cc:%, sales_pot_id:%, sales_pot:%'', 
	row.company_id, row.address_num, v_office_postfix, row.company_name, v_office_id, v_company_id,
	v_country_code, v_sales_potential_id, row."ClassificationID";

	update im_companies set
		company_path = v_company_path,
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

