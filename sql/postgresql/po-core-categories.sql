-- /packages/intranet-core/sql/postgres/intranet-core-categories.sql
--
-- Copyright (C) 1999-2004 Project/Open
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
-- @author	various@arsdigita.com
-- @author      frank.bergmann@project-open.com

-- ------------------------------------------------------------
-- po-core-categories.sql
-- 25.6.2003, Frank Bergmann <fraber@fraber.de>
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Po_Categories
--
-- We insert all of the PO-Core po_categories more as a 
-- starting point/reference for other companies. 
-- Feel free to change these either here in the data model 
-- or through the category editor.
-- ------------------------------------------------------------


--------- Core ----------------------------------
-- 100-199	Company Status
-- 200-299	Company Type
-- 300-399	Project Status
-- 400-499	Project Type
-- 500-599	Departments
-- 600-699	Company Anual Revenues


-- Company Status
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '101', 'Potential', 'Company Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '102', 'Inquiries', 'Company Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '103', 'Qualifying', 'Company Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '104', 'Quoting', 'Company Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '105', 'Quote out', 'Company Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '106', 'Active', 'Company Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '107', 'Declined', 'Company Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '108', 'Inactive', 'Company Status');


-- Company Types
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '201', 'Translation Agency', 'Company Type');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '202', 'Final Client', 'Company Type');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '203', 'Localization', 'Company Type');
INSERT INTO po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '204', 'Internal', 'Company Type');
INSERT INTO po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '205', 'Milengo', 'Company Type');


-- Project Status
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '301', 'Potential', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '302', 'Inquiring', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '303', 'Qualifying', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '304', 'Quoting', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '305', 'Quote Out', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '306', 'Open', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '307', 'Declined', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '308', 'Delivered', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '309', 'Invoiced', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '310', 'Partially Paid', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '311', 'Closed', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '312', 'Deleted', 'Project Status');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '313', 'Canceled', 'Project Status');


-- Project Type
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '400', 'Localization', 'Project Type');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '401', 'Other', 'Project Type');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '402', 'Technology', 'Project Type');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '403', 'Unknown', 'Project Type');


-- Departments
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '501', 'Administration', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '502', 'Business Development', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '503', 'Client services', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '504', 'Finance', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '505', 'Internal IT Support', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '506', 'Legal', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '507', 'Marketing', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '508', 'Office management', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '509', 'Operations', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '510', 'Human Resources', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '511', 'Sales', 'Department');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '512', 'Senior Management', 'Department');



-- Anual Revenue
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '601', 'EUR 0-1k', 'Annual Revenue');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '602', 'EUR 1-10k', 'Annual Revenue');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '603', 'EUR 10-100k', 'Annual Revenue');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '604', '> EUR 100k', 'Annual Revenue');
insert into po_categories (PROFILING_WEIGHT, CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('1', '', 'f', '605', 'Pre-revenue', 'Annual Revenue');

