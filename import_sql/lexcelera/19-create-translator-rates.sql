---------------------------------------------------------------------------------
-- tblTranRates - Translator Rates
---------------------------------------------------------------------------------

-- Delete prices imported with this file...
delete from im_trans_prices where provider_price_p = 1;

create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_count			integer;
	v_price_id		integer;
	v_company_id		integer;
	v_project_type_id	integer;
	v_uom_id		integer;
	v_lang_id		integer;
	v_service_name		text;
	v_note_text		text;
BEGIN
    for row in
        select	m."TranID", m."FirstNm", m."LastNm",
		s."ServiceNmDisplay" as service_name,
		t."RateTypeNm",
		l."LangID",
		l."LangNmDisplay",
		r."TranServiceRate",
		r."TranMinimum",
		c."CurrencyAbb" as currency_code
	from
		"tblTranRate" r,
		"tblTranMaster" m,
		"lktblService" s,
		"lktblRateType" t,
		"lktblLang" l,
		"lktblCurrency" c
	where
		r."TranID" = m."TranID"
		and r."ServiceID" = s."ServiceID"
		and r."RateTypeID" = t."RateTypeID"
		and r."LangID" = l."LangID"
		and r."CurrencyID" = c."CurrencyID"
    loop
	v_service_name := row.service_name;
--	IF v_service_name = ''Proofreading'' THEN v_service_name := ''Copy writing''; END IF;
--	IF v_service_name = ''Rewriting'' THEN v_service_name := ''Copy writing''; END IF;
	IF v_service_name = '''' THEN v_service_name := ''''; END IF;
	IF v_service_name = '''' THEN v_service_name := ''''; END IF;

	v_note_text := 	   ''Service:'' ||
			row.service_name 
			|| '', UoM:'' ||
			row."RateTypeNm" 
			|| '', Lang:'' ||
			row."LangNmDisplay" 
			|| '', Rate:'' ||
			row."TranServiceRate" 
			|| '', Min:'' ||
			row."TranMinimum" 
			|| '', Curr:'' ||
			row.currency_code;

	select	company_id into v_company_id
	from	im_companies 
	where	lxc_trans_id = row."TranID";

	select	category_id into v_project_type_id
	from	im_categories
	where	category_type = ''Intranet Project Type''
		and aux_string1 = v_service_name;
	
	select	category_id into v_uom_id
	from	im_categories
	where	category_type = ''Intranet UoM''
		and aux_string1 = row."RateTypeNm";
	
	select	category_id into v_lang_id
	from	im_categories
	where	category_type = ''Intranet Translation Language''
		and aux_string1 = row."LangNmDisplay";
	
	RAISE NOTICE ''Rate: comp=%, ptype=%, uom=%, lang=%, cur=%, service=%, rate_type=%, lang=%'',
	v_company_id, v_project_type_id, v_uom_id, v_lang_id, row.currency_code,
	row.service_name, row."RateTypeNm", row."LangID";

	IF 0 <> row."TranServiceRate" THEN

		IF 0 = row."LangID" THEN v_lang_id := null; END IF;
	
		IF	v_uom_id is not null AND 
			v_company_id is not null AND 
			v_project_type_id is not null AND
			row."TranServiceRate" is not null
		THEN
	
		    select	count(*) into v_count
		    from	im_trans_prices
		    where	company_id = v_company_id
				and uom_id = v_uom_id
				and task_type_id = v_project_type_id
				and target_language_id = v_lang_id
				and currency = row.currency_code
		    ;
	
			RAISE NOTICE ''Insert: %, %, %, %, %, %, %'',
			v_uom_id, v_company_id,	v_project_type_id, v_lang_id, 
			row.currency_code, row."TranServiceRate", v_note_text;
	
		    IF 0 = v_count THEN	
			insert into im_trans_prices (
				price_id, uom_id, company_id, task_type_id,
				target_language_id, source_language_id,
				currency,
				price,
				note,
				provider_rate_p
			) values (
				nextval(''im_trans_prices_seq''),
				v_uom_id, v_company_id,	v_project_type_id,
				v_lang_id, null,
				row.currency_code,
				row."TranServiceRate",
				v_note_text,
				1
			);
	
		    ELSE
	
			update im_trans_prices set
				price		= row."TranServiceRate",
				note		= v_note_text
			where
				company_id = v_company_id
				and uom_id = v_uom_id
				and task_type_id = v_project_type_id
				and target_language_id = v_lang_id
				and currency = row.currency_code;
	
		    END IF;
		
		ELSE
	
			RAISE NOTICE ''Discarded Rate: comp=%, ptype=%, uom=%, lang=%, cur=%, service=%, rate_type=%, lang=%'',
			v_company_id, v_project_type_id, v_uom_id, v_lang_id, row.currency_code,
			row.service_name, row."RateTypeNm", row."LangID";
	
		END IF;

	END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
