<master src="../master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>

<form action=clone-2.tcl method=POST>
<%= [export_form_vars return_url parent_project_id company_id clone_postfix] %>

  <table border=0>
    <tr> 
      <td colspan=2 class=rowtitle>
        #intranet-core.Project_Base_Data#
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_Name#</td>
      <td> 
	<input type=text size=40 name=project_name value="@project_name@">
	<%= [im_gif help "Please enter any suitable name for the project. The name must be unique."] %>
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_# &nbsp;</td>
      <td> 
	<input type=text size="@project_nr_field_size@" name=project_nr value="@project_nr@" maxlength="@project_nr_field_size@" >
	<%= [im_gif help "A project number is composed by 4 digits for the year plus 4 digits for current identification"] %> &nbsp; 
      </td>
    </tr>

    @clone_html;noquote@

    <tr> 
      <td valign=top> 
	<div align=right>&nbsp; </div>
      </td>
      <td> 
	  <p> 
	    <input type=submit value="@button_text@" name=submit2>
	    <%= [im_gif help "Create the new folder structure"] %>
	  </p>
      </td>
    </tr>
  </table>
</form>
