@../intranet-core-create.sql


update	im_categories 
set	category_type='Intranet UoM' 
where 
	category_type='Intranet Translation UoM'
;

create table im_start_weeks (
        start_block             date not null
                                constraint im_start_weeks_pk
                                primary key,
                                -- We might want to tag a larger unit
                                -- For example, if start_block is the first
                                -- Sunday of a week, those tagged with
                                -- start_of_larger_unit_p might tag
                                -- the first Sunday of a month
        start_of_larger_unit_p  char(1) default 'f'
                                constraint im_start_weeks_larger_ck
                                check (start_of_larger_unit_p in ('t','f')),
        note                    varchar(4000)
);

create table im_start_months (
        start_block             date not null
                                constraint im_start_months_pk
                                primary key,
                                -- We might want to tag a larger unit
                                -- For example, if start_block is the first
                                -- Sunday of a week, those tagged with
                                -- start_of_larger_unit_p might tag
                                -- the first Sunday of a month
        start_of_larger_unit_p  char(1) default 'f'
                                constraint im_start_months_larger_ck
                                check (start_of_larger_unit_p in ('t','f')),
        note                    varchar(4000)
);


-- Populate im_start_weeks. Start with Sunday,
-- Jan 7th 1996 and end after inserting 1000 weeks. Note
-- that 1000 is a completely arbitrary number.
DECLARE
    v_max                       integer;
    v_i                         integer;
    v_first_block_of_month      integer;
    v_next_start_week           date;
BEGIN
    v_max := 1000;

    FOR v_i IN 0..v_max-1 LOOP
        -- for convenience, select out the next start block to insert into a variable
        select to_date('1996-01-07','YYYY-MM-DD') + v_i*7
        into v_next_start_week
        from dual;

        insert into im_start_weeks (
                start_block
        ) values (
                to_date(v_next_start_week)
        );

        -- set the start_of_larger_unit_p flag if this is the first
        -- start block of the month
        update im_start_weeks
           set start_of_larger_unit_p='t'
         where start_block=to_date(v_next_start_week)
           and not exists (
        select 1
              from im_start_weeks
             where to_char(start_block,'YYYY-MM') =
                 to_char(v_next_start_week,'YYYY-MM')
                   and start_of_larger_unit_p='t');
    END LOOP;
END;
/
show errors;



-- Populate im_start_months. Start with im_start_weeks
-- dates and check for the beginning of a new month.
BEGIN
    for row in (
        select unique concat(to_char(start_block, 'YYYY-MM'),'-01') as first_day_in_month
        from im_start_weeks
     ) loop

        insert into im_start_months (
                start_block
        ) values (
                to_date(row.first_day_in_month)
        );

     end loop;
END;
/
show errors;


update im_profiles set profile_gif='admin' where profile_id=474;
update im_profiles set profile_gif='company' where profile_id=478;
update im_profiles set profile_gif='employee' where profile_id=482;
update im_profiles set profile_gif='freelance' where profile_id=486;
update im_profiles set profile_gif='proman' where profile_id=490;
update im_profiles set profile_gif='senman' where profile_id=494;
update im_profiles set profile_gif='accounting' where profile_id=498;
update im_profiles set profile_gif='sales' where profile_id=502;
commit;



declare
	v_top_menu integer;
begin
      v_top_menu := im_menu.new (
        package_name => 'intranet-core',
        label =>        'top',
        name =>         'Top Menu',
        url =>          '/',
        sort_order =>   10,
        parent_menu_id => null
    );

    update im_menus set parent_menu_id=v_top_menu where label='main';
    update im_menus set parent_menu_id=v_top_menu where label='project';

end;
/


alter table im_payments add
         cost_id                 integer
			         constraint im_payments_cost
                                 references im_costs
;



insert into im_costs
	select
		invoice_id as cost_id,
		invoice_nr as cost_name,		
		null as project_id,
		company_id,
		null as cost_center_id,
		provider_id,
		null as investment_id,
		invoice_status_id as cost_status_id,
		3700 as cost_type_id,
		null as cause_object_id,
		invoice_template_id as template_id,
		invoice_date as effective_date,
		null as start_block,
		payment_days,
		null as amount,
		null as currency,
		vat,
		tax,
		null as variable_clost_p,
		null as needs_redistribution_p,
		null as parent_id,
		null as redistributed_p,
		'f' as planning_p,
		null as planning_type_id,
		null as description,
		note
	from im_invoices
;


-- Can only be executed when im_costs is filled with data
update im_payments set cost_id=invoice_id;



alter table im_payments drop constraint im_payments_un;
alter table im_payments drop column invoice_id;

alter table im_payments add 
		constraint im_payments_un
                unique (company_id, cost_id, provider_id, received_date,
                        start_block, payment_type_id, currency);

alter table im_payments drop constraint im_payments_start_block;


alter table im_payments add 
constraint im_payments_start_block
foreign key (start_block) references im_start_months
;



alter table im_menus 
add constraint im_menus_label_unn unique(label);



alter table im_invoices drop column company_id;
alter table im_invoices drop column provider_id;
alter table im_invoices drop column creator_id;
alter table im_invoices drop column invoice_date;
alter table im_invoices drop column due_date;
alter table im_invoices drop column invoice_currency;
alter table im_invoices drop column invoice_template_id;
alter table im_invoices drop column invoice_status_id;
alter table im_invoices drop column invoice_type_id;
alter table im_invoices drop column last_modified;
alter table im_invoices drop column last_modifying_user;
alter table im_invoices drop column modified_ip_address;
alter table im_invoices drop column vat;
alter table im_invoices drop column tax;
alter table im_invoices drop column note;
alter table im_invoices drop column payment_days;

alter table im_invoices add
        reference_document_id   integer
                                constraint im_invoices_reference_doc
                                references im_invoices;


update im_costs set cost_status_id=3802 where cost_status_id=602;
update im_costs set cost_status_id=3804 where cost_status_id=604;
update im_costs set cost_status_id=3810 where cost_status_id=610;
update im_costs set cost_status_id=3814 where cost_status_id=614;

create index im_proj_payments_cost_id_idx on im_payments(cost_id);

update im_categories 
set category_type='Intranet Cost Template' 
where category_type='Intranet Invoice Template';


alter table im_costs add 
	paid_amount             number(12,3);
alter table im_costs add
	paid_currency           char(3)
                                constraint im_costs_paid_currency_fk
                                references currency_codes(iso);

