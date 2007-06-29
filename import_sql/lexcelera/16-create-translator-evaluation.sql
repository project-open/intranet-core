---------------------------------------------------------------------------------
-- tblTranEvaluation - Notes for companies
---------------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_company_id		integer;
	v_topic_id		integer;
	v_note_text		text;
	v_subject		text;
	v_person_id		integer;
BEGIN
    for row in
        select	*
	from	"tblTranEvaluation" e,
		"lktblTranEvaluation" v,
		"tblTranMaster" m
	where
		e."EvaluationID" = v."EvaluationID"
		and e."TranID" = m."TranID"
    loop
	select	company_id into v_company_id
	from	im_companies where lxc_company_id = row."TranID";

	select	person_id into v_person_id
	from	persons where lxc_user_id = row."MatUserID";
	IF v_person_id is NULL THEN v_person_id = 624; END IF;

	v_note_text := row."EvaluationNm" || '' '' || row."Rating"::varchar;

	select	topic_id into v_topic_id
	from	im_forum_topics
	where	object_id = v_company_id
		and message = v_note_text;

	RAISE NOTICE ''Note: tid=%, cid=%, fn=%, ln=%, note=%'', 
	row."TranID", v_company_id, row."FirstNm", row."LastNm", v_note_text;

	IF v_company_id is not null AND v_topic_id is NULL THEN
	    insert into im_forum_topics (
		topic_id, object_id,
		topic_type_id, topic_status_id,
		posting_date,
		owner_id,
		scope,
		subject,
		message
	    ) values (
		nextval(''im_forum_topics_seq''), v_company_id,
		1108, 1200,
		row."MatDte"::date,
		v_person_id,
		''group'',
		substring(v_note_text for 60),
		v_note_text
	    );
	END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


