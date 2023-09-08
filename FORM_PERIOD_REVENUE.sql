create or alter procedure FORM_PERIOD_REVENUE (
    DATE_BEGIN date,
    DATE_END date,
    N_YEAR integer,
    N_MONTH integer)
as
declare variable STP_MYP varchar(3);
declare variable CLIENT_GROUP varchar(100);
declare variable REWARD_BEG date;
declare variable REWARD_END date;
declare variable REWARD_TYPE varchar(3);
declare variable N_PAYER integer;
declare variable ACC_EXECUTIVE varchar(100);
declare variable STATUS integer;
declare variable LOB varchar(100);
declare variable PRODUCT varchar(150);
declare variable N_SOURCE integer;
declare variable IS_NEW varchar(1);
declare variable IS_RECURRING varchar(1);
declare variable DEP varchar(20);
declare variable NOM_GR_ONE_C_CODE varchar(20);
declare variable EFFECTIVE_DATE date;
declare variable EXPIRY_DATE date;
declare variable COST_REWARD numeric(15,2);
declare variable CURR varchar(20);
declare variable TOT_REV_CUR_NET_VAT numeric(15,2);
declare variable COST_REWARD_ORIG_CUR numeric(15,2);
declare variable DFRD_REV_ON_INCEPT numeric(15,2);
declare variable PER_AMRTZD_REV numeric(15,2);
declare variable N_CURR integer;
declare variable PODR_N integer;
declare variable REF_CERT varchar(100);
declare variable REPORTING_DATE date;
declare variable N_CURRENT integer;
begin
  /* Procedure Text */
  select date_end from period where n_year=:n_year and n_month=:n_month into :reporting_date;
  for select STP_MYP,CLIENT_GROUP,REWARD_BEG,REWARD_END,REWARD_TYPE,N_PAYER,ACC_EXECUTIVE,STATUS,LOB,PRODUCT,
             N_SOURCE,IS_NEW,IS_RECURRING,DEP,NOM_GR_ONE_C_CODE,EFFECTIVE_DATE,EXPIRY_DATE,COST_REWARD,CURR,
             TOT_REV_CUR_NET_VAT,COST_REWARD_ORIG_CUR,DFRD_REV_ON_INCEPT,PER_AMRTZD_REV,N_CURR,PODR_N,REF_CERT
             from QUERY_STP (:DATE_BEGIN,:DATE_END,0,0)
      union all
      select STP_MYP,CLIENT_GROUP,REWARD_BEG,REWARD_END,REWARD_TYPE,N_PAYER,ACC_EXECUTIVE,STATUS,LOB,PRODUCT,
             N_SOURCE,IS_NEW,IS_RECURRING,DEP,NOM_GR_ONE_C_CODE,EFFECTIVE_DATE,EXPIRY_DATE,COST_REWARD,CURR,
             TOT_REV_CUR_NET_VAT,COST_REWARD_ORIG_CUR,DFRD_REV_ON_INCEPT,PER_AMRTZD_REV,N_CURR,PODR_N,REF_CERT
             from QUERY_MYP (:DATE_BEGIN,:DATE_END,0,0)
      into :STP_MYP,:CLIENT_GROUP,:REWARD_BEG,:REWARD_END,:REWARD_TYPE,:N_PAYER,:ACC_EXECUTIVE,:STATUS,:LOB,:PRODUCT,
           :N_SOURCE,:IS_NEW,:IS_RECURRING,:DEP,:NOM_GR_ONE_C_CODE,:EFFECTIVE_DATE,:EXPIRY_DATE,:COST_REWARD,:CURR,
           :TOT_REV_CUR_NET_VAT,:COST_REWARD_ORIG_CUR,:DFRD_REV_ON_INCEPT,:PER_AMRTZD_REV,:N_CURR,:PODR_N,:REF_CERT
  do
    begin
      insert into period_revenue
                 (n,STP_MYP,CLIENT_GROUP,REWARD_BEG,REWARD_END,REWARD_TYPE,N_PAYER,ACC_EXECUTIVE,STATUS,LOB,
                  PRODUCT,N_SOURCE,IS_NEW,IS_RECURRING,DEP,NOM_GR_ONE_C_CODE,EFFECTIVE_DATE,EXPIRY_DATE,
                  COST_REWARD,CURR,N_YEAR,N_MONTH,REPORTING_DATE,DATE_CREATE,COST_REWARD_CURR,TOT_REV_CUR_NET_VAT)
             values
                 (GEN_ID(N_PERIOD_REVENUE,1),
                  :STP_MYP,:CLIENT_GROUP,:REWARD_BEG,:REWARD_END,:REWARD_TYPE,:N_PAYER,:ACC_EXECUTIVE,:STATUS,:LOB,
                  :PRODUCT,:N_SOURCE,:IS_NEW,:IS_RECURRING,:DEP,:NOM_GR_ONE_C_CODE,:EFFECTIVE_DATE,:EXPIRY_DATE,
                  :COST_REWARD,:CURR,:N_YEAR,:N_MONTH,:REPORTING_DATE,'NOW',:COST_REWARD_ORIG_CUR,:TOT_REV_CUR_NET_VAT);
    end

end