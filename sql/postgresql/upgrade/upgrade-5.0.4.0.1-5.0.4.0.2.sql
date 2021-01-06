SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.4.0.1-5.0.4.0.2.sql','');

-- These menus are being treated differently in the Admin menu
update im_menus set visible_tcl = null where visible_tcl = '0';
update im_menus set visible_tcl = null where visible_tcl = '';
update im_menus set visible_tcl = null where visible_tcl = 't';


