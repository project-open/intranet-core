<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">user</property>

<table cellspacing=0 cellpadding=0>
<tr valign=top>
  <td>
      <formtemplate id="@form_id@"></formtemplate>

<if @admin_html@ ne "">

  <td>&nbsp;</td>

  <td valign=top>
    <table border=0 cellpadding=0 cellspacing=0>
    <tr valign=top>
      <td class=rowtitle align=center>
        #intranet-core.Admin_Users#
      </td>
    </tr>
    <tr valign=top>
      <td>
        @admin_html;noquote@
      </td>
    </tr>
    </table>
  </td>

  <endif>

</tr>
</table>
@page_body;noquote@