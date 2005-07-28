

create view registered_users
as
  select p.email, p.url, pe.first_names, pe.last_name, u.*, mr.member_state
  from parties p, persons pe, users u, group_member_map m, membership_rels mr
  where party_id = person_id
  and person_id = user_id
  and u.user_id = m.member_id
  and m.rel_id = mr.rel_id
  and m.group_id = acs__magic_object_id('registered_users')
  and m.container_id = m.group_id
  and m.rel_type = 'membership_rel'
  and mr.member_state = 'approved'
  and u.email_verified_p = 't';


-- faster simpler view
-- does not check for registered user/banned etc
create or replace view acs_users_all
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;


create view cc_users
as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr
where o.object_id = pa.party_id
  and pa.party_id = pe.person_id
  and pe.person_id = u.user_id
  and u.user_id = m.member_id
  and m.group_id = acs__magic_object_id('registered_users')
  and m.rel_id = mr.rel_id
  and m.container_id = m.group_id
  and m.rel_type = 'membership_rel';






create or replace view users_active as
select
        u.user_id,
        u.username,
        u.screen_name,
        u.last_visit,
        u.second_to_last_visit,
        u.n_sessions,
        u.first_names,
        u.last_name,
        c.home_phone,
        c.priv_home_phone,
        c.work_phone,
        c.priv_work_phone,
        c.cell_phone,
        c.priv_cell_phone,
        c.pager,
        c.priv_pager,
        c.fax,
        c.priv_fax,
        c.aim_screen_name,
        c.priv_aim_screen_name,
        c.msn_screen_name,
        c.priv_msn_screen_name,
        c.icq_number,
        c.priv_icq_number,
        c.m_address,
        c.ha_line1,
        c.ha_line2,
        c.ha_city,
        c.ha_state,
        c.ha_postal_code,
        c.ha_country_code,
        c.priv_ha,
        c.wa_line1,
        c.wa_line2,
        c.wa_city,
        c.wa_state,
        c.wa_postal_code,
        c.wa_country_code,
        c.priv_wa,
        c.note,
        c.current_information
from
        registered_users u left outer join users_contact c on u.user_id = c.user_id
;

