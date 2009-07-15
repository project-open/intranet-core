<master src="../master">
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="admin_navbar_label">admin_categories</property>


<form method=GET action=index.tcl>
<table width="100%">
<tr valign=top>
  <td width="50%">

	<table border=0 cellpadding=0 cellspacing=0>
	<tr> 
	  <td class=rowtitle align=center>
	    Filter Category Types
	  </td>
	</tr>
	<tr>
	  <td>
	    @category_select_html;noquote@
	    <input type=submit name=Submit value=go>
	  </td>
	</tr>
	</table>

	<table border=0 cellpadding=0 cellspacing=0>
	<tr> 
	  <td class=rowtitle align=center>
	    <span style="font-size:70%;font:italic">Note: Some category-types are mandatory and shouldn't be manipulated.<br>Please consult the "PO Configuration Guide" for more details. </span>
	  </td>
	</tr>
	</table>


  </td>
  <td width="50%">


	<table border=0 cellpadding=0 cellspacing=0>
	<tr> 
	  <td class=rowtitle align=center>
	    Admin Links
	  </td>
	</tr>
	<tr>
	  <td>
	    <ul>
<if @show_add_new_category_p@>
	      <li>
		<a href="@new_href;noquote@">Add a new Category</a>  
</if>
<else>
	      <li>
		<a href="one?new_category=1">
		  Add a new Category Type
		</a>  
</else>
 	    </ul>
	  </td>
	</tr>
	</table>

  </td>
</tr>
</table>
</form>



@category_list_html;noquote@
