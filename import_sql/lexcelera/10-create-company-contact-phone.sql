---------------------------------------------------------------------------------
-- tblContCompPhon - Attach items to Contacts
---------------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_person_id		integer;
	v_user_id		integer;
	v_note_id		integer;
	v_note_type_id		integer;
	v_note_text		text;
BEGIN
    for row in
	select	*
	from	"tblContCompPhon" p,
		"tblContComp" cc,
		"tblContMaster" m
	where
		p."ContCompID" = cc."ContCompID"
		and cc."ContID" = m."ContID"
		and "CoordTypeID" != 0
		and m."FirstNm" is not NULL
		and m."LastNm" is not NULL
    loop
	select	person_id into v_person_id
	from	persons
	where	lxc_contact_id = row."ContID";

	select	category_id into v_note_type_id
	from	im_categories 
	where	aux_int1 = row."CoordTypeID"
		and category_type = ''Intranet Notes Type'';

	v_note_text :=	row."Phone" || '' '' || coalesce(row."PhonNotes", '''');

	RAISE NOTICE ''Note: cont=%, pid=%, type=%, tid=%, fn=%, ln=%, phon=%'', 
	row."ContID", v_person_id, row."CoordTypeID", v_note_type_id, row."FirstNm", row."LastNm", v_note_text;

	IF v_person_id is not NULL THEN
		select	note_id into v_note_id
		from	im_notes
		where	object_id = v_person_id and note = v_note_text;
	
		IF v_note_id is NULL THEN
		    v_note_id := im_note__new(
			null, ''im_note'', now(),
			624, ''0.0.0.0'', null, 
			v_note_text,
			v_person_id,
			v_note_type_id, 11400
		    );
		END IF;

		-- Work Phone
		IF 21 = row."CoordTypeID" THEN
			update users_contact set work_phone = row."Phone" where user_id = v_person_id;	
			RAISE NOTICE ''Note: work_phone(%) = %'', v_person_id, row."Phone";
		END IF;
		-- Mobile Phone
		IF 22 = row."CoordTypeID" THEN
			update users_contact set cell_phone = row."Phone" where user_id = v_person_id;
			RAISE NOTICE ''Note: mobile_phone(%) = %'', v_person_id, row."Phone";
		END IF;
		-- Fax
		IF 23 = row."CoordTypeID" THEN
			update users_contact set fax = row."Phone" where user_id = v_person_id;
			RAISE NOTICE ''Note: fax(%) = %'', v_person_id, row."Phone";
		END IF;
		-- Skype
		IF 24 = row."CoordTypeID" THEN
			update users_contact set aim_screen_name = row."Phone" where user_id = v_person_id;
			RAISE NOTICE ''Note: skype(%) = %'', v_person_id, row."Phone";
		END IF;
		-- Home Phone
		IF 25 = row."CoordTypeID" THEN
			update users_contact set home_phone = row."Phone" where user_id = v_person_id;
			RAISE NOTICE ''Note: home_phone(%) = %'', v_person_id, row."Phone";
		END IF;
		-- Other (Phone?)
		IF 26 = row."CoordTypeID" THEN
			update users_contact set pager = row."Phone" where user_id = v_person_id;
			RAISE NOTICE ''Note: other(%) = %'', v_person_id, row."Phone";
		END IF;

	END IF;


    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
