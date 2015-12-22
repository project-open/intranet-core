<master>


<%= [im_box_header "Comments"] %>


<form action=comment-pgdump-2>
<%= [export_vars -form {return_url filenames}] %>
<table>
<tr>
<td>Comment</td>
<td><textarea name=comment rows=5 cols=80></textarea></td>
</tr>
<tr>
<td></td>
<td><input type=submit value="Add Comment"></td>
</tr>
</table>
</form>


<%= [im_box_footer] %>
