<master>

<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>


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
    <td class="list-narrow">Return Message</td>
    <td class="list-narrow"><pre>@err_str@</pre></td>
  </tr>

</table>

