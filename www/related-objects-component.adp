<if @show_master_p@>
<master src="/packages/intranet-core/www/master">
</if>

<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
window.addEventListener('load', function() { 
     document.getElementById('list_check_all').addEventListener('click', function() { acs_ListCheckAll('rels_list', this.checked) });
});
</script>


<listtemplate name="rels"></listtemplate>
@show_more_url;noquote@
