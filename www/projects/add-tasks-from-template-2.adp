<master src="../master">
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label">projects</property>

<form action=clone-2.tcl method=POST>
<%= [export_vars -form {return_url parent_project_id company_id}] %>
  <table border="0">
    <tr> 
      <td colspan="2" class=rowtitle>
        @page_title@
      </td>
    </tr>
    <tr> 
      <td>@page_title@:</td>
      <td> 
        <%= [im_project_template_select template_project_id $template_project_id] %>
	<%= [im_gif help [lang::message::lookup "" intranet-core.List_all_templates_blurb "Lists all template projects and project with a name containing 'Template'."]] %> &nbsp; 
      </td>
    </tr>
    <tr> 
      <td valign="top"> 
	<div align="right">&nbsp; </div>
      </td>
      <td> 
	  <p> 
	    <input type="submit" value="@button_text@" name="submit2">
	  </p>
      </td>
    </tr>
  </table>
</form>

<script <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
function blockUserActions() {
	var a = document.getElementsByName("submit2");
	var p = document.createElement("p");
	p.innerText = "Attendi..";
	a[0].style = "display:none";
	var n = document.forms.length;
	document.forms[n-1].appendChild(p);
}
</script>
