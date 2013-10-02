<if @template_p@>
<master>
<property name="focus">party_ae.first_names</property>
</if>

<formtemplate id="contact"></formtemplate>

<br>

<if "" ne @found_user_id@>
<h2>Exact User Match</h2>
<p>
We have found an exact match for user @found_user_name@ (@found_user_email@).
</p>
<br>
</if>


<if @search_results_p@>

<table>
<tr valign=top>
<td valign=top>
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
