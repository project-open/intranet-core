<master src="../master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context_bar;literal@</property>
<property name="main_navbar_label">admin</property>

<%= [im_box_header [lang::message::lookup "" intranet-ganttproject.Upload_Template "Upload a Template"]] %>
<p>
  <%= [lang::message::lookup "" intranet-core.Upload_Template_Msg "
	Please upload a file with a file name having the following structure: </br><br/>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;TemplateName.locale.ext<br>
	<br/>       
	Examples:
	<ul>
	<li>'template.en.adp': An English HTML ('.adp') template.
	<li>'invoice.de.odt': A German OpenOffice ('.odt') template apparently for invoices.
	</ul>
  "] %><br/>
</p>&nbsp;<br>

<form enctype="multipart/form-data" method="POST" action="template-upload-2.tcl">
<%= [export_vars -form {project_id return_url}] %>
<table border="0">
  <tr>
    <td><%= [lang::message::lookup "" intranet-core.File "File"] %>:</td>
    <td>
      <input type="file" name="upload_file" size="30">
    </td>
  </tr>
  <tr>
    <td></td>
    <td>
      <br/>
      <input type="submit" name="submit" value="Submit">
    </td>
  </tr>
</table>
</form>
<%= [im_box_footer] %>

