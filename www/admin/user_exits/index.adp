<master>

<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>

<form action=exits-delete method=post>

<table class="list">

  <tr class="list-header">
    <th class="list-narrow">#intranet-core.Name#</th>
    <th class="list-narrow">#intranet-core.Exists#</th>
    <th class="list-narrow">#intranet-core.Executable#</th>
<!--    <th class="list-narrow">#intranet-core.Del#</th> -->
  </tr>

  <multiple name=exits>
  <if @exits.rownum@ odd>
    <tr class="list-odd">
  </if> <else>
    <tr class="list-even">
  </else>
  
    <td class="list-narrow">
	@exits.exit_name@
    </td>
    <td class="list-narrow">
	@exits.exists_p@
    </td>

    <td class="list-narrow">
	@exits.executable_p@
    </td>

<!-- 
    <td class="list-narrow">
	<input type="checkbox" name="exit.@exits.exit_name@">
    </td>
-->
  </tr>
  </multiple>
</table>

<table width=100%>
  <tr>
    <td colspan=99 align=right>
      <input type=submit value="Delete">
    </td>
  </tr>
</table>

</form>


<ul>
<li><A href=widget-new>#intranet-dynfield.Create_a_new_Widget#</a>
</ul>

