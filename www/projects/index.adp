<master src="../master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@project_navbar_html;literal@</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="show_context_help">@show_context_help_p;literal@</property>

<!-- Show calendar on start- and end-date -->
<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
window.addEventListener('load', function() { 
     document.getElementById('start_date_calendar').addEventListener('click', function() { showCalendar('start_date', 'y-m-d'); });
     document.getElementById('end_date_calendar').addEventListener('click', function() { showCalendar('end_date', 'y-m-d'); });
});
</script>

<if 0 eq @plugin_id@>

	<table cellspacing="0" cellpadding="0" border="0" width="100%">
	<tr valign="top">
	<td>
		<form action="/intranet/projects/project-action" method=POST>
		<%= [export_vars -form {return_url}] %>
		<table class="table_list_page">
	            <%= $table_header_html %>
	            <%= $table_body_html %>
	            <%= $table_continuation_html %>
		</table>
		</form>
	</td>
	<td width="<%= $dashboard_column_width %>">
	<%= $dashboard_column_html %>
	</td>
	</tr>
	</table>

</if>
<else>

	<%= [im_component_page -plugin_id $plugin_id -return_url $return_url] %>

</else>

