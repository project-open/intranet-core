  <master>
    <property name="title">@page_title;noquote@</property>
    <property name="context">@context;noquote@</property>

    Search for <b><code>@pattern@</code></b>:

    <if @matches:rowcount@ not nil and @matches:rowcount@ gt 0>
      @matches:rowcount@ matches found.<p></p>

      <if @full@ eq "f">
	Only the first 200 chars of key and value are shown.
	<a href="show-util-memoize?full=t&pattern=@pattern@">View
	  full results.</a>
      </if>
      <else>
	Full strings for key and value shown.
	<a href="show-util-memoize?full=f&pattern=@pattern@">View
	  short results.</a>
      </else>
      <table border="0" cellpadding="5" cellspacing="1">
	<tr bgcolor="#eeeeee">
	  <th>Key</th>
	  <th>Value</th>
	  <th>Date</th>
	  <th>Size</th>
	</tr>

	<multiple name="matches">
	    <if @matches.rownum@ odd>
	    	<tr class=rowodd>
	    </if>
	    <else>
	    	<tr class=roweven>
	    </else>
	      <td>@matches.key@</td>
	      <td>@matches.value@</td>
	      <td>@matches.date@</td>
	      <td>@matches.value_size@</td>
	    </tr>
	</multiple>

	</table>
	<p><!--
	<a href="flush?type=all&pattern=@pattern@">Flush all of these
	from the cache</a>-->
    </if>
    <else>
      <i>no matches found</i>
    </else>

