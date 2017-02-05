-- /packages/intranet/sql/postgres/intranet-openacs-patches.sql
--
-- Copyright (c) 1999-2008 various parties
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
-- @author      frank.bergmann@project-open.com

-----------------------------------------------------
-- Set Parameters

-- reset the SystemCSS parameter to NULL
-- in order to enable the V3.4 GUI

update apm_parameter_values set
	attr_value = NULL
where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	package_key = 'intranet-core' 
			and parameter_name = 'SystemCSS'
);



-----------------------------------------------------

create or replace function apm__get_value(int4,varchar) returns varchar as $body$
   declare
     get_value__package_id             alias for $1; 
     get_value__parameter_name         alias for $2; 
     v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
     value                             apm_parameter_values.attr_value%TYPE;
   begin
       v_parameter_id := apm__id_for_name (get_value__package_id, get_value__parameter_name);
  
       select attr_value into value from apm_parameter_values v
       where v.package_id = get_value__package_id
       and parameter_id = v_parameter_id;
  
       return value;
     
end;$body$ language 'plpgsql';

-----------------------------------------------------

create or replace function acs_privilege__create_privilege (varchar,varchar,varchar)
returns integer as $body$
declare
	create_privilege__privilege             alias for $1;  
	create_privilege__pretty_name           alias for $2;  -- default null  
	create_privilege__pretty_plural         alias for $3;  -- default null
	v_count					integer;
begin
	select count(*) into v_count from acs_privileges
	where privilege = create_privilege__privilege;
	IF v_count > 0 THEN return 0; END IF;

	insert into acs_privileges (
		privilege, pretty_name, pretty_plural
	) values (
		create_privilege__privilege, 
		create_privilege__pretty_name, 
		create_privilege__pretty_plural
	);

    return 0; 
end;$body$ language 'plpgsql';


create or replace function acs_privilege__add_child (varchar,varchar)
returns integer as $body$
declare
	add_child__privilege		alias for $1;
	add_child__child_privilege	alias for $2;
	v_count				integer;
BEGIN
	SELECT count(*) into v_count from acs_privilege_hierarchy
	WHERE privilege = add_child__privilege and child_privilege = add_child__child_privilege;
	IF v_count > 0 THEN return 0; END IF;

	insert into acs_privilege_hierarchy (privilege, child_privilege)
	values (add_child__privilege, add_child__child_privilege);

	return 0; 
END;$body$ language 'plpgsql';




CREATE OR REPLACE FUNCTION ad_group_member_p(integer, integer)
RETURNS character AS $body$
DECLARE
	p_user_id		alias for $1;
	p_group_id		alias for $2;

	ad_group_member_count	integer;
BEGIN
	select count(*)	into ad_group_member_count
	from	acs_rels r,
		membership_rels mr
	where
		r.rel_id = mr.rel_id
		and object_id_one = p_group_id
		and object_id_two = p_user_id
		and mr.member_state = 'approved'
	;

	if ad_group_member_count = 0 then
		return 'f';
	else
		return 't';
	end if;
END;$body$ LANGUAGE 'plpgsql';



-------------------------------------------------------------
-- Portrait Fields
--
create or replace function inline_0 ()
returns integer as $body$
declare
        v_count                 integer;
begin
        select  count(*) into v_count from user_tab_columns
        where   lower(table_name) = 'persons' and lower(column_name) = 'portrait_checkdate';
        if v_count = 1 then return 0; end if;

	alter table persons add portrait_checkdate date;
	alter table persons add portrait_file varchar(400);

        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Extend the OpenACS type system 
create or replace function inline_0 ()
returns integer as $body$
DECLARE
        v_count                 integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'acs_object_types' and lower(column_name) = 'status_column';
	IF v_count > 0 THEN return 0; END IF;

	alter table acs_object_types
	add status_column character varying(30);
	
	alter table acs_object_types
	add type_column character varying(30);
	
	alter table acs_object_types
	add status_type_table character varying(30);

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();



-- Add a "skin" field to users table
create or replace function inline_0 ()
returns integer as $body$
DECLARE
        v_count                 integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'users' and lower(column_name) = 'skin';
	IF v_count > 0 THEN return 0; END IF;

	alter table users add skin int not null default 0;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();



-- Avoid authorities without short_name
ALTER TABLE auth_authorities ALTER COLUMN short_name SET NOT NULL;




-- acs-mail is deprecated
-- To ensure backwards compatibility inherit acs_mail_nt__post_request using acs_mail_lite queue
--
create or replace function acs_mail_nt__post_request(integer,integer,boolean,varchar,text,integer,integer)
returns integer as $BODY$
declare
        p_party_from            alias for $1;
        p_party_to              alias for $2;
        p_expand_group          alias for $3;   -- default 'f'
        p_subject               alias for $4;
        p_message               alias for $5;
        p_max_retries           alias for $6;   -- default 0
        p_package_id            alias for $7;   -- default null
        v_header_from           acs_mail_bodies.header_from%TYPE;
        v_header_to             acs_mail_bodies.header_to%TYPE;
        v_message_id            acs_mail_queue_messages.message_id%TYPE;
        v_header_to_rec         record;
        v_creation_user         acs_objects.creation_user%TYPE;
	v_creation_date		timestamptz;
	v_locking_server	varchar;
	v_mime_type		varchar;
begin
        if p_max_retries <> 0 then
           raise EXCEPTION ' -20000: max_retries parameter not implemented.';
        end if;

        -- get the sender email address
        select max(email) into v_header_from from parties where party_id = p_party_from;

        -- if sender address is null, then use site default OutgoingSender
        if v_header_from is null then
                select apm__get_value(package_id, 'OutgoingSender') into v_header_from from apm_packages where package_key='acs-kernel';
        end if;

        -- make sure that this party is in users table. If not, let creation_user
        -- be null to prevent integrity constraint violations on acs_objects
        select max(user_id) into v_creation_user from users where user_id = p_party_from;

        -- get the recipient email address
        select max(email) into v_header_to from parties where party_id = p_party_to;

        -- do not let from addresses be null
        if v_header_from is null then
           raise EXCEPTION ' -20000: acs_mail_nt: cannot sent email from blank address.';
        end if;

        -- do not let any of these addresses be null
        if v_header_to is null AND p_expand_group = 'f' then
           raise EXCEPTION ' -20000: acs_mail_nt: cannot sent email to blank address.';
        end if;

	-- set vars 
	select now() into v_creation_date; 
	v_locking_server := null; 
	v_mime_type := 'text/plain';


	if p_expand_group = 'f' then

		insert into acs_mail_lite_queue
                  (message_id,
                   creation_date,
                   locking_server,
                   to_addr,
                   from_addr,
                   reply_to,
                   subject,
                   package_id,
                   mime_type,
                   body
                  )
            values
                   (nextval('acs_mail_lite_id_seq'),
                   v_creation_date,
                   v_locking_server,
                   v_header_to,
                   v_header_from,
                   v_header_from,
                   p_subject ,
                   p_package_id,
                   v_mime_type,
                   p_message
                  );

        else
                -- expand the group
                -- FIXME: need to check if this is a group and if there are members
                --        if not, do we need to notify sender?

                for v_header_to_rec in
                        select email from parties p
                        where party_id in (
                           SELECT u.user_id
                           FROM group_member_map m, membership_rels mr, users u
                           INNER JOIN (select member_id from group_approved_member_map where group_id = p_party_to) mm
                           ON u.user_id = mm.member_id
                           WHERE u.user_id = m.member_id
                           AND m.group_id in (acs__magic_object_id('registered_users'::CHARACTER VARYING))
                           AND m.rel_id = mr.rel_id AND m.container_id = m.group_id
                           AND m.rel_type::TEXT = 'membership_rel'::TEXT
                           AND mr.member_state = 'approved'
                        )
                loop
			insert into acs_mail_lite_queue
			       (message_id,
			       creation_date,
			       locking_server,
			       to_addr,
			       from_addr,
			       reply_to,
			       subject,
			       package_id,
			       mime_type,
			       body
			)
			values
			      (nextval('acs_mail_lite_id_seq'),
			      v_creation_date,
			      v_locking_server,
			      v_header_to_rec.email,
			      v_header_from,
			      v_header_from,
			      p_subject ,
			      p_package_id,
			      v_mime_type,
			      p_message
	               );
                end loop;
        end if;
        return 1;
end;$BODY$ language 'plpgsql';


create or replace function acs_mail_nt__post_request(integer,integer,boolean,varchar,text,integer)
returns integer as $BODY$
declare
        p_party_from            alias for $1;
        p_party_to              alias for $2;
        p_expand_group          alias for $3;   -- default 'f'
        p_subject               alias for $4;
        p_message               alias for $5;
        p_max_retries           alias for $6;   -- default 0
        v_header_from           acs_mail_bodies.header_from%TYPE;
        v_header_to             acs_mail_bodies.header_to%TYPE;
        v_message_id            acs_mail_queue_messages.message_id%TYPE;
        v_header_to_rec         record;
        v_creation_user         acs_objects.creation_user%TYPE;
	v_creation_date		timestamptz;
	v_locking_server	varchar;
	v_mime_type		varchar;
begin
	
	return acs_mail_nt__post_request(p_party_from, p_party_to, p_expand_group, p_subject, p_message, p_max_retries, null);

end;$BODY$ language 'plpgsql';


--------------------------------------------------
-- Shortcut for sending out emails
--
CREATE OR REPLACE FUNCTION im_sendmail(text, text, text, text)
RETURNS integer AS $BODY$
DECLARE
	p_to			alias for $1;
	p_from			alias for $2;
	p_subject		alias for $3;
	p_body			alias for $4;
	v_message_id		integer;
BEGIN
	v_message_id := nextval('acs_mail_lite_id_seq');
	INSERT INTO acs_mail_lite_queue (
		message_id, to_addr, from_addr, subject, body
	) values (
		v_message_id, p_to, p_from, p_subject, p_body
	);
	return v_message_id;
end;$BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION im_sendmail(text, text, text)
RETURNS integer AS $BODY$
DECLARE
	p_to			alias for $1;
	p_subject		alias for $2;
	p_body			alias for $3;
	v_from			varchar;
BEGIN
	SELECT attr_value INTO v_from FROM apm_parameters ap, apm_parameter_values apv 
	WHERE ap.parameter_id = apv.parameter_id and ap.package_key = 'acs-kernel' and ap.parameter_name = 'SystemOwner';

	RETURN im_sendmail(p_to, v_from, p_subject, p_body);
end;$BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION im_sendmail(text, text)
RETURNS integer AS $BODY$
DECLARE
	p_subject		alias for $1;
	p_body			alias for $2;
	v_to			varchar;
BEGIN
	SELECT attr_value INTO v_to FROM apm_parameters ap, apm_parameter_values apv 
	WHERE ap.parameter_id = apv.parameter_id and ap.package_key = 'intrant-core' and ap.package_key = 'SecurityBreachEmail';
	IF v_to is NULL THEN v_to := 'support@project-open.com'; END IF;

	RETURN im_sendmail(v_to, p_subject, p_body);
end;$BODY$
LANGUAGE plpgsql;


-- Debugging: Test im_sendmail with a long string.
-- ToDo: Disable before production use
CREATE OR REPLACE FUNCTION inline_0()
RETURNS integer AS $BODY$
DECLARE
	row		RECORD;
        v_text		varchar;
BEGIN
	v_text := '';
	FOR row IN
		select	apv.package_key || ' ' || apv.version_name as pack
		from	apm_package_versions apv,
			apm_packages ap
		where	apv.installed_p = 't' and
			apv.package_key = ap.package_key
	LOOP
		v_text := v_text || row.pack || E'\n';
	END LOOP;

	PERFORM im_sendmail('intranet-core.upgrade-4.1.0.1.3-4.1.0.1.4.sql', v_text);
        return 0;
end;$BODY$ LANGUAGE plpgsql;
select inline_0();
drop function inline_0();



-- Extend acs_logs for longer keys
alter table acs_logs alter column log_key type text;





---------------------------------------------------------
-- Convert acs_events varchar to text
-- That is important, because triggers write data
-- from im_projects.
--

drop view acs_events_dates;
drop view acs_events_activities;
alter table acs_events alter column name type text;
alter table acs_activities alter column name type text;


-- This view makes the temporal information easier to access
create view acs_events_dates as
select e.*, 
       start_date, 
       end_date
from   acs_events e,
       timespans s,
       time_intervals t
where  e.timespan_id = s.timespan_id
and    s.interval_id = t.interval_id;

-- Postgres is very strict: we must specify 'comment on view', if not a real table
comment on view acs_events_dates is '
    This view produces a separate row for each time interval in the timespan
    associated with an event.
';



-- This view provides an alternative to the get_name and get_description
-- functions
create view acs_events_activities as
select event_id, 
       coalesce(e.name, a.name) as name,
       coalesce(e.description, a.description) as description,
       coalesce(e.html_p, a.html_p) as html_p,
       coalesce(e.status_summary, a.status_summary) as status_summary,
       e.activity_id,
       timespan_id,
       recurrence_id
from   acs_events e,
       acs_activities a
where  e.activity_id = a.activity_id;

comment on view acs_events_activities is '
    This view pulls the event name and description from the underlying
    activity if necessary.
';




create or replace function notification__new(
	integer,integer,integer,timestamptz,integer,integer,
	varchar,text,text,text,timestamptz,integer,varchar,integer
) returns integer as $body$
declare
    p_notification_id               alias for $1;
    p_type_id                       alias for $2;
    p_object_id                     alias for $3;
    p_notif_date                    alias for $4;
    p_response_id                   alias for $5;
    p_notif_user                    alias for $6;
    p_notif_subject                 alias for $7;
    p_notif_text                    alias for $8;
    p_notif_html                    alias for $9;
    p_file_ids                      alias for $10;
    p_creation_date                 alias for $11;
    p_creation_user                 alias for $12;
    p_creation_ip                   alias for $13;
    p_context_id                    alias for $14;
    v_notification_id               integer;
    v_notif_date                    notifications.notif_date%TYPE;
begin
    v_notification_id := acs_object__new(
        p_notification_id,
        'notification',
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        p_context_id
    );

    if p_notif_date is null then
        v_notif_date := now();
    else
        v_notif_date := p_notif_date;
    end if;

    insert
    into notifications
    (notification_id, type_id, object_id, notif_date, response_id, notif_user, notif_subject, notif_text, notif_html, file_ids)
    values
    (v_notification_id, p_type_id, p_object_id, v_notif_date, p_response_id, p_notif_user, p_notif_subject, substring(p_notif_text for 9999), substring(p_notif_html for 9999), p_file_ids);

    return v_notification_id;
end;$body$ language 'plpgsql';



create or replace function notification__new(integer,integer,integer,timestamptz,integer,integer,varchar,text,text,timestamptz,integer,varchar,integer)
returns integer as $body$
declare
    p_notification_id               alias for $1;
    p_type_id                       alias for $2;
    p_object_id                     alias for $3;
    p_notif_date                    alias for $4;
    p_response_id                   alias for $5;
    p_notif_user                    alias for $6;
    p_notif_subject                 alias for $7;
    p_notif_text                    alias for $8;
    p_notif_html                    alias for $9;
    p_creation_date                 alias for $10;
    p_creation_user                 alias for $11;
    p_creation_ip                   alias for $12;
    p_context_id                    alias for $13;
    v_notification_id               integer;
    v_notif_date                    notifications.notif_date%TYPE;
begin
    v_notification_id := acs_object__new(
        p_notification_id,
        'notification',
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        p_context_id
    );

    if p_notif_date is null then
        v_notif_date := now();
    else
        v_notif_date := p_notif_date;
    end if;

    insert
    into notifications
    (notification_id, type_id, object_id, notif_date, response_id, notif_user, notif_subject, notif_text, notif_html)
    values
    (v_notification_id, p_type_id, p_object_id, v_notif_date, p_response_id, p_notif_user, p_notif_subject, substring(p_notif_text for 9999), substring(p_notif_html for 9999));

    return v_notification_id;
end;$body$ language 'plpgsql';








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






-- Fixed issue deleting authorities by
-- deleting parameters now
--
drop function if exists authority__del (integer);
create or replace function authority__del (integer)
returns integer as $body$
begin

  delete from auth_driver_params
  where authority_id = $1;

  perform acs_object__delete($1);

  return 0; 
end;$body$ language 'plpgsql';

