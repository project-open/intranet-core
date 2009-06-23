# /packages/intranet-core/www/intranet/companies/company-offices.xml.tcl
#
# Copyright (C) 1998-2004 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

ad_page_contract {
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    {user_id:integer 0}
    {auth_token ""}
    {company_id:integer 612}
}

# Check for valid user/auth_token combination
set valid_p [im_valid_auto_login_p -check_user_requires_manual_login_p 0 -user_id $user_id -auto_login $auth_token]
if {!$valid_p} { 
    doc_return 200 "text/xml" "<xml><error>Login error: Wrong user/password combination.</error></xml>"
    ad_script_abort
}

# Check if the user can see that company
im_company_permissions $user_id $company_id view read write admin
if {!$read} {
    doc_return 200 "text/xml" "<xml><error>Permission error: User has no rights to read company \#$company_id.</error></xml>"
    ad_script_abort
}

# Select out the offices for that company and format as XML
set offices_xml ""
set sql "
	select	o.office_id, o.office_name
	from	im_offices o
	where	o.company_id = :company_id
	order by o.office_name
"
db_foreach offices $sql {
    append offices_xml "
	<item>
	   <id>$office_id</id>
	   <name>$office_name</name>
	</item>
   "
}

doc_return 200 "text/xml" "
<xml>
$offices_xml
</xml>
"
