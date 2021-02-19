SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.4.0.2-5.0.4.0.3.sql','');

-- Use HTTPS everywhere.
-- Otherwise CSP may complain about unsafe connections
--
update apm_parameter_values
set attr_value = replace(attr_value, 'http://', 'https://')
where attr_value like 'http://%';
