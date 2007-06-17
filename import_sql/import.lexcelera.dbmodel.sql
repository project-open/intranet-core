
alter table im_offices add lxc_office_id integer;

alter table persons add lxc_user_id integer;




insert into im_categories(category_id, category, category_type) values (11500, 'Address', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) values (11502, 'Email', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) values (11504, 'Http', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) values (11506, 'Ftp', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) values (11508, 'Phone', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) values (11510, 'Fax', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) values (11512, 'Mobile', 'Intranet Notes Type');
insert into im_categories(category_id, category, category_type) values (11514, 'Other', 'Intranet Notes Type');

insert into im_categories(category_id, aux_int1, category, category_type) values (11515, 21, 'Work', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11516, 25, 'Home', 'Intranet Notes Type');



-- Map ]po[ categories to LXC categories
update im_categories set aux_int1 = 31 where category_id = 11502;
update im_categories set aux_int1 = 32 where category_id = 11504;
update im_categories set aux_int1 = 33 where category_id = 11506;
update im_categories set aux_int1 = 23 where category_id = 11510;
update im_categories set aux_int1 = 22 where category_id = 11512;
update im_categories set aux_int1 = 26 where category_id = 11514;



insert into im_categories(category_id, aux_int1, category, category_type) values (11520, 0, 'none', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11522, 1, 'Action', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11524, 2, 'General', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11526, 3, 'Billing', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11528, 4, 'Translation', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11530, 7, 'Deactivation', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11532, 8, 'Problem', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11534, 9, 'Solution', 'Intranet Notes Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (11536, 10, 'Contacts', 'Intranet Notes Type');







insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 0, '<none>', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 1, 'Aerospace', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 2, 'Automotive', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 3, 'Business Services', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 4, 'Communications', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 5, 'Construction & Engineering', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 6, 'Consumer Goods', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 7, 'Culture, Sports & Tourism', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 8, 'Energy & Environment', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 9, 'Entertainment & Media', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 10, 'Exhibitions', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 11, 'Financial Services', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 12, 'Food Industry', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 13, 'Government', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 14, 'Human Resources / Training', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 15, 'Humanitarian', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 16, 'Information Technology', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 17, 'Legal', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 18, 'Life Sciences', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 19, 'Luxury Goods', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 20, 'Manufacturing / Distribution', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 21, 'Patents', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 22, 'Sciences', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 23, 'Telecommunications', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 24, 'Transportation & Logistics', 'Intranet Company Sector');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 25, 'Translation Agencies', 'Intranet Company Sector');



insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 0, 'none', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 1, 'Client referral', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 2, 'Contact move', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 3, 'Personal contact', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 4, 'Current or former employee', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 5, 'Translator referral', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 6, 'Mailing', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 7, 'Internet yellow pages', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 8, 'Yellow pages', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 9, 'Minitel', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 10, 'Eurotexte web site', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 11, 'New division of existing client', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 12, 'unknown', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 13, 'Colleague', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 14, 'Quick Quote', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 15, 'Eulogia', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 16, 'Initiative', 'Intranet Company Referral Type');
insert into im_categories(category_id, aux_int1, category, category_type) values (nextval('im_categories_seq'), 17, 'Sales call', 'Intranet Company Referral Type');









-- Companies
drop table "tblCompAcct";
drop table "tblCompAcctAdd";
drop table "tblCompAcctContComp";
drop table "tblCompAcct_MatUserID";
drop table "tblCompAdd";
drop table "tblCompAdd_ForCompAcctIDOnly";

drop table "tblCompGlossary";

drop table "tblCompMaster" cascade;
drop table "tblCompMaster_CompNm";
drop table "tblCompNote";
drop table "tblCompNote_ActionTypeID";
drop table "tblCompPhon";
drop table "tblCompProjMgr";
drop table "tblCompRate";
drop table "tblCompRate_ServiceID_key";
drop table "tblCompRefFile";
drop table "tblCompTran";
drop table "tblCompTranService";
drop sequence "tblCompTranService_CompTranServiceID_seq";
drop table "tblCompTranSpec";

drop table "tblCompWeb";

drop table "lktblCompSector";
drop table "lktblCompSectorNm";
drop table "lktblCompSource";
drop table "lktblCompType";

-- Cont (??)
drop table "tblContComp";
drop table "tblContCompNote";
drop table "tblContCompPhon";
drop table "tblContCompWeb";
drop table "tblContMaster" cascade;
drop table "tblContMaster_ContNm";




-- Bills
drop table "tblBillLineItem";
drop table "tblBillLineItem_BillNum";
drop table "tblBillMaster" cascade;
drop table "lktblBillRate";
drop table "lktblBillRateNm";
drop table "lktblBillType";
drop table "lktblBillTypeNm";


-- Quotes
drop table "tblDevisDelivery";
drop sequence "tblDevisDelivery_DevisDeliveryID_seq";
drop table "tblDevisFile";
drop table "tblDevisFile_LangID";
drop table "tblDevisFile_SourceTarget";
drop table "tblDevisLineItemArchive";
drop table "tblDevisLineItemArchive_JobTypeRateID";
drop table "tblDevisMaster" cascade;
drop table "tblDevisRate";
drop table "tblDevisRate_PhaseNum";
drop table "tblDevisRate_SortKey";
drop table "tblDevisStockPhrase";

-- Job
drop table "tblJobAssignment";
drop table "tblJobCancel";
drop table "tblJobCancel_JobNum";
drop table "tblJobCredit";
drop table "tblJobCredit_BillNum";
drop table "tblJobCredit_PayMethID";
drop table "tblJobDelivery";
drop table "tblJobFile";
drop table "tblJobFileCATCalc";
drop table "tblJobFileFolder";
drop table "tblJobFileFolder_ParentFolderID";
drop table "tblJobFileFolder_SourceFileID";
drop table "tblJobFileSpec";
drop table "tblJobFile_SourceFileID";
drop table "tblJobFile_TargetPhaseNum";
drop table "tblJobLang";
drop table "tblJobLang_JobID_key";
drop table "tblJobMaster";
drop table "tblJobMaster_CompContID";
drop table "tblJobMaster_DevisNum";
drop table "tblJobMaster_JobNum";
drop table "tblJobMaster_NumDisplay";
drop table "tblJobMaster_NumDisplay_NumDisplay_key";
drop table "tblJobNote";
drop table "tblJobNote_ActionTypeID";
drop table "tblJobPhase";
drop table "tblJobRate";
drop table "tblJobRate_PercRateID";
drop table "tblJobRate_PhaseServiceID";
drop table "tblJobRate_tblJobRateCompRateID";
drop table "tblJobRefFile";
drop table "tblJobService";
drop table "tblJobService_PhaseNumServiceID";
drop table "tblJobTranslation";
drop table "lktblJobPhaseState";
drop table "lktblJobState";

-- Translator
drop table "tblTranAdd";
drop table "tblTranBill";
drop table "tblTranBillLineItem";
drop table "tblTranBill_TranBillNum";
drop table "tblTranEvaluation";
drop table "tblTranFileType";
drop table "tblTranHardware";
drop table "tblTranLang";
drop table "tblTranMaster";
drop table "tblTranMaster_TranNm";
drop table "tblTranNote";
drop table "tblTranPhon";
drop table "tblTranPhon_CountryID";
drop table "tblTranRate";
drop table "tblTranReview";
drop table "tblTranReviewEvaluation";
drop table "tblTranService";
drop table "tblTranSpec";
drop table "tblTranWeb";

-- Internal User
drop table "tblUsers";


drop table "lktblCATMatchType";
drop table "lktblChain";
drop table "lktblChainPhase";
drop table "lktblChainService";
drop table "lktblClassification";

drop table "lktblCoordType";

drop table "lktblCountry";
drop table "lktblCountryNm";
drop table "lktblCountry_CountryNmDisplay_key";

drop table "lktblCurrency";

drop table "lktblDeactivateReason";
drop table "lktblDeliveryType";
drop table "lktblDeliveryTypeNm";
drop table "lktblDiscountReason";
drop table "lktblDiscountReasonNm";

drop table "lktblDocType";
drop table "lktblDocTypeNm";

drop table "lktblFileType";
drop table "lktblFileTypeGrp";
drop table "lktblFileTypeVersion";
drop table "lktblFileWareType";
drop table "lktblFileWareType_WareTypeID";

drop table "lktblHardware";
drop table "lktblHardwareGrp";
drop table "lktblHardwareVersion";


drop table "lktblLang";
drop table "lktblLangExpansionRate";
drop table "lktblLangGrp";
drop table "lktblLangGrpNm";
drop table "lktblLangNm";
drop table "lktblLangRate";
drop table "lktblLangRate_DteFrom";
drop table "lktblLang_FileNmTag_key";
drop table "lktblMail";
drop table "lktblMailType";
drop table "lktblMatMnth";
drop table "lktblMergeType";
drop table "lktblMnth";
drop table "lktblMnthNm";
drop table "lktblNoteType";
drop table "lktblPayMethod";
drop table "lktblPayMethodNm";
drop table "lktblPriority";
drop table "lktblRateScheme";
drop table "lktblRateType";
drop table "lktblRateTypeNm";
drop table "lktblRefuse";
drop table "lktblRequiredBy";
drop table "lktblRib";
drop table "lktblRibNm";
drop table "lktblRptYr";
drop table "lktblServGrp";
drop table "lktblServGrpNm";
drop table "lktblService";
drop table "lktblServiceDisplayType";
drop table "lktblServiceNm";
drop table "lktblServiceRate";
drop table "lktblServiceRate_DteFrom";
drop table "lktblServiceRate_DteTo";
drop table "lktblSpec";
drop table "lktblSpecExpansionRate";
drop table "lktblSpecGrp";
drop table "lktblSpecGrpNm";
drop table "lktblSpecGrp_SpecGrpID";
drop table "lktblSpecNm";
drop table "lktblStockPhrase";
drop table "lktblStockPhraseText";
drop table "lktblStockPhrase_StockPhraseRank";
drop table "lktblTimeZone";
drop table "lktblTimeZone_MapTimeZoneID";
drop table "lktblTitleOfAddress";
drop table "lktblTitleOfAddressNm";
drop table "lktblTranEvaluation";
drop table "lktblTranRating";
drop table "lktblTranRatingEvaluation";
drop table "lktblVATRate";
drop table "lktblWeekday";
drop table "lktblWeekdayNm";
drop table "lktblZipCode";


