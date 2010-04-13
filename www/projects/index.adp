<master src="../master">
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@project_navbar_html;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>
<property name="show_context_help">@show_context_help_p;noquote@</property>

<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>

<table cellspacing=0 cellpadding=0 border=0 width="100%">
<tr valign=top>
<td>

	<table class="table_list_page">
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
	</table>

</td>
<td width="<%= $dashboard_column_width %>">
<%= $dashboard_column_html %>
</td>
</tr>
</form>
</table>
