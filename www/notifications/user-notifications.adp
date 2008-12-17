<if @user_id@ eq @current_user_id@>
<if @notifications:rowcount@ ne 0>

<table cellspacing="1" cellpadding="3">
  <multiple name="notifications">
    <if @notifications.rownum@ odd>
      <tr class="bt_listing_odd">
    </if>
    <else>
      <tr class="bt_listing_even">
    </else>
      <td align="center" class="bt_listing_narrow">
        <if @notifications.subscribed_p@ true>
          <b>&raquo;</b>
        </if>
        <else>
          &nbsp;
        </else>
      </td>
      <td class="bt_listing">
        @notifications.label@
      </td>
      <td class="bt_listing">
        <if @notifications.subscribed_p@ false>
          <a href="@notifications.url@" title="@notifications.title@">Subscribe</a>
        </if>
	<else>
          <a href="@notifications.url@" title="@notifications.title@">Unsubscribe</a>
	</else>
      </td>
    </tr>
  </multiple>
</table>
</if>
</if>
