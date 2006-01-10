
-------------------------------------------------------
-- Run this SQL script in order to change a Windows
-- "Preconf" for a Linux server.
-------------------------------------------------------


update apm_parameter_values
set attr_value = '/web/enso/' || substring(attr_value, 16)
where
	attr_value like 'C:/ProjectOpen/%';

