


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- tblUsers - in-house users
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Employees
create or replace function inline_0 ()
returns integer as '
DECLARE
	row				RECORD;
	v_user_id			integer;
	v_user_email			varchar;
	v_ucont_exists_p		integer;
	v_member_p			integer;
BEGIN
    for row in
	select	*
	from	"tblUsers"
	where	"LastNm" is not NULL and "FirstNm" is not NULL
    loop
	select	party_id into v_user_id from parties pa
	where	lower(trim(pa.email)) = lower(trim(row."UserEmail"));

	IF v_user_id is NULL THEN
		select	person_id into v_user_id from persons p
		where	lower(trim(p.first_names)) = lower(trim(row."FirstNm")) and
			lower(trim(p.last_name)) = lower(trim(row."LastNm"));
	END IF;

	v_user_email := row."UserEmail";
	IF v_user_email is NULL OR '''' = v_user_email THEN
		v_user_email := lower(row."FirstNm"||''.''||row."LastNm"||''@nowhere.com'');
	END IF;

	-- Create User or get the existing user based on email
	IF v_user_id is NULL THEN
	    -- Create the new user without a reasonable password
	    select acs__add_user(
		null, ''user'', now(), null, ''0.0.0.0'', null,
		row."FirstNm" || '' '' || row."LastNm" || ''.'' || row."UserID",
		v_user_email, null, row."FirstNm", row."LastNm",
		''password'', ''salt'',
		row."FirstNm" || '' '' || row."LastNm" || ''.'' || row."UserID",
		''f'', ''approved''
	    ) into v_user_id;

	    select count(*) into v_ucont_exists_p from users_contact
	    where user_id = v_user_id;
	    IF 0 = v_ucont_exists_p THEN 
		insert into users_contact(user_id) values (v_user_id);
	    END IF;

	    RAISE NOTICE ''Created the user => %'', v_user_id;
	END IF;	

	-- Make user a member of Freelancers
	select count(*) into v_member_p from group_distinct_member_map where member_id=v_user_id and group_id=463;
	IF 0 = v_member_p THEN
	    PERFORM membership_rel__new(463, v_user_id);
	END IF;

	update persons set
		lxc_user_id = row."UserID"
	where person_id  = v_user_id;

	update users_contact set
		work_phone = row."UserPhone",
		fax = row."UserFax"
	where user_id = v_user_id;

	RAISE NOTICE ''Users: uid:%, name=% %'', v_user_id, row."FirstNm", row."LastNm";
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





