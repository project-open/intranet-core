<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>


<h1>User Exits &amp; Their Status</h1>

<form name=user_exits action=invoke method=POST>
<input type=hidden name=user_exit value="">

<table>
<tr valign=top>
<td>

	<table class="list">
	  <tr class="list-header">
	    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Name "Name"] %></th>
	    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Exists "Exists"] %></th>
	    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Executable "Execut<br>able"] %></th>
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
	      <if @exits.exists_p@>exists</if>
	      <else>-</else>
	    </td>
	    <td class="list-narrow">
	      <if @exits.executable_p@>exec</if>
	      <else>
		<if @exits.exists_p@><font color=red>not executable</font></if>
		<else>-</else>
	      </else>
	    </td>
	    <td class="list-narrow">
		<if @exits.executable_p@>
		<input type=image src=/intranet/images/newfol.gif width=21 height=21 onClick="window.document.user_exits.user_exit.value='@exits.exit_name@'; submit();" title='Invoke' alt='Invoke'>
	        </if>
	    </td>
	  </tr>
	  </multiple>
	</table>

</td><td>

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




<h1>Parameters</h1>

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
