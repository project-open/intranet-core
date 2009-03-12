-- /packages/intranet/sql/postgresql/intranet-performance-log.sql
--
-- Copyright (c) 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

---------------------------------------------------------
-- Performance Log
--
-- This module keeps track of overall ]po[ performance
-- by logging end-to-end duration of ]po[ pages.
-- We use the im_header and im_footer to catch basically
-- all pages in the system.


create sequence im_performance_log_seq start 1;

drop table im_performance_log;
create table im_performance_log (
	log_id			integer
				constraint im_perf_log_pk
				primary key,
	user_id			integer
				constraint im_perf_log_user_fk
				references persons,

	-- IP of the connected user
	client_ip		varchar,

	-- session ID
	session_id		varchar,

	-- The complete url of the page
	url			varchar,

	-- The url of the page (without parameters)
	url_params		varchar,

	-- where did we measure the time within the page?
	-- usually this is either im_header or im_footer.
	location		varchar,

	-- current time in database format
	clock_time		timestamptz,

	-- timestamp in terms of clock clicks
	clock_clicks		integer
);
