-- /po-core/sql/postgres/po-project-create.sql
--
-- Copyright (C) 1999-2004 Project/Open
-- The code is based on ArsDigita ACS 3.4
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author	various@arsdigita.com
-- @author      frank.bergmann@project-open.com


-----------------------------------------------------------
-- Projects
--
-- Each project can have any number of sub-projects
--

CREATE FUNCTION inline_0 ()
RETURNS integer AS '
begin
	PERFORM acs_object_type__create_type (
	''po_project'',		-- object_type
 	''Project'',		-- pretty_name
	''Projects'',		-- pretty_plural
	''group'',		-- supertype
	''po_projects'',	-- table_name
	''project_id'',		-- id_column
	null,			-- package_name
	''f'',			-- abstract_p
	null,			-- type_extension_table
	null			-- name_method
	);
	return 0;
end;' LANGUAGE 'plpgsql';

SELECT inline_0 ();

DROP FUNCTION inline_0 ();


create table po_projects (
	project_id		integer
				constraint po_project_pk
				primary key
				constraint po_project_fk
				references groups,
	type_id			integer not null
				constraint po_project_type_fk
				references po_categories,
	status_id		integer not null
				constraint po_project_status_fk
				references po_categories,
	customer_id		integer
				constraint po_customer_fk
				references po_companies,
	parent_id		integer
				constraint po_parent_fk
				references po_projects,
	description		varchar(4000),
	start_date		date,
	end_date		date
	-- make sure the end date is after the start date
				constraint po_projects_date_const
				check( end_date - start_date >= 0 ),
	note			varchar(4000),
	project_lead_id		integer
				constraint po_project_lead
				references parties,
	requires_report_p	char(1) default 't'
				constraint po_requires_report_p
				check (requires_report_p in ('t','f')),
	project_budget		numeric(12,2),
	project_budget_currency	char(3)
				constraint po_project_budget_currency_fk
				references currency_codes(currency_code)
);
create index po_project_parent_id_idx on po_projects(parent_id);

