# /www/admin/categories/tree.tcl
ad_page_contract {

  Presents the contents of the categories and the category_hierarchy table
  as a tree.

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id tree.tcl,v 3.3.2.4 2000/09/22 01:34:28 kevin Exp
} {

}


set category_tree ""

db_foreach category_hierarchy_tree "
SELECT
  c.category_id,
  c.category,
  c.category_type,
  c.profiling_weight,
  c.enabled_p,
  cat_tree.rownum_col,
  cat_tree.level_col,
  COUNT(ui.user_id) AS n_interested_users
FROM
  users_interests ui,
  categories c,
    (SELECT h.child_category_id, ROWNUM as rownum_col, LEVEL AS level_col
     FROM category_hierarchy h
     START WITH h.parent_category_id IS NULL
     CONNECT BY PRIOR h.child_category_id = h.parent_category_id) cat_tree
WHERE
  c.category_id = cat_tree.child_category_id
  AND c.category_id = ui.category_id (+)
GROUP BY
  c.category_id,
  c.category,
  c.category_type,
  c.profiling_weight,
  c.enabled_p,
  cat_tree.rownum_col,
  cat_tree.level_col
ORDER BY
  cat_tree.rownum_col" {

    #  We want to form a string consisting of $level_col "&nbsp;"s.
    #  Or two times $level_col.
    regsub -all . [format %*s [expr $level_col - 1] {}] {\&nbsp; \&nbsp; } indent
    append category_tree "
<tr>
<td>$indent <a href=\"one?[export_url_vars category_id]\">$category</a></td>
<td>$category_type</td>
<td align=center>$profiling_weight</td>
<td align=center>$enabled_p</td>
<td align=center>[expr {$n_interested_users > 0 ? "<a href=\"/admin/users/action-choose?[export_url_vars category_id]\">$n_interested_users</a>\n" : 0}] </td>
</tr>
"
}



doc_return  200 text/html "[ad_admin_header "Content Categories Tree"]

<h2>Content Categories Tree</h2>

[ad_admin_context_bar [list index "Categories"] "Category tree"]

<hr>

<table>
<tr>
<th>Category</th>
<th>Type</th>
<th>Weight</th>
<th>Enabled</th>
<th># of Interested Users</th>
</tr>

$category_tree

</table>

<ul>
<li><a href=\"category-add\">Add a category</a>
</ul>
[ad_admin_footer]
"
