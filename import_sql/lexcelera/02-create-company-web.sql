
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

