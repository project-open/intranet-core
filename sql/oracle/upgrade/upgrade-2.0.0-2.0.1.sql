
alter table im_view_columns add
	extra_from		varchar(4000);

@../intranet-companies.sql
@../intranet-categories.sql
@../intranet-views.sql

alter table im_view_columns add
	extra_from             varchar(4000);

alter table im_view_columns add 
	order_by_clause         varchar(4000);
