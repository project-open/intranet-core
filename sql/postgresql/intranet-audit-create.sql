-- /packages/intranet-core/sql/postgresql/intranet-audit-create.sql
--
-- Copyright (c) 2007 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>


-------------------------------------------------------------
-- Audit for im_projects
--
-- The table and audit trigger definition will in future be
-- defined by the intranet-dynfield module to take care of
-- dynamic extensions of data types

create table im_projects_audit (
        last_modified			timestamptz,
        last_modifying_user		integer,
	last_modifying_ip		varchar(20),

	project_id			integer,
	project_name			varchar(1000),
	project_nr			varchar(100),
	project_path			varchar(100),
	parent_id			integer,
	company_id			integer,
	project_type_id			integer,
	project_status_id		integer,
	description			varchar(4000),
	billing_type_id			integer,
	note				varchar(4000),
	project_lead_id			integer,
	supervisor_id			integer,
	project_budget			float,
	corporate_sponsor		integer,
	percent_completed		float,
	on_track_status_id		integer,
	project_budget_currency		character(3),
	project_budget_hours		float,
	end_date			timestamptz,
	start_date			timestamptz,
	company_contact_id		integer,
	company_project_nr		varchar(50),
	final_company			varchar(50)
);

create index im_projects_audit_project_id_idx on im_projects_audit(project_id);

