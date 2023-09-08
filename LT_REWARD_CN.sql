create or alter procedure LT_REWARD_CN (
    CN_N integer,
    DATE_BEGIN date,
    DATE_END date)
returns (
    RESULT numeric(15,2),
    INCEPT_REV numeric(15,2),
    ARMTZD_TO_POST_DATE_REV numeric(15,2))
as
declare variable CN_POSTING_DATE date;
declare variable CN_VAT_RATE numeric(15,2);
declare variable CN_TOTAL_REWARD numeric(15,2);
declare variable CN_TOTAL_REWARD_NET_VAT numeric(15,2);
declare variable CN_DPRC_PERIOD numeric(15,2);
declare variable CN_DAYLY_REWARD numeric(15,2);
declare variable DAYS_IN_REP_PER integer;
declare variable DAYS_FROM_INCEPTION_TO_POSTING integer;
declare variable CN_DATE_BEG date;
declare variable CN_DATE_END date;
begin
                        /* Procedure Text */

/* calculating applicable VAT rate */
select posting_date from ri_contract where n=:CN_N
    into :CN_POSTING_DATE;

     select VAT_RATE+1 from get_vat_rate(:CN_POSTING_DATE)
     into :CN_VAT_RATE;

/* calculating ultimate RUB reward under cover_note and passing  it to local variable CN_TOTAL_REWARD  */
/*select SUM(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus/((:CN_VAT_RATE)*10000))*/
select SUM(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus/10000)
FROM layer_cl_reins lcr
LEFT JOIN ri_layer  rl ON rl.n=lcr.n_ri_layer
LEFT JOIN accrual a ON a.n_ri_layer=rl.n
LEFT JOIN ri_contract cn ON cn.n=rl.n_ri_contract
where cn.n= :CN_N
into :CN_TOTAL_REWARD ;

CN_TOTAL_REWARD_NET_VAT=CN_TOTAL_REWARD/CN_VAT_RATE;

/* Calculating long term policy duration */
select cn.date_beg, cn.date_end
FROM ri_contract cn
where cn.n=:CN_N
into :CN_DATE_BEG, :CN_DATE_END;

CN_DPRC_PERIOD=CN_DATE_END-CN_DATE_BEG+1;

/* Calculating daily amortisation income under long term policy */
CN_DAYLY_REWARD=CN_TOTAL_REWARD_NET_VAT/CN_DPRC_PERIOD;

/* Calculating number of amortisation days during reporting period */
select
/*minvalue(cn.date_end+30-730, cast(:date_end as timestamp))-maxvalue(cn.date_beg+30, cast(:date_begin as timestamp))+1*/
minvalue(cn.date_end-730, cast(:date_end as timestamp))-maxvalue(cn.date_beg+30, cast(:date_begin as timestamp))+1
from ri_contract cn
where cn.n=:CN_N
into :DAYS_IN_REP_PER;
    /* if calculated number of depreciation days in period is less then zero we take zero to zero-out RESULT*/
    DAYS_IN_REP_PER=maxvalue(DAYS_IN_REP_PER, 0);

/* Calculating depreciation income applicable to reporting period */
RESULT= CN_DAYLY_REWARD*DAYS_IN_REP_PER;

/* Calculating long term SA revenue on inceprion */
INCEPT_REV=CN_DAYLY_REWARD*730;

/* If policy inception date is earlier then posting date calculating depreciation income for period {min(end of amrtz period ; :date_begin) - 'inception date'}}
value used when processing 2.1. lines. We take date_beg here as depreciation during reporting period will be calculated in ordinary manner for such lines
 */

if (
:CN_DATE_BEG < cast(:date_begin as timestamp)
) then
    begin

    DAYS_FROM_INCEPTION_TO_POSTING = minvalue(:CN_POSTING_DATE, :CN_DATE_END-700)-(:CN_DATE_BEG+30)+1;
    ARMTZD_TO_POST_DATE_REV = CN_DAYLY_REWARD*DAYS_FROM_INCEPTION_TO_POSTING;
    end

else
ARMTZD_TO_POST_DATE_REV =0;

suspend;
end