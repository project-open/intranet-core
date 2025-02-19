SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.2.0.0.0-5.2.0.0.1.sql','');


-------------------------------------------------------------
-- Initials for Gantt Editor
--
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count                 integer;
BEGIN
	select count(*) into v_count from user_tab_columns where lower(table_name) = 'persons' and lower(column_name) = 'initials';
	IF v_count = 0 THEN 
		alter table persons add initials varchar;
	END IF;
	return 0;
END;$body$ language 'plpgsql';
SELECT inline_0 ();
DROP FUNCTION inline_0 ();

SELECT im_dynfield_attribute_new ('person', 'initials', 'Initials', 'textbox_small', 'string', 'f', 0, 'f', 'persons');

-------------------------------------------------------------------
-- Trigger for initials
-------------------------------------------------------------------

drop trigger if exists persons_initials_default_update_tr ON persons;
drop function if exists persons_initials_default_update_tr();

create or replace function persons_initials_default_update_tr () 
returns trigger as $body$
declare
	v_name		varchar;
	v_initials	varchar;
	v_state		integer;
	v_i		integer;
	v_j		integer;
	v_char		varchar;
	v_names		varchar[];
	v_name_start	integer;
	v_name_end	integer;
	v_name_idx	integer;
	v_exists_p	integer;
	v_opts		integer[][];
	v_debug		boolean;
begin
	v_debug := false;
	-- Ignore if initials are already set
	IF old.initials is not null THEN return new; END IF;

	-- We update persons below, so avoid loops
	IF pg_trigger_depth() > 1 THEN return new; END IF;

	SELECT upper(regexp_replace(' ' || new.first_names || ' ' || new.last_name, '\W', ' ', 'g') || ' ') INTO v_name;

	-- Mini state-engine looking at letter-space and space-letter transitions
	v_name_idx = 0;
	v_initials := '';
	v_state := 0; -- 0=space, 1=letters
	FOR v_i IN 1..length(v_name) LOOP
		v_char := substring(v_name from v_i for 1);
		IF v_state = 0 THEN
			-- We had spaces before   
			IF ' ' = v_char THEN
				-- more spaces, do nothing
			ELSE
				-- found a first char
				v_initials := v_initials || v_char;
				v_name_start := v_i;
				v_state := 1;
			END IF;
		ELSE
			-- We had chars before
			IF ' ' = v_char THEN
				-- found a first space after chars
				v_name_end := v_i;
				v_state := 0;
				v_names[v_name_idx] := substring(v_name, v_name_start, v_name_end-v_name_start);
				v_name_idx := v_name_idx + 1;
			ELSE
				-- more chars, do nothing
			END IF;	
		END IF;
		IF v_debug THEN RAISE NOTICE 'persons_initials_default_update_tr: id=%, v_name="%", v_i=%, v_char=%, v_name_idx=%, v_name_start=%', new.person_id, v_name, v_i, v_char, v_name_idx, v_name_start; END IF;

	END LOOP;
	IF v_debug THEN RAISE NOTICE 'persons_initials_default_update_tr: id=%, v_name="%": candidate initials=%', new.person_id, v_name, v_initials; END IF;

	-- Use initials if not already there
	-- These initials could have three letters in case of Jose Luis Alberga
	select count(*) into v_exists_p from persons where upper(initials) = v_initials;
	IF v_exists_p = 0 THEN
		RAISE NOTICE 'persons_initials_default_update_tr: id=%, v_name="%": unique initials=%', new.person_id, v_name, v_initials;
		update persons set initials = v_initials where person_id = new.person_id;
		return new;
	END IF;
	IF v_debug THEN RAISE NOTICE 'persons_initials_default_update_tr: id=%, v_name="%": already taken: initials=%', new.person_id, v_name, v_initials; END IF;

	-- Use combinations of first name and 2nd name (ignore 3rd names)
	v_opts := '{{1,2},{2,2},{2,3},{3,3}}';
	FOR v_i IN 1..array_length(v_opts,1) LOOP
	    	IF v_debug THEN RAISE NOTICE 'persons_initials_default_update_tr: id=%, v_name="%": v_opts[%]=%', new.person_id, v_name, v_i, v_opts[v_i]; END IF;
		v_initials := substring(v_names[0], 1, v_opts[v_i][1]) || substring(v_names[1], 1, v_opts[v_i][2]);
		select count(*) into v_exists_p from persons where upper(initials) = v_initials;
		IF v_exists_p = 0 THEN
			RAISE NOTICE 'persons_initials_default_update_tr: id=%, v_name="%": found initials=% in position %', new.person_id, v_name, v_initials, v_i;
			update persons set initials = v_initials where person_id = new.person_id;
			return new;
		END IF;
	END LOOP;

	return new;
end;$body$ language 'plpgsql';

create trigger persons_initials_default_update_tr after update
on persons for each row execute procedure persons_initials_default_update_tr ();

-- Set initials for all users
update persons set person_id = person_id where initials is null;
