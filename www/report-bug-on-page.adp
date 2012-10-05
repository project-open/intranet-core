<master>
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">help</property>

<% set error_location "[ns_info address] on [ns_info platform]" %>
<% set report_url [ad_parameter -package_id [im_package_core_id] "ErrorReportURL" "" ""] %>
<% set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""] %>
<% db_1row user_info "select * from cc_users where user_id=[ad_get_user_id]" %>
<% set publisher_name [ad_parameter -package_id [ad_acs_kernel_id] PublisherName "" ""] %>
<% set package_versions [db_list package_versions "select v.package_key||':'||v.version_name from (select max(version_id) as version_id, package_key from apm_package_versions group by package_key) m, apm_package_versions v where m.version_id = v.version_id"] %>


<form action="@report_url;noquote@" method=POST>
<input type=hidden name=error_location value=@error_location@>
<input type=hidden name=system_url value=@system_url@>
<input type=hidden name=error_first_names value=@first_names;noquote@>
<input type=hidden name=error_last_name value=@last_name;noquote@>
<input type=hidden name=error_user_email value=@email;noquote@>
<input type=hidden name=package_versions value="@package_versions;noquote@">
<input type=hidden name=publisher_name value="@publisher_name;noquote@">

<table cellpadding=0 cellspacing=0 border=0>
<tr class=rowtitle>
	<td colspan=2 class=rowtitle align=center>@page_title@</td>
</tr>
<tr class=roweven>
	<td>#intranet-core.URL#</td>
	<td><input type=text name=eror_url value="@page_url;noquote@" size=40></td>
</tr>
<tr class=rowodd>
	<td>#intranet-core.What_is_wrong#</td>
	<td><textarea name=error_message cols=60 rows=10>@tell_us_what_is_wrong_msg@</textarea></td>
</tr>
<tr class=rowodd>
	<td>#intranet-core.How_it_should_be_right#</td>
	<td><textarea name=error_info cols=60 rows=10>@tell_us_what_should_be_right_msg@</textarea></td>
</tr>
<tr class=roweven>
	<td></td>
	<td>
		<input type=submit>
		I agree with the <a href="http://www.project-open.com/en/company/project-open-privacy.html">privacy statement</a>.
	</td>
</tr>
</table>
</form>
