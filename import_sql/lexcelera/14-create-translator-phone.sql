---------------------------------------------------------------------------------
-- tblTranPhone - Phone Numbers
---------------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_company_id		integer;
	v_user_id		integer;
	v_note_id		integer;
	v_note_type_id		integer;
	v_note_text		text;
BEGIN
    for row in
        select	*
	from	"tblTranPhon"
	where	"CoordTypeID" != 0
    loop
	select	company_id into v_company_id
	from	im_companies 
	where	lxc_trans_id = row."TranID";

	select	category_id into v_note_type_id
	from	im_categories 
	where	aux_int1 = row."CoordTypeID"
		and category_type = ''Intranet Notes Type'';

	RAISE NOTICE ''Note: tran=%, cid=%, type=%, tid=%, note=%'', 
	row."TranID", v_company_id, row."CoordTypeID", v_note_type_id, v_note_text;

	v_note_text :=	row."Phone" || '' '' || coalesce(row."PhonNotes", '''');

	IF v_company_id is not null THEN
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
	END IF;


	select	person_id into v_user_id
	from	persons
	where	lxc_trans_id = row."TranID";

	IF v_user_id is not null THEN
		select	note_id into v_note_id
		from	im_notes
		where	object_id = v_user_id and note = v_note_text;
	
		IF v_note_id is NULL THEN
		    v_note_id := im_note__new(
			null, ''im_note'', now(),
			624, ''0.0.0.0'', null, 
			v_note_text,
			v_user_id,
			v_note_type_id, 11400
		    );
		END IF;

	-- Work Phone
	IF 21 = row."CoordTypeID" THEN	update users_contact set work_phone = row."Phone" where user_id = v_user_id;	END IF;
	-- Mobile Phone
	IF 22 = row."CoordTypeID" THEN	update users_contact set cell_phone = row."Phone" where user_id = v_user_id;	END IF;
	-- Fax
	IF 23 = row."CoordTypeID" THEN	update users_contact set fax = row."Phone" where user_id = v_user_id;		END IF;
	-- Skype
	IF 24 = row."CoordTypeID" THEN	update users_contact set aim_screen_name = row."Phone" where user_id = v_user_id; END IF;
	-- Home Phone
	IF 25 = row."CoordTypeID" THEN	update users_contact set home_phone = row."Phone" where user_id = v_user_id;	END IF;
	-- Other (Phone?)
	IF 26 = row."CoordTypeID" THEN	update users_contact set pager = row."Phone" where user_id = v_user_id;	END IF;

	END IF;



    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


