<master src="../master">
<property name=title>#intranet-core.Email_sent#</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>

<h1>
<if @send_email_p@>
  #intranet-core.lt_first_names_last_name_2#
</if>
<else>
  #intranet-core.No_Email_Has_Been_Sent#
</else>
</h1>

<p>#intranet-core.Next_Steps#
</p>

<ul>
  <li>
    <a href="@return_url@">
    #intranet-core.Return_To_Previous_Page# 
    </a>
  </li>
  <li>
    #intranet-core.lt_View_administrative_p# 
    <a href="/intranet/users/view?@export_vars@">@first_names@ @last_name@</a>
  </li>
  <li>
    #intranet-core.Return_to# 
    <a href="/intranet/users/">#intranet-core.user_administration#</a>
  </li>
  <li>
    <a href="/intranet/users/new">#intranet-core.Add_a_new_User#</a>
  </li>
</ul>
</p>


