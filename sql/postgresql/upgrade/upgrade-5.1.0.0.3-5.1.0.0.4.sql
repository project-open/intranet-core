-- upgrade-5.1.0.0.1-5.1.0.0.2.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.1.0.0.1-5.1.0.0.2.sql','');


-------------------------------------------------------------
-- Convert an array into rows
-------------------------------------------------------------

drop function if exists im_array2rows (float[]);
create or replace function im_array2rows (float[])
returns table(cnt integer, val float) as $body$
DECLARE
	p_array			alias for $1;
	v_i			integer;
BEGIN
	FOR v_i IN 1 .. array_upper(p_array, 1) LOOP
		cnt := v_i;
		val := p_array[v_i];
		return next;
	END LOOP;
END;$body$ language 'plpgsql';

