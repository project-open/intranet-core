-- /packages/intranet/sql/intranet-core-create.sql
--
-- Copyright (C) 1999-2004 various parties
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
-- @author      unknown@arsdigita.com
-- @author      frank.bergmann@project-open.com


---------------------------------------------------------
-- Partners
--
-- Partners are currently not being used in Project/Open.
-- We've included this old 3.4 code in order to maintain
-- compatibility while porting the system.

create table im_partners (
	partner_id 		integer
				constraint im_partner_pk
				primary key 
				constraint im_partner_partner_id_fk
				references groups,
	partner_name		varchar(1000) not null
				constraint im_partners_name_un unique,
	partner_path		varchar(100) not null
				constraint im_partners_path_un unique,
	deleted_p		char(1) default('f') 
				constraint im_partners_deleted_p 
				check(deleted_p in ('t','f')),
	partner_type_id		integer
				constraint im_partner_type_fk
				references categories,
	partner_status_id	integer
				constraint im_partner_status_fk
				references categories,
	primary_contact_id	integer
				constraint im_partner_contact_fk
				references users,
	url			varchar(200),
	note			varchar(4000),
	referral_source		varchar(1000),
	annual_revenue_id	integer
				constraint im_partner_ann_rev_fk
				references categories
);

