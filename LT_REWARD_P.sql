create or alter procedure LT_REWARD_P (
    P_N integer,
    DATE_BEGIN date,
    DATE_END date)
returns (
    RESULT numeric(15,2),
    INCEPT_REV numeric(15,2),
    ARMTZD_TO_POST_DATE_REV numeric(15,2))
as
declare variable P_POSTING_DATE date;
declare variable P_VAT_RATE numeric(15,2);
declare variable P_TOTAL_REWARD numeric(15,2);
declare variable P_TOTAL_REWARD_NET_VAT numeric(15,2);
declare variable P_DPRC_PERIOD numeric(15,2);
declare variable P_DAYLY_REWARD numeric(15,2);
declare variable DAYS_FROM_INCEPTION_TO_POSTING integer;
declare variable DAYS_IN_REP_PER integer;
declare variable P_DATE_BEG date;
declare variable P_DATE_END date;
begin
                                                    /* Procedure Text */
    /* calculating applicable VAT rate */

    select posting_date from policy_stas where n=:P_N
    into :P_POSTING_DATE;

    select VAT_RATE+1 from get_vat_rate(:P_POSTING_DATE)
into :P_VAT_RATE;

    /* calculating ultimate RUB reward under policy and passing  it to local variable P_TOTAL_REWARD  */
select (sum(pp.payment_amount*pp.brok_rate/100))
from policy_payment pp
left join policy_stas p on p.n=pp.n_policy_stas
where pp.n_policy_stas= :P_N
-- added on 20220830
and pp.is_reject_pmnt = 'F'
into :P_TOTAL_REWARD ;

P_TOTAL_REWARD_NET_VAT=P_TOTAL_REWARD/P_VAT_RATE;

    /* Calculating long term policy depreciation period */
select p.icept_date, p.exp_date
FROM policy_stas p
where p.n=:P_N
into :P_DATE_BEG, P_DATE_END;

P_DPRC_PERIOD = P_DATE_END-P_DATE_BEG+1;

    /* Calculating daily amortisation income under long term policy */
P_DAYLY_REWARD=P_TOTAL_REWARD_NET_VAT/P_DPRC_PERIOD;

    /* Calculating number of amortisation days during reporting period for 2.2. lines*/
select
/**minvalue(p.exp_date+30-730, cast(:date_end as timestamp))-maxvalue(p.icept_date+30, cast(:date_begin as timestamp))+1*/
minvalue(p.exp_date-730, cast(:date_end as timestamp))-maxvalue(p.icept_date+30, cast(:date_begin as timestamp))+1
from policy_stas p
where p.n=:P_N
into :DAYS_IN_REP_PER;

    /* if calculated number of depreciation days in period is less then zero we take zero to zero-out RESULT*/
DAYS_IN_REP_PER=maxvalue(DAYS_IN_REP_PER, 0);

    /* Calculating depreciation income applicable to reporting period */
RESULT= P_DAYLY_REWARD*DAYS_IN_REP_PER;

    /* Calculating long term policy revenue on inceprion */
INCEPT_REV=P_DAYLY_REWARD*730;

    /* If policy inception date is earlier then posting date calculating depreciation income for period {min(end of amrtz period ; :date_begin) - 'inception date'}}
    value used when processing 2.1. lines. We take date_beg here as depreciation during reporting period will be calculated in ordinary manner for such lines
     */

if (
:P_DATE_BEG < cast(:date_begin as timestamp)
) then
    begin

    DAYS_FROM_INCEPTION_TO_POSTING = minvalue(:P_POSTING_DATE, :P_DATE_END-700)-(:P_DATE_BEG+30)+1;
    ARMTZD_TO_POST_DATE_REV = P_DAYLY_REWARD*DAYS_FROM_INCEPTION_TO_POSTING;
    end

else
ARMTZD_TO_POST_DATE_REV =0;

suspend;
end