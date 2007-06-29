---------------------------------------------------------------------------------
-- tblTransFreelanceSkills
---------------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
DECLARE
        row			RECORD;
	v_count			integer;
	v_user_id		integer;
	v_subject_area_id	integer;
	v_experience_id		integer;
	v_language_id		integer;
	v_lang_skill_type_id	integer;
BEGIN
    for row in
	select	*
	from	"tblTransFreelanceSkills" s
    loop
	select	person_id into v_user_id
	from	persons
	where	first_names = row."FirstNm"
		and last_name = row."LastNm";

	select	category_id into v_subject_area_id
	from	im_categories
	where	category_type = ''Intranet Translation Subject Area''
		and category = row."SpecNm";

	select	category_id into v_experience_id
	from	im_categories
	where	category_type = ''Intranet Experience Level''
		and aux_string1 = row."Rating";

	select	category_id into v_language_id
	from	im_categories
	where	category_type = ''Intranet Translation Language''
		and aux_string1 = row."LangNmDisplay";

	IF row."IsTarget" THEN v_lang_skill_type_id := 2002; END IF;
	IF NOT row."IsTarget" THEN v_lang_skill_type_id := 2000; END IF;

	RAISE NOTICE ''Skills: pid=%, subj=%, lang=%, lang=%, level=%, fn=%, ln=%'', 
	v_user_id, v_subject_area_id, v_language_id, row."LangNmDisplay", 
	v_experience_id, row."FirstNm", row."LastNm";

	update im_freelancers
	set rec_status_id = 10000019
	where user_id = v_user_id;

	-- ---------------------------------------------------------
	-- Add Subject Area Skills
	select count(*) into v_count
	from	im_freelance_skills
	where	user_id = v_user_id
		and skill_id = v_subject_area_id
		and skill_type_id = 2014;

	IF 0 = v_count AND v_user_id is not null AND v_subject_area_id is not null THEN
	    RAISE NOTICE ''Insert Skills: pid=%, subj=%, level=%'', 
	    v_user_id, v_subject_area_id, v_experience_id;

	    insert into im_freelance_skills (
		user_id,
		skill_id,
		skill_type_id,
		claimed_experience_id,
		confirmed_experience_id,
		confirmation_user_id,
		confirmation_date
	    ) values (
		v_user_id,
		v_subject_area_id,
		2014,
		v_experience_id,
		v_experience_id,
		624,
		now()
	    );
	END IF;

	-- ---------------------------------------------------------
	-- Source or Target Language
	select count(*) into v_count
	from	im_freelance_skills
	where	user_id = v_user_id
		and skill_id = v_language_id
		and skill_type_id = v_lang_skill_type_id;

	IF 0 = v_count AND v_user_id is not null AND v_subject_area_id is not null THEN
	    RAISE NOTICE ''Insert Skills: pid=%, subj=%, level=%'', 
	    v_user_id, v_subject_area_id, v_experience_id;

	    insert into im_freelance_skills (
		user_id,
		skill_id,
		skill_type_id,
		claimed_experience_id,
		confirmed_experience_id,
		confirmation_user_id,
		confirmation_date
	    ) values (
		v_user_id,
		v_language_id,
		v_lang_skill_type_id,
		v_experience_id,
		v_experience_id,
		624,
		now()
	    );
	END IF;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


