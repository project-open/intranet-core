<if @template_p@>
<master src="/packages/intranet-core/www/master">
<property name="focus">party_ae.first_names</property>
</if>

<formtemplate id="contact"></formtemplate>

<br>

<if "" ne @found_user_id@>
<h2><%= [lang::message::lookup "" intranet-core.Exact_User_Match "Exact User Match"] %></h2>
<p>
<%= [lang::message::lookup "" intranet-core.We_have_found_an_exact_match "We have found an exact match for user %found_user_name% (%found_user_email%)."] %>
</p>
<br>
</if>


<if @search_results_p@>

<table>
<tr valign="top">
<td valign="top">
    <h2>Companies</h2>
    <p>
    <listtemplate name="company_list"></listtemplate>
    </p>
    <br>
</td>
<td>
    <h2>Users</h2>
    <p>
    <listtemplate name="contact_list"></listtemplate>
    </p>
    <br>
</td>
</tr>
</table>

</if>
