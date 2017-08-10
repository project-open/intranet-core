<master>

<h1>@page_title@</h1>

<h2>Index Pages</h2>
<table border=0>
<tr class=rowtitle>
<td class=rowtitle align=center>Page</td>
<td class=rowtitle align=center>Status</td>
</tr>
<%= [join $index_lines "\n"] %>
</table>


<h2>All Pages</h2>
<table border=0>
<tr class=rowtitle>
<td class=rowtitle align=center>Page</td>
<td class=rowtitle align=center>Status</td>
</tr>
<%= [join $all_lines "\n"] %>
</table>