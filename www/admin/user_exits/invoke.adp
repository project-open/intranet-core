<master src="../master">

<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="admin_navbar_label">admin_user_exits</property>


<h1>Call Results</h1>

<table class="list">
  <tr class="list-header">
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Name "Name"] %></th>
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Value "Value"] %></th>
  </tr>
  <tr>  
    <td class="list-narrow">User Exit</td>
    <td class="list-narrow">@user_exit@</td>
  </tr>
  <tr>  
    <td class="list-narrow">Call Command</td>
    <td class="list-narrow">@user_exit_call@</td>
  </tr>
  <tr>  
    <td class="list-narrow">Return Code</td>
    <td class="list-narrow">@err_code@</td>
  </tr>
</table>


<h1>Trace Log</h1>

<table class="list">
  <tr class="list-header">
    <th class="list-narrow">#intranet-core.Id#</th>
    <th class="list-narrow">#intranet-core.Date#</th>
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Level "Level"] %></th>
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Key "Key"] %></th>
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Message "Message"] %></th>
  </tr>
  <multiple name=logs>
    <if @logs.rownum@ odd>
      <tr class="list-odd">
    </if> <else>
      <tr class="list-even">
    </else>
    <td class="list-narrow">
	@logs.log_id@
    </td>
    <td class="list-narrow">
	@logs.log_date_pretty@
    </td>
    <td class="list-narrow">
	@logs.log_level@
    </td>
    <td class="list-narrow">
	@logs.log_key@
    </td>
    <td class="list-narrow">
	<pre>@logs.message@</pre>
    </td>
  </tr>
  </multiple>
</table>
