drop table tmp_projects;

create table tmp_projects (
	project_name		varchar(1000),
	project_nr		varchar(1000),
	company_nr		varchar(1000),
	project_status_id	integer,
	project_type_id		integer
);


insert into tmp_projects values ('First Project', 'first', 'internal', 76, 86);
insert into tmp_projects values ('Second Project', 'second', 'internal', 76, 86);

create or replace function tmp_import_projects ()
returns integer as '
DECLARE
        row		RECORD;
	v_project_id	integer;
	v_company_id	integer;
	v_duplicate_p	integer;
BEGIN
    for row in
        select * 
	from tmp_projects
    loop
	RAISE NOTICE ''Project: %: %'', row.project_nr, row.project_name;

	-- Get the customer for the project
	-- The customers must be set up _before_ importing the projects.
	-- You can use "internal" for specifying internal projects.
	select company_id
	into v_company_id
	from im_companies
	where company_path = row.company_nr;

	-- Check for duplicate project_nr.
	-- In this case we dont have to create a new project.
	-- We still can update the existing project.
	select count(*)
	into v_duplicate_p
	from im_projects p
	where trim(p.project_nr) = trim(row.project_nr);

	IF v_duplicate_p = 0 THEN
		-- First create a new Main project
		select im_project__new (
			null, ''im_project'',
			now()::date, 0, ''0.0.0.0'', null,
			row.project_name, row.project_nr, row.project_nr,
			null, v_company_id, 
			row.project_type_id, row.project_status_id
		) into v_project_id;
	END IF;

	-- Now the project should exist.
	select project_id
	into v_project_id
	from im_projects
	where project_nr = row.project_nr;

	-- Now we can add more stuff to the project.
	-- This is just an example
	update im_projects set 
		note = ''batch import''
	where project_id = v_project_id;

    end loop;
    return 0;
END;' language 'plpgsql';
select tmp_import_projects ();
drop function tmp_import_projects ();

-- Check if the projects are there...
select * from im_projects order by project_id;

