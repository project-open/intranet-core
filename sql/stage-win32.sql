-- /packages/intranet-core/sql/stage-32.sql
--
-- Convert a database from a Linux system (ptdemo)
-- to a Windows system. Basically, we have to modify
-- the filestorage parameters
--
-- @author      frank.bergmann@project-open.com

-----------------------------------------------------------
-- Replace Filestorage Directories

-- Replace all parameters with "/web/ptdemo" by "C:/ProjectOpen"
update apm_parameter_values
set attr_value = 'C:/ProjectOpen' || substring(attr_value, 12)
where attr_value like '/web/ptdemo%';

-- replace the find command from "/usr/bin/find" to "/bin/find" for CygWin
update apm_parameter_values
set attr_value = '/bin/find'
where attr_value = '/usr/bin/find';

-- Set the "Home Path" to the P/O documentation dir.
update apm_parameter_values
set attr_value = 'C:/ProjectOpen/doc'
where parameter_id in (
	select parameter_id
	from apm_parameters
	where parameter_name = 'HomeBasePathUnix'
      );

-- Close the "images" folder of object 0 (Home FS)
-- so that the images are hidden
update im_fs_folder_status
set open_p = 'c'
where folder_id in (
	select folder_id
	from im_fs_folders
	where object_id = 0 and path = 'images'
);


-----------------------------------------------------------
-- Enable Components

-- Enable the help text on the home page
update im_component_plugins
set location = 'left'
where plugin_name = 'Home Page Help Blurb';



-- We still need to uninstall the packages that are not public...


