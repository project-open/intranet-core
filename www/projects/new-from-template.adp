<master src="../master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>

<form action=new-from-template-2.tcl method=POST>
<%= [export_form_vars return_url parent_project_id company_id clone_postfix] %>

  <table border=0>
    <tr> 
      <td colspan=2 class=rowtitle>
        @page_title@
      </td>
    </tr>
    <tr> 
      <td>@page_title@:</td>
      <td> 
        <%= [im_project_template_select template_project_id $template_project_id] %>
	<%= [im_gif help "Lists all template projects and project with a name containing 'Template'."] %> &nbsp; 
      </td>
    </tr>

    <tr> 
      <td valign=top> 
	<div align=right>&nbsp; </div>
      </td>
      <td> 
	  <p> 
	    <input type=submit value="@button_text@" name=submit2>
	  </p>
      </td>
    </tr>
  </table>
</form>
