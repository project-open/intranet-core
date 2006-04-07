<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-trans-invoices/www/companies/new-company-from-freelance-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-21 -->
<!-- @arch-tag 8bcf633c-acde-47d0-a846-d6967fdaf1b7 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="freelancer_info">
    <querytext>

select
	u.*,
	c.*,
	pe.*,
	pa.*
from
	users u
      LEFT JOIN
	persons pe ON u.user_id = pe.person_id
      LEFT JOIN
	parties pa ON u.user_id = pa.party_id
      LEFT JOIN
	users_contact c USING (user_id)
      LEFT JOIN
        country_codes ha_cc ON c.ha_country_code = ha_cc.iso
      LEFT JOIN
        country_codes wa_cc ON c.wa_country_code = wa_cc.iso
where
	u.user_id = :freelance_id

    </querytext>
  </fullquery>


</queryset>
