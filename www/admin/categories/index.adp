<master src="../master">
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="main_navbar_label">admin</property>
  <property name="focus">@page_focus;literal@</property>
  <property name="admin_navbar_label">admin_categories</property>
  <property name="left_navbar">@left_navbar_html;literal@</property>

<table width="100%">
<tr valign="top">
<td>
	<h1>@page_title@</h1>
	<%= [lang::message::lookup "" intranet-core.Categories_List_Help "
		<p>
		This page allows you to configure 'categories' (the contents of most drop-down boxes in the system).
		</p>
		
	  <span style=\"color:red;font-weight:bold\">Please keep the following in mind when working with categories:</span>
	  <ul>
	  <li>Never <strong>DELETE</strong> categories unless you know what you are doing. Instead <strong>DISBALE</strong> them if they are not needed.</li>
	  <li>Some twenty or so core CATEGORY ELEMENTS are required by the system. <strong>DISABLING</strong> them might break parts of the system.</li>
	  <li>Never change CATEGORY NAMES unless you know what you are doing. Instead make adjustments to the naming in the CATEGORY TRANSLATIONS. This way you change how they appear in the GUI.</li>
	  <li>In some rare cases changes in category types might require <a href='/acs-admin/cache/'>flushing</a> the cache manually or restarting the web server.</li>
	  </ul> 

	<ul>
	<li><a href='http://www.project-open.com/en/page-intranet-admin-categories-index'>Help about this page</a>
	<li><a href='http://www.project-open.com/en/list-categories'>Help about the meaning of categories</a>
"]%>
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


<script type="text/javascript">
	$(document).ready(function() { 
		$("#myTable").tablesorter(); 
	}); 
</script>
