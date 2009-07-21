DROP TABLE import_offices;
CREATE TABLE import_offices (
	office_name		text,
	office_path		text,
	office_status		text,
	office_type		text,
	phone			text,
	fax			text,
	address_line1		text,
	address_line2		text,
	address_city		text,
	address_state		text,
	address_postal_code	text,
	address_country_code	text,
	contact_person		text,
	note			text
);

COPY import_offices (office_name, office_path, office_status, office_type, phone, fax, address_line1, address_line2, address_city, address_state, address_postal_code, address_country_code, contact_person, note) from stdin;
Tigerpond Main Office	internal	Active	Main Office	+1 272 798 05 92	+1 272 798 05 93	Ronda Sant Antoni 51, 1o 2a	\N	Barcelona	\N	08011	es	\N	\N
\.

DROP TABLE import_companies;
CREATE TABLE import_companies (
	company_name		text,
	company_path		text,
	office_path		text,
	company_status		text,
	company_type		text,
	primary_contact		text,
	accounting_contact	text,
	note			text,
	referral_source		text,
	default_vat		text
);

COPY import_companies (company_name, company_path, office_path, company_status, company_type, primary_contact, accounting_contact, note, referral_source, default_vat) from stdin;
International Social Security Association	internal	geneva_headquarter	active	internal	sysadmin@tigerpond.com	sysadmin@tigerpond.com	\N	\N	\N
\.


DROP TABLE import_users;
CREATE TABLE import_users (
	email		text,
	username	text,
	first_names	text,
	last_name	text,
	group1		text,
	group2		text,
	group3		text
);

COPY import_users (email, username, first_names, last_name, group1, group2, group3) from stdin;
\.

DROP TABLE import_users_contact;
CREATE TABLE import_users_contact (
	email			text,
	home_phone		text,
	work_phone		text,
	cell_phone		text,
	fax			text,
	skype_number		text,
	msn_screen_name		text,
	google_screen_name	text,
	ha_line1		text,
	ha_line2		text,
	ha_city			text,
	ha_state		text,
	ha_postal_code		text,
	ha_country_code		text,
	note			text
);

COPY import_users_contact (email, home_phone, work_phone, cell_phone, fax, skype_number, msn_screen_name, google_screen_name, ha_line1, ha_line2, ha_city, ha_state, ha_postal_code, ha_country_code, note) from stdin;
\.


DROP TABLE import_employees;
CREATE TABLE import_employees (
	email			text,
	supervisor		text,
	department_code		text,
	hourly_cost		text,
	availability		text,
	job_title		text,
	birthdate		text,
	group1			text,
	group2			text,
	group3			text
);

COPY import_employees (email, supervisor, department_code, hourly_cost, availability, job_title, birthdate, group1, group2, group3) from stdin;
\.


DROP TABLE import_projects;
CREATE TABLE import_projects (
	project_name		text,
	project_nr		text,
	project_path		text,
	parent_nr		text,
	customer_nr		text,
	project_type		text,
	project_status		text,
	project_lead		text,
	supervisor		text,
	corporate_sponsor	text,
	on_track_status		text,
	project_budget		text,
	project_budget_currency	text,
	project_budget_hours	text,
	cost_center_id		text,
	start_date		text,
	end_date		text,
	customer_contact	text,
	customer_project_nr	text,
	note			text,
	description		text
);

-- Make the Nr unique in order to allow to find super-projects.
CREATE UNIQUE INDEX import_projects_project_nr_un ON import_projects(project_nr);

COPY import_projects (project_name, project_nr, project_path, parent_nr, customer_nr, project_type, project_status, project_lead, supervisor, corporate_sponsor, on_track_status, project_budget, project_budget_currency, project_budget_hours, cost_center_id, start_date, end_date, customer_contact, customer_project_nr, note, description) FROM stdin;
Developing USB Bus Driver	2005_0088	2005_0088	\N	internal	Software Development	Open	frank.bergmann@project-open.com	\N	\N	Green	\N	EUR	\N	\N	2007-09-25 00:00:00+02	2008-04-23 00:00:00+02	\N	\N	\N	This is a USB Driver development project. The driver will be developed on ARM based Linux.
\.


DROP TABLE import_tasks;
CREATE TABLE import_tasks (
	project_nr		text,
	material_nr		text,
	planned_units		text,
	billable_units		text,
	cost_center_code	text,
	priority		text
);

COPY import_tasks (project_nr, material_nr, planned_units, billable_units, cost_center_code, priority) FROM stdin;
\.



DROP TABLE import_project_members;
CREATE TABLE import_project_members (
	project_nr		text,
	email			text,
	role			text,
	percentage		text
);

COPY import_project_members (project_nr, email, role, percentage) FROM stdin;
\.



DROP TABLE import_company_members;
CREATE TABLE import_company_members (
	company_nr		text,
	email			text
);

COPY import_company_members (company_nr, email) FROM stdin;
\.



---------------------------------------------------------------------------------
-- Auxilary Functions and Helpers
---------------------------------------------------------------------------------

-- Lookup a category in po and return the category_id
create or replace function import_cat (varchar, varchar)
returns integer as '
DECLARE
	p_category	alias for $1;
	p_category_type	alias for $2;
	v_category_id	integer;
BEGIN
	SELECT	c.category_id INTO v_category_id FROM im_categories c
	WHERE	lower(c.category) = lower(p_category)
		AND lower(c.category_type) = lower(p_category_type);

	IF v_category_id is null AND p_category is not null THEN
	   	RAISE NOTICE ''import_cat(%,%): Did not find category'', p_category, p_category_type;
	END IF;
	RETURN v_category_id;
END;' language 'plpgsql';
-- select import_cat('open','intranet project status');


-- Lookup the "primary key" (email or username) of a user into a user_id
create or replace function lookup_user (varchar, varchar)
returns integer as '
DECLARE
	p_email		alias for $1;
	p_purpose	alias for $2;

	v_user_id	integer;
BEGIN
	IF p_email is null THEN return null; END IF;
	IF p_email = '''' THEN return null; END IF;

	SELECT	p.party_id INTO v_user_id
	FROM	parties p
	WHERE	lower(p.email) = lower(p_email);

	IF v_user_id is null THEN
		SELECT	u.user_id INTO v_user_id
		FROM	users u
		WHERE	lower(u.username) = lower(p_email);
	END IF;

	IF v_user_id is null AND p_email is not null THEN
	   	RAISE NOTICE ''lookup_user(%) for %: Did not find user'', p_email, p_purpose;
	END IF;

	RETURN v_user_id;
END;' language 'plpgsql';



---------------------------------------------------------------------------------
-- Users
---------------------------------------------------------------------------------

-- Actually create new users by going through the import_users table
-- line by line and inserting the user into the DB.
create or replace function import_users ()
returns integer as '
DECLARE
        row		RECORD;
	v_user_id	integer;
	v_exists_p	integer;
	v_authority_id	integer;
	v_group_id	integer;
BEGIN
    FOR row IN
        select	* 
	from import_users
    LOOP
	-- Check if the user already exists / has been imported already
	-- during the last run of this script
	select count(*) into v_exists_p from parties p
	where trim(lower(p.email)) = trim(lower(row.email));

	-- Create a new user if the user wasnt there
	IF v_exists_p = 0 THEN
	   	RAISE NOTICE ''Insert User: %'', row.email;
		v_user_id := acs__add_user(
			null, ''user'', now(), 0, ''0.0.0.0'', 
			null, row.username, row.email, null,
			row.first_names, row.last_name, 
			''hashed_password'', ''salt'', 
			row.username, ''t'', ''approved''
		);
		INSERT INTO users_contact (user_id) VALUES (v_user_id);
		INSERT INTO im_employees (employee_id) VALUES (v_user_id);
	END IF;

	-- This is the main part of the import process, this part is 
	-- executed for every line in the import_users table every time
	-- this script is executed.
	-- Update the users information, no matter whether its a new or
	-- an already existing user.
	v_user_id := lookup_user(row.email, ''import_users'');

	RAISE NOTICE ''Update User: %'', row.email;
	update users set
			username = row.username
	where user_id = v_user_id;

	update persons set
			first_names = row.first_names,
			last_name = row.last_name
	where person_id = v_user_id;

	update parties set
			url = null
	where party_id = v_user_id;

	PERFORM im_profile_add_user(row.group1, v_user_id);
	PERFORM im_profile_add_user(row.group2, v_user_id);
	PERFORM im_profile_add_user(row.group3, v_user_id);

    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
select import_users ();



create or replace function import_users_contact ()
returns integer as '
DECLARE
        row		RECORD;
	v_user_id	integer;
BEGIN
    FOR row IN
        select	* 
	from import_users_contact
    LOOP

        v_user_id := lookup_user(row.email, ''import_users_contact'');
	RAISE NOTICE ''Update Contacts: % - %'', row.email, v_user_id;

	update users_contact set
		home_phone = row.home_phone,
		work_phone = row.work_phone,
		cell_phone = row.cell_phone,
		fax = row.fax,
		icq_number = row.skype_number,
		msn_screen_name = row.msn_screen_name,
		aim_screen_name = row.google_screen_name,
		ha_line1 = row.ha_line1,
		ha_line2 = row.ha_line2,
		ha_city = row.ha_city,
		ha_state = row.ha_state,
		ha_postal_code = row.ha_postal_code,
		ha_country_code = lower(row.ha_country_code),
		note = row.note
	where user_id = v_user_id;

    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
select import_users_contact ();


create or replace function import_employees ()
returns integer as '
DECLARE
        row		RECORD;
	v_user_id	integer;
	v_count		integer;
BEGIN
    FOR row IN
        select	* 
	from import_employees
    LOOP
        v_user_id := lookup_user(row.email, ''import_employees'');
	RAISE NOTICE ''Update Employees: % - %'', row.email, row.department_code;

	IF v_user_id is not null THEN

		-- Setup im_employees entries if not already there.
		select count(*) into v_count from im_employees
		where employee_id = v_user_id;
		IF 0 = v_count THEN
			insert into im_employees (employee_id) values (v_user_id);
		END IF;

		update im_employees set
			supervisor_id = lookup_user(row.supervisor, ''import_employees.supervisor''),
			department_id = (
				select cost_center_id 
				from im_cost_centers 
				where trim(lower(cost_center_code)) = trim(lower(row.department_code))
			),
			hourly_cost = row.hourly_cost::numeric,
			availability = row.availability::numeric,
			job_title = row.job_title,
			birthdate = row.birthdate::date
		where employee_id = v_user_id;

		PERFORM im_profile_add_user(row.group1, v_user_id);
		PERFORM im_profile_add_user(row.group2, v_user_id);
		PERFORM im_profile_add_user(row.group3, v_user_id);
	END IF;

    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
select import_employees ();


---------------------------------------------------------------------------------
-- Offices
---------------------------------------------------------------------------------

create or replace function import_offices ()
returns integer as '
DECLARE
        row		RECORD;
	v_office_id	integer;
	v_status_id	integer;
	v_type_id	integer;
	v_exists_p	integer;
BEGIN
    FOR row IN
        select	* 
	from import_offices
    LOOP
	v_status_id := import_cat(row.office_status, ''Intranet Office Status'');
	v_type_id := import_cat(row.office_type, ''Intranet Office Type'');

	-- Check for duplicate entry based on office_path PK
	select count(*) into v_exists_p from im_offices o
	where trim(lower(o.office_path)) = trim(lower(row.office_path));
	IF v_exists_p = 0 THEN
	   	RAISE NOTICE ''Insert Office: %'', row.office_path;
		v_office_id := im_office__new (
			NULL, ''im_office'', now()::date, 0, ''0.0.0.0'', null,
			row.office_name, row.office_path, v_type_id, v_status_id, null
		);
	END IF;

	RAISE NOTICE ''Update Office: %'', row.office_path;
	update im_offices set
			office_name = row.office_name,
			office_status_id = v_status_id,
			office_type_id = v_type_id,
        		phone = row.phone,
			fax = row.fax,
        		address_line1 = row.address_line1,
        		address_line2 = row.address_line2,
        		address_city = row.address_city,
        		address_state = row.address_state,
        		address_postal_code = row.address_postal_code,
        		address_country_code = lower(row.address_country_code),
        		contact_person_id = lookup_user(row.contact_person, ''import_offices.contact_person''),
        		note = row.note
	where office_path = row.office_path;

    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
select import_offices ();


---------------------------------------------------------------------------------
-- Companies
---------------------------------------------------------------------------------

create or replace function import_companies ()
returns integer as '
DECLARE
        row		RECORD;
	v_company_id	integer;
	v_status_id	integer;
	v_type_id	integer;
	v_office_id	integer;
	v_exists_p	integer;
BEGIN
    FOR row IN
        select	* 
	from import_companies
    LOOP
	select count(*) into v_exists_p from im_companies o
	where trim(lower(o.company_path)) = trim(lower(row.company_path));

	v_status_id := import_cat(row.company_status, ''Intranet Company Status'');
	v_type_id := import_cat(row.company_type, ''Intranet Company Type'');

	select office_id into v_office_id from im_offices
	where office_path = row.office_path;
	IF v_office_id is null THEN
	   	RAISE NOTICE ''import_companies(%): Did not find office "%"'', row.company_path, row.office_path;
	END IF;

	IF v_exists_p = 0 THEN
	   	RAISE NOTICE ''Insert Company: %'', row.company_path;
		v_company_id := im_company__new (
			NULL, ''im_company'', now()::date, 0, ''0.0.0.0'', null,
			row.company_name, row.company_path, 
			v_office_id, v_type_id, v_status_id
		);
	END IF;

	RAISE NOTICE ''Update Company: %'', row.company_path;
	update im_companies set
			company_name = row.company_name,
			main_office_id = v_office_id,
			company_status_id = v_status_id,
			company_type_id = v_type_id,
			primary_contact_id = lookup_user(row.primary_contact, ''import_companies.primary_contact''),
			accounting_contact_id = lookup_user(row.accounting_contact, ''import_companies.accounting_contact''),
			referral_source = row.referral_source,
			default_vat = row.default_vat::numeric,
        		note = row.note
	where company_path = row.company_path;

    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
select import_companies ();



---------------------------------------------------------------------------------
-- Projects
---------------------------------------------------------------------------------

create or replace function import_projects ()
returns integer as '
DECLARE
        row		RECORD;
	v_project_id	integer;
	v_status_id	integer;
	v_type_id	integer;
	v_customer_id	integer;
	v_parent_id	integer;
	v_exists_p	integer;
BEGIN
    FOR row IN
        select	* 
	from import_projects
    LOOP

	-- ToDo: ProjectID_from_project_nr (with parents)
	-- ToDo: Company from CompanyNr

	v_status_id := import_cat(row.project_status, ''Intranet Project Status'');
	v_type_id := import_cat(row.project_type, ''Intranet Project Type'');

	select company_id into v_customer_id from im_companies
	where company_path = row.customer_nr;
	IF v_customer_id is null THEN
	   	RAISE NOTICE ''import_projects(%): Did not find company "%"'', row.project_path, row.customer_nr;
	END IF;

	select project_id into v_parent_id from im_projects
	where project_nr = row.parent_nr;

	-- Duplicate?
	select count(*) into v_exists_p from im_projects p
	where trim(lower(p.project_path)) = trim(lower(row.project_path));
	IF v_exists_p = 0 THEN
	   	RAISE NOTICE ''Insert Project: %'', row.project_path;
		v_project_id := im_project__new (
			NULL, ''im_project'', now(), 0, ''0.0.0.0'', null,
			row.project_name, row.project_nr, row.project_path,
			v_parent_id, v_customer_id, v_type_id, v_status_id
		);
	END IF;

	RAISE NOTICE ''Update Project: %'', row.project_path;
	update im_projects set
		project_name		= row.project_name,
		project_nr		= row.project_nr,
		project_path		= row.project_path,
		parent_id		= v_parent_id,
		company_id		= v_customer_id,
		project_type_id		= v_type_id,
		project_status_id	= v_status_id,
		project_lead_id		= lookup_user(row.project_lead, ''import_projects.project_lead''),
		supervisor_id		= lookup_user(row.supervisor, ''import_projects.supervisor_id''),
		corporate_sponsor	= lookup_user(row.corporate_sponsor, ''import_projects.corporate_sponsor''),
		on_track_status_id	= import_cat(row.on_track_status, ''Intranet Project On Track Status''),
		project_budget		= row.project_budget::numeric,
		project_budget_currency	= row.project_budget_currency,
		project_budget_hours	= row.project_budget_hours::numeric,
		start_date		= row.start_date::date,
		end_date		= row.end_date::date,
		company_contact_id	= lookup_user(row.customer_contact, ''import_projects.company_contact''),
		company_project_nr	= row.customer_project_nr,
		note			= row.note,
		description		= row.description
	where project_nr = row.project_nr;

    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
select import_projects ();


drop function import_tasks_not_working_yet();
create or replace function import_project_members ()
returns integer as '
DECLARE
        row		RECORD;
	v_project_id	integer;
	v_user_id	integer;
	v_rel_id	integer;
BEGIN
    FOR row IN
        select	* 
	from import_project_members
    LOOP
	select project_id into v_project_id from im_projects
	where project_nr = row.project_nr;
	IF v_project_id is null THEN
	   	RAISE NOTICE ''import_project_members: Did not find project "%"'', row.project_nr;
	END IF;

	v_user_id := lookup_user(row.email, ''import_tasks.owner'');

	IF v_user_id is not null AND v_project_id is not null THEN
		v_rel_id := im_biz_object_member__new (
			null,
			''im_biz_object_member'',
			v_project_id,
			v_user_id,
			import_cat(row.role, ''Intranet Biz Object Role''),
			row.percentage::numeric,
			null,
			''0.0.0.0''
		);
	END IF;

    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
select import_project_members ();





-- drop function import_tasks_not_working_yet();
create or replace function import_tasks_not_working_yet ()
returns integer as '
DECLARE
        row		RECORD;
	v_project_id	integer;
	v_status_id	integer;
	v_type_id	integer;
	v_customer_id	integer;
	v_parent_id	integer;
	v_exists_p	integer;
	v_default_material_id	integer;
	v_cost_center_id integer;
BEGIN
    FOR row IN
        select	* 
	from import_projects
    LOOP

	select material_id into v_default_material_id from im_materials
	where material_nr = ''default'';

		IF v_type_id = 100 THEN
			select cost_center_id into v_cost_center_id from im_cost_centers
			where cost_center_code = row.cost_center;
			INSERT INTO im_timesheet_tasks (
				task_id,
				material_id,
				uom_id,
				planned_unites,
				billable_units,
				cost_center_id,
				sort_order
			) VALUES (
				v_project_id,
				v_default_material_id,
				320,
				row.planned_unites,
				row.billable_units,
				v_cost_center_id,
				0
			);
		END IF;

    END LOOP;
    RETURN 0;
END;' language 'plpgsql';
-- select import_tasks ();

