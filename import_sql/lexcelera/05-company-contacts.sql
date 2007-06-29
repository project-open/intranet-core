

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- tblCon* - Contacts
---------------------------------------------------------------------------------
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

