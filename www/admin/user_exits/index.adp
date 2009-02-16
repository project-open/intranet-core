<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="admin_navbar_label">admin_user_exits</property>


<form name=user_exits action=invoke method=POST>
<input type=hidden name=user_exit value="">

<table>
<tr valign=top>
<td>
	<h1>"User Exits"</h1>

	<table class="list">
	  <tr class="list-header">
	    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Name "Name"] %></th>
	    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Status "Status"] %></th>
	    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Invoke "Invoke"] %></th>
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

	      <if @exits.executable_p@>OK</if>
	      <else>
		<if @exits.exists_p@><font color=red>Not Executable</font></if>
		<else>Not defined</else>
	      </else>
	    </td>
	    <td class="list-narrow">
		<if @exits.executable_p@>
		<input type=submit value="Invoke" onClick="window.document.user_exits.user_exit.value='@exits.exit_name@'; submit();">
	        </if>
	    </td>
	  </tr>
	  </multiple>
	</table>

</td><td>

	<h1>Test Parameters</h1>

	<table class="list">
	  <tr class="list-header">
	    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Name "Name"] %></th>
	    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Value "Value"] %></th>
	  </tr>
	  <tr>
	    <td class="list-narrow">User_Id</td>
	    <td class="list-narrow">
	      <input type=text name=user_id value=@default_user_id@ size=6>
	    </td>
	  </tr>
	  <tr>
	    <td class="list-narrow">Project_Id</td>
	    <td class="list-narrow">
	      <input type=text name=project_id value=@default_project_id@ size=6>
	    </td>
	  </tr>
	  <tr>
	    <td class="list-narrow">Company_Id</td>
	    <td class="list-narrow">
	      <input type=text name=company_id value=@default_company_id@ size=6>
	    </td>
	  </tr>
	  <tr>
	    <td class="list-narrow">Trans_Task_Id</td>
	    <td class="list-narrow">
	      <input type=text name=trans_task_id value=@default_trans_task_id@ size=6>
	    </td>
	  </tr>
	</table>

<br>

	<table width=400>
	<tr><td>
	<blockquote>
	User Exits are "hooks" for external system that get called from
	<nobr><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span></nobr>
	every time a specific action has been exececuted such as creating,
	modifying and deleting an object.
	<p>
	Please refer to the PO-Configuration-Guide for details on User Exists
	and consult the source code of the User Exit scripts and the included
	comments.
	<p>
	You may have to <strong>restart your server</strong> to activate 
	changes of parameter values.
	</blockquote>
	</td></tr>
	</table>

</td></tr>
</table>


</form>




<h1>Global Parameters</h1>

<table class="list">
  <tr class="list-header">
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Name "Name"] %></th>
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Value "Value"] %></th>
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Comment "Comment"] %></th>
  </tr>
  <tr>
    <td class="list-narrow">User Exit Path</td>
    <td class="list-narrow">@user_exit_path@</td>
    <td class="list-narrow">Where are the User Exits located?</td>
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
