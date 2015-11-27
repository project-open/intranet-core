<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context_bar;literal@</property>
<property name="main_navbar_label">user</property>
<property name="sub_navbar">@sub_navbar;literal@</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="show_context_help_p">@show_context_help_p;literal@</property>

<table class="table_list_page">
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
</table>

<if @debug_html@ ne "">
<ul>
	@debug_html;noquote@
</ul>
</if>