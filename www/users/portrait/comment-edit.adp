<master src="../../master">
<property name="title">#acs-subsite.lt_Edit_comment_for_the_#</property>
<property name="main_navbar_label">user</property>
<property name="context">@context;noquote@</property>

<form method="post" action="comment-edit-2.tcl">
@export_vars;noquote@
#acs-subsite.Story_behind_photo#:<br />
<textarea rows="6" cols="50" wrap="<%=[im_html_textarea_wrap]%>" name="description">@description@</textarea>


<p><center>
<input type="submit" value="#acs-subsite.Save_comment#" />
</center></p>
</form>



