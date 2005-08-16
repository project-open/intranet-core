<master src="../master">
<property name="title">#intranet-core.Companies#</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">projects</property>

<%= [im_gif cleardot "" 0 1 3] %>

<!--
<if "" ne @action_html@>
<p>
@action_html;noquote@
</p>
</if>
-->

<%= $project_filter_html %>
<%= $project_navbar_html %>
<table width=100% cellpadding=2 cellspacing=2 border=0>
  <%= $table_header_html %>
  <%= $table_body_html %>
  <%= $table_continuation_html %>
</table>


