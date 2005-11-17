<master src="../master">
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">projects</property>

<%= $project_filter_html %>
<%= $project_navbar_html %>
<table width=100% cellpadding=2 cellspacing=2 border=0>
  <%= $table_header_html %>
  <%= $table_body_html %>
  <%= $table_continuation_html %>
</table>


