-- -----------------------------------------------------------
-- Script to remove duplicate links from invoices that are
-- linked to more then one projects.
-- These invoices give problems during demo sessions.
-- -----------------------------------------------------------


CREATE OR REPLACE FUNCTION im_cleanup_demo_invoices_projects2 () 
RETURNS integer AS '
DECLARE
	v_return		INTEGER;

	row			RECORD;
	row2			RECORD;
BEGIN
	v_return := 0;
	FOR row IN 
		select	count(*) as cnt,
			invoice_id
		from	im_invoices i,
			im_projects p,
			acs_rels r
		where	i.invoice_id = r.object_id_two and
			p.project_id = r.object_id_one
		group by
			invoice_id
	LOOP
		-- Skip if there is only one project...
		IF row.cnt > 1 THEN	
			-- Check for non-top projects to delete them first
			FOR row2 IN
				select	i.invoice_id,
					p.project_id,
					r.rel_id
				from	im_invoices i,
					im_projects p,
					acs_rels r
				where	i.invoice_id = row.invoice_id and
					i.invoice_id = r.object_id_two and
					p.project_id = r.object_id_one
				LIMIT 1
			LOOP
				RAISE NOTICE ''delete iid=%, pid=%'', row2.invoice_id, row2.project_id;
				PERFORM acs_rel__delete(row2.rel_id);
				v_return := v_return + 1;
			END LOOP;
		END IF;
	END LOOP;

	RETURN v_return;
end;' language 'plpgsql';


CREATE OR REPLACE FUNCTION im_cleanup_demo_invoices_projects () 
RETURNS integer AS '
DECLARE
	v_return		INTEGER;
BEGIN
	v_return := 1;
	WHILE v_return > 0 LOOP
		v_return := im_cleanup_demo_invoices_projects2();
	END LOOP;

	RETURN 0;
end;' language 'plpgsql';

select im_cleanup_demo_invoices_projects();

