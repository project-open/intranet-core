-- -----------------------------------------------
--
-- poall.post-patch.sql
-- 2005-05-05 Frank Bergmann <frank.bergmann@project-open.com>
--
-- Patching a PostgreSQL database dump to recover
-- three missing views. These views are not imported
-- correctly from database dumps that are created with
-- PostgreSQL versions < 7.4.6 because of a bug with the
-- load order of the database statements.
--
-- So we are basicly executing the same statement again.
--
-- -----------------------------------------------


CREATE VIEW cc_users AS
    SELECT o.object_id, o.object_type, o.context_id, o.security_inherit_p, o.creation_user, o.creation_date, o.creation_ip, o.last_modified, o.modifying_user, o.modifying_ip, o.tree_sortkey, o.max_child_sortkey, pa.party_id, pa.email, pa.url, pe.person_id, pe.first_names, pe.last_name, u.user_id, u.authority_id, u.username, u.screen_name, u.priv_name, u.priv_email, u.email_verified_p, u.email_bouncing_p, u.no_alerts_until, u.last_visit, u.second_to_last_visit, u.n_sessions, u."password", u.salt, u.password_question, u.password_answer, u.password_changed_date, u.auth_token, mr.member_state, mr.rel_id FROM acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr WHERE ((((((((o.object_id = pa.party_id) AND (pa.party_id = pe.person_id)) AND (pe.person_id = u.user_id)) AND (u.user_id = m.member_id)) AND (m.group_id = acs__magic_object_id('registered_users'::character varying))) AND (m.rel_id = mr.rel_id)) AND (m.container_id = m.group_id)) AND ((m.rel_type)::text = 'membership_rel'::text));


CREATE VIEW registered_users AS
    SELECT p.email, p.url, pe.first_names, pe.last_name, u.user_id, u.authority_id, u.username, u.screen_name, u.priv_name, u.priv_email, u.email_verified_p, u.email_bouncing_p, u.no_alerts_until, u.last_visit, u.second_to_last_visit, u.n_sessions, u."password", u.salt, u.password_question, u.password_answer, u.password_changed_date, u.auth_token, mr.member_state FROM parties p, persons pe, users u, group_member_map m, membership_rels mr WHERE (((((((((p.party_id = pe.person_id) AND (pe.person_id = u.user_id)) AND (u.user_id = m.member_id)) AND (m.rel_id = mr.rel_id)) AND (m.group_id = acs__magic_object_id('registered_users'::character varying))) AND (m.container_id = m.group_id)) AND ((m.rel_type)::text = 'membership_rel'::text)) AND ((mr.member_state)::text = 'approved'::text)) AND (u.email_verified_p = true));


CREATE VIEW users_active AS
    SELECT u.user_id, u.username, u.screen_name, u.last_visit, u.second_to_last_visit, u.n_sessions, u.first_names, u.last_name, c.home_phone, c.priv_home_phone, c.work_phone, c.priv_work_phone, c.cell_phone, c.priv_cell_phone, c.pager, c.priv_pager, c.fax, c.priv_fax, c.aim_screen_name, c.priv_aim_screen_name, c.msn_screen_name, c.priv_msn_screen_name, c.icq_number, c.priv_icq_number, c.m_address, c.ha_line1, c.ha_line2, c.ha_city, c.ha_state, c.ha_postal_code, c.ha_country_code, c.priv_ha, c.wa_line1, c.wa_line2, c.wa_city, c.wa_state, c.wa_postal_code, c.wa_country_code, c.priv_wa, c.note, c.current_information FROM (registered_users u LEFT JOIN users_contact c ON ((u.user_id = c.user_id)));

