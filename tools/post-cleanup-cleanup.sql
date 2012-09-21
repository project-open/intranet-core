-- Delete "rests" of old data after a Clean demo data


---------------------------------------------
-- Delete the rest of projects

delete from im_timesheet_task_dependencies;

delete from "acs_object_context_index"
where object_id in (
	select	object_id
	from	acs_objects
	where	object_type = 'im_project'
);

update acs_objects
set context_id = null
where context_id in (
	select	object_id
	from	acs_objects
	where	object_type = 'im_project'
);

delete from acs_rels
where 	object_id_one in (
		select	object_id
		from	acs_objects
		where	object_type = 'im_project'
	) or
	object_id_two in (
		select	object_id
		from	acs_objects
		where	object_type = 'im_project'
	)
;

delete from acs_objects where object_type = 'im_project';


---------------------------------------------
-- Delete the rest of companies

update acs_objects
set context_id = null
where context_id in (
        select  object_id
        from    acs_objects
        where   object_type = 'im_company'
);

delete from acs_rels
where   object_id_one in (
                select  object_id
                from    acs_objects
                where   object_type = 'im_company'
        ) or
        object_id_two in (
                select  object_id
                from    acs_objects
                where   object_type = 'im_company'
        )
;

-- fraber 120921: Disabled translation
-- delete from im_trans_trados_matrix;

delete from acs_objects
where   object_type = 'im_company' and
	object_id not in (
			select	company_id
			from	im_companies
			where	company_path = 'internal'
	)
;


delete from acs_rels
where	object_id_one in (
	select object_id 
	from acs_objects
	where   object_type = 'im_office' and
		object_id not in (
				select	main_office_id
				from	im_companies
				where	company_path = 'internal'
		)
	)
;

delete from acs_rels
where	object_id_two in (
	select object_id 
	from acs_objects
	where   object_type = 'im_office' and
		object_id not in (
				select	main_office_id
				from	im_companies
				where	company_path = 'internal'
		)
	)
;

delete from acs_objects
where   object_type = 'im_office' and
	object_id not in (
			select	main_office_id
			from	im_companies
			where	company_path = 'internal'
	)
;



--------------------------------------------------
-- Rests of Timesheet Tasks

update acs_objects
set context_id = null
where context_id in (
        select  object_id
        from    acs_objects
        where   object_type = 'im_timesheet_task'
);


delete from acs_rels
where   object_id_one in (
                select  object_id
                from    acs_objects
                where   object_type = 'im_timesheet_task'
        ) or
        object_id_two in (
                select  object_id
                from    acs_objects
                where   object_type = 'im_timesheet_task'
        )
;


delete from acs_objects where object_type = 'im_timesheet_task';

--------------------------------------------------

delete from acs_rels where rel_id in (
	select object_id 
	from acs_objects 
	where object_type = 'im_biz_object_member'
);

delete from acs_objects where object_type = 'im_biz_object_member';



----------------------------------------------------

delete from cal_items;
delete from acs_objects where object_type = 'cal_item';



----------------------------------------------------

delete from journal_entries;
delete from acs_objects where object_type = 'journal_entry';


----------------------------------------------------


-- fraber 120921: Disabled translation
-- delete from im_trans_trados_matrix;

-- delete from im_trans_tasks;
-- delete from acs_objects where object_type = 'im_trans_task';



----------------------------------------------------
-- Check what is left...

select count(*) as cnt, object_type
from acs_objects
group by object_type
order by cnt DESC;

