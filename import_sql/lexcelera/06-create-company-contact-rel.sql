
---------------------------------------------------------------------------------
-- tblContComp - Relationship between company and contact
---------------------------------------------------------------------------------


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

