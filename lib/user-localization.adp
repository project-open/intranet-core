<form method=POST action=edit-locale>
<input type="hidden" name="user_id" value="@user_id@">

<table cellpadding=1 cellspacing=1 border=0>
  <tr>
    <td colspan=2 class=rowtitle align=center>#intranet-core.Localization#</td>
  </tr>
  <tr class=rowodd>
    <td>#intranet-core.Your_Current_Locale#</td>
    <td>@site_wide_locale;noquote@</td>
  </tr>
  <tr class=roweven>
    <td>#intranet-core.Your_Current_Timezone#</td>
    <td>@timezone;noquote@</td>
  </tr>
  <tr>
    <td colspan=99 align=right>
      <input type="submit" value="#intranet-core.Edit#">
    </td>
  </tr>
</table>
</form>

