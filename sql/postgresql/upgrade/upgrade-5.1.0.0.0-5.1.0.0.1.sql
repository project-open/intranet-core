SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.1.0.0.0-5.1.0.0.1.sql','');


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
	v_char		varchar;
begin
	-- Ignore if initials are already set
	IF old.initials is not null THEN return new; END IF;

	-- We update persons below, so avoid loops
	IF pg_trigger_depth() > 1 THEN return new; END IF;

	SELECT upper(regexp_replace(new.first_names || ' ' || new.last_name, '\W', ' ', 'g')) INTO v_name;

	-- Mini state-engine looking at letter-space and space-letter transitions
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
				v_state := 1;
			END IF;
		ELSE
			-- We had chars before
			IF ' ' = v_char THEN
				-- found a first space after chars
				v_state := 0;
			ELSE
				-- more chars, do nothing
			END IF;	
		END IF;
	END LOOP;
	update persons set initials = upper(v_initials) where person_id = new.person_id;
	-- RAISE NOTICE 'persons_initials_default_update_tr: found v_name=%, v_initials=%', v_name, v_initials;

	return new;
end;$body$ language 'plpgsql';

create trigger persons_initials_default_update_tr after update
on persons for each row execute procedure persons_initials_default_update_tr ();

-- Set initials for all users
update persons set person_id = person_id;
