-- /packages/intranet-core/sql/stage-32.sql
--
-- Convert a database from a Linux system (ptdemo)
-- to a Windows system. Basicly, we have to modify
-- the filestorage parameters
--
-- @author      frank.bergmann@project-open.com

-----------------------------------------------------------
-- Replace Parameters

-- Replace all parameters with "/web/ptdemo" by "C:/ProjectOpen"
update apm_parameter_values
set attr_value = 'C:/ProjectOpen' || substring(attr_value, 12)
where attr_value like '/web/ptdemo%';

-- replace the find command from "/usr/bin/find" to "/bin/find" for CygWin
update apm_parameter_values
set attr_value = '/bin/find'
where attr_value = '/usr/bin/find';


-- We still need to uninstall the packages that are not public...


