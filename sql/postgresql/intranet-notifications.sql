-- /packages/intranet-core/sql/oracle/intranet-views.sql
--
-- Copyright (c) 2007 ]project-open[
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
-- @author      frank.bergmann@project-open.com



-- Determine the default locale for the user
create or replace function acs_lang_get_locale_for_user (integer) returns text as '
declare
	p_user_id	alias for $1;

	v_workflow_key		varchar(100);
	v_transition_key	varchar(100);
	v_acs_lang_package_id	integer;
	v_locale		varchar(10);
begin
	-- Get the users local from preferences
	select	locale into v_locale
	from	user_preferences
	where	user_id = p_user_id;

	-- Get users locale from global default
	IF v_locale is null THEN
		select	package_id
		into	v_acs_lang_package_id
		from	apm_packages
		where	package_key = ''acs-lang'';

		v_locale := apm__get_value (v_acs_lang_package_id, ''SiteWideLocale'');
	END IF;

	-- Partial locale - lookup complete one
	IF length(v_locale) = 2 THEN
		select	locale into v_locale
		from	ad_locales
		where	language = v_locale
			and enabled_p = ''t''
			and (default_p = ''t''
			   or (select count(*) from ad_locales where language = v_locale) = 1
			);
	END IF;

	-- Default: English
	IF v_locale is null THEN
		v_locale := ''en_US'';
	END IF;

	return v_locale;
end;' language 'plpgsql';


-- Determine the message string for (locale, package_key, message_key):
create or replace function acs_lang_lookup_message (text, text, text) returns text as $body$
declare
	p_locale		alias for $1;
	p_package_key		alias for $2;
	p_message_key		alias for $3;
	v_message		text;
	v_locale		text;
	v_acs_lang_package_id	integer;
begin
	-- --------------------------------------------
	-- Check full locale
	select	message into v_message
	from	lang_messages
	where	(message_key = p_message_key OR message_key = replace(p_message_key, ' ', '_'))
		and package_key = p_package_key
		and locale = p_locale
	LIMIT 1;
	IF v_message is not null THEN return v_message; END IF;

	-- --------------------------------------------
	-- Partial locale - lookup complete one
	v_locale := substring(p_locale from 1 for 2);

	select	locale into v_locale
	from	ad_locales
	where	language = v_locale
		and enabled_p = 't'
		and (default_p = 't' or
		(select count(*) from ad_locales where language = v_locale) = 1);

	select	message into v_message
	from	lang_messages
	where	(message_key = p_message_key OR message_key = replace(p_message_key, ' ', '_'))
		and package_key = p_package_key
		and locale = v_locale
	LIMIT 1;
	IF v_message is not null THEN return v_message; END IF;

	-- --------------------------------------------
	-- Try System Locale
	select	package_id into	v_acs_lang_package_id
	from	apm_packages
	where	package_key = 'acs-lang';
	v_locale := apm__get_value (v_acs_lang_package_id, 'SiteWideLocale');

	select	message into v_message
	from	lang_messages
	where	(message_key = p_message_key OR message_key = replace(p_message_key, ' ', '_'))
		and package_key = p_package_key
		and locale = v_locale
	LIMIT 1;
	IF v_message is not null THEN return v_message; END IF;

	-- --------------------------------------------
	-- Try with English...
	v_locale := 'en_US';
	select	message into v_message
	from	lang_messages
	where	(message_key = p_message_key OR message_key = replace(p_message_key, ' ', '_'))
		and package_key = p_package_key
		and locale = v_locale
	LIMIT 1;
	IF v_message is not null THEN return v_message; END IF;

	-- --------------------------------------------
	-- Nothing found...
	v_message := 'MISSING ' || p_locale || ' TRANSLATION for ' || p_package_key || '.' || p_message_key;
	return v_message;	

end;$body$ language 'plpgsql';


