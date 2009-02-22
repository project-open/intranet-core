<master src="../master">
<property name="title">#intranet-core.Companies#</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">companies</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<%= [im_box_header [_ intranet-core.Companies]] %>
<table class="table_list_page">
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
</table>
<%= [im_box_footer] %>
