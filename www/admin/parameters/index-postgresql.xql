<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="packages">
	<querytext>
select
        p.package_id,
        p.package_key,
	m.description,
        p.instance_name,
        v.attr_value,
        m.parameter_name
from
        apm_packages p,
        apm_parameters m left outer join apm_parameter_values v
        on (m.parameter_id = v.parameter_id)
where
        p.package_key = m.package_key
order by
        p.package_key

	</querytext>
</fullquery>

</queryset>
