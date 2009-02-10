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
        modifying_action		varchar(20),
        last_modified			timestamptz,
        last_modifying_user		integer,
	last_modifying_ip		varchar(50),

	project_id			integer,
	project_name			text,
	project_nr			text,
	project_path			text,
	parent_id			integer,
	company_id			integer,
	project_type_id			integer,
	project_status_id		integer,
	description			text,
	billing_type_id			integer,
	note				text,
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
	company_project_nr		text,
	final_company			text,
	cost_invoices_cache		float,	
	cost_quotes_cache		float,		
	cost_delivery_notes_cache	float,
	cost_bills_cache		float,	
	cost_purchase_orders_cache	float,	
	cost_timesheet_planned_cache	float,	
	cost_timesheet_logged_cache	float,
	cost_expense_planned_cache	float,	
	cost_expense_logged_cache	float,
	reported_hours_cache		float
);

create index im_projects_audit_project_id_idx on im_projects_audit(project_id);

