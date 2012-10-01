<master src="../master">
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="main_navbar_label">admin</property>
  <property name="focus">@page_focus;noquote@</property>
  <property name="admin_navbar_label">admin_categories</property>
  <property name="left_navbar">@left_navbar_html;noquote@</property>



<table width="100%">
<tr valign=top>
<td>
	<h1>@page_title@</h1>
	<%= [lang::message::lookup "" intranet-core.Categories_List_Help "
		<p>
		This page allows you to configure 'categories'
		(the contents of most drop-down boxes in the system).
		</p><p>
		Please <b>do not change categories unless you know what you
		are doing</b>. Many categories are used as constants
		and changing them will break the system.
		</p><p>
		Instead, please use 'Category translation' to change the
		way how categories appear in the GUI.
		 </p><p>
		In some rare cases changes in category types might require <a href='/acs-admin/cache/'>flushing</a> the cache manually or restarting the web server.  
        "] %>
<br><br>
	<ul>
	<li><a href='http://www.project-open.org/en/page_intranet_admin_categories_index'>Help about this page</a>
	<li><a href='http://www.project-open.org/en/list_categories'>Help about the meaning of categories</a>
<if "All" ne @select_category_type@>
	<li><a href='@category_help_url;noquote@'>Help about '@select_category_type@'</a>
</if>
	</ul>

<br><br>
</td>
</tr>
</table>


<if @show_add_new_category_p@>
	@category_list_html;noquote@
</if>
<else>
	<listtemplate name="categories"></listtemplate>
</else>
