
---------------------------------------------------------------------------------
-- tblTranWeb - Attach items to company as im_note
---------------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_company_id		integer;
	v_note_id		integer;
	v_note_type_id		integer;
	v_note_text		text;
	v_user_id		integer;
	v_email			text;
	v_email_exists_p	integer;
BEGIN
    for row in
        select	*
	from	"tblTranWeb"
	order by "TranID"
    loop
	select	company_id into v_company_id
	from	im_companies 
	where	lxc_trans_id = row."TranID";

	select person_id into v_user_id 
	from persons 
	where lxc_trans_id = row."TranID";

	select	category_id into v_note_type_id
	from	im_categories 
	where	aux_int1 = row."CoordTypeID"
		and category_type = ''Intranet Notes Type'';

	v_note_text :=	replace(coalesce(row."WebAdd", ''''), '' '', ''_'') || '' '' || 
			coalesce(row."WebNotes", '''');

	RAISE NOTICE ''Trans: comp=%, cid=%, type=%, tid=%, text=%'', 
	row."TranID", v_company_id, row."CoordTypeID", v_note_type_id, v_note_text;

	IF v_company_id is not null THEN
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
	END IF;

	IF v_user_id is not null THEN
		select	note_id into v_note_id
		from	im_notes
		where	object_id = v_user_id
			and note = v_note_text;

		IF v_note_id is NULL THEN
		    v_note_id := im_note__new(
			null, ''im_note'', now(),
			624, ''0.0.0.0'', null, 
			v_note_text,
			v_user_id,
			v_note_type_id, 11400
		    );
		END IF;
	END IF;

	-- Update the translators email
	select email from parties into v_email where party_id = v_user_id;
	select count(*) into v_email_exists_p from parties where lower(trim(email)) = lower(trim(row."WebAdd"));
	IF 
		0 = v_email_exists_p
		AND row."CoordTypeID" = 31 
		AND substring(v_email from ''nowhere.com'') is not null 
	THEN
		update parties set
			email = trim(lower(row."WebAdd"))
		where party_id = v_user_id;
		RAISE NOTICE ''Trans: Updated email: uid=%, email=%'', v_user_id, v_email;
	END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

