


---------------------------------------------------------------------------------
-- tblContCompPhon - Attach items to Contacts
---------------------------------------------------------------------------------


create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_person_id		integer;
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

	RAISE NOTICE ''Note: cont=%, pid=%, type=%, tid=%, fnm=%, lnm=%, web=%'', 
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

    END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

