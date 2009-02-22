<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">user</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<%= [im_box_header $page_title $list_icons] %>
<table>
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
</table>
<%= [im_box_footer] %>

