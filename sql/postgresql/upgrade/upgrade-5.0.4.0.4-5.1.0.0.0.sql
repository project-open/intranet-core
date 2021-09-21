SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.4.0.4-5.1.0.0.0.sql','');

-- Create a 0 category as a workaround for the status of users/
-- employees/persons/parties which is 0 because there is no status
SELECT im_category_new(0, 'Unknown', 'Intranet Object Status');
