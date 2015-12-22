<master>


<%= [im_box_header "Comments"] %>


<form action=comment-pgdump-2>
<%= [export_vars -form {return_url filenames}] %>
<table>
<tr>
<td>Comment</td>
<td><input type=text name=comment width=40></td>
</tr>
<tr>
<td></td>
<td><input type=submit value="Add Comment"></td>
</tr>
</table>
</form>


<%= [im_box_footer] %>
