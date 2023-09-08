create or alter procedure LT_REWARD_SA (
    SA_N integer,
    DATE_BEGIN date,
    DATE_END date)
returns (
    RESULT numeric(15,2),
    INCEPT_REV numeric(15,2),
    ARMTZD_TO_POST_DATE_REV numeric(15,2))
as
declare variable SA_POSTING_DATE date;
declare variable SA_VAT_RATE numeric(15,2);
declare variable SA_TOTAL_REWARD numeric(15,2);
declare variable SA_TOTAL_REWARD_NET_VAT numeric(15,2);
declare variable SA_DPRC_PERIOD numeric(15,2);
declare variable SA_DAYLY_REWARD numeric(15,2);
declare variable DAYS_FROM_INCEPTION_TO_POSTING integer;
declare variable DAYS_IN_REP_PER integer;
declare variable SA_DATE_BEG date;
declare variable SA_DATE_END date;
begin
                        /* Procedure Text */

/* calculating applicable VAT rate */

select posting_date from serv_agreem where n=:SA_N
    into :SA_POSTING_DATE;

select VAT_RATE+1 from get_vat_rate(:SA_POSTING_DATE)
into :SA_VAT_RATE;

/* calculating ultimate RUB reward under servicing agreement and passing  it to local variable SA_TOTAL_REWARD */
select sum(fp.payment_amount)
from fee_payment fp
left join serv_agreem sa on sa.n=fp.n_serv_agreem
where fp.n_serv_agreem= :sa_n
into :SA_TOTAL_REWARD;

SA_TOTAL_REWARD_NET_VAT=SA_TOTAL_REWARD/SA_VAT_RATE;

/* Calculating long term policy duration */
select sa.date_beg, sa.date_end
FROM serv_agreem sa
where sa.n=:sa_n 
into :SA_DATE_BEG, :SA_DATE_END;

SA_DPRC_PERIOD=SA_DATE_END-SA_DATE_BEG+1;

/* Calculating daily amortisation income under long term service agreement */
SA_DAYLY_REWARD=SA_TOTAL_REWARD_NET_VAT/SA_DPRC_PERIOD;

/* Calculating number of amortisation days during reporting period */
            select
            /*minvalue(sa.date_end+30-730, cast(:date_end as timestamp))-maxvalue(sa.date_beg+30, cast(:date_begin as timestamp))+1*/
            minvalue(sa.date_end-730, cast(:date_end as timestamp))-maxvalue(sa.date_beg+30, cast(:date_begin as timestamp))+1
            from serv_agreem sa
            where sa.n=:SA_N
            into :DAYS_IN_REP_PER;
    /* if calculated number of depreciation days in period is less then zero we take zero to zero-out RESULT*/
    DAYS_IN_REP_PER=maxvalue(DAYS_IN_REP_PER, 0);

/* Calculating depreciation income applicable to reporting period */
RESULT= SA_DAYLY_REWARD*DAYS_IN_REP_PER;

/* Calculating long term SA revenue on inceprion */
INCEPT_REV=SA_DAYLY_REWARD*730;

/* If policy inception date is earlier then posting date calculating depreciation income for period {min(end of amrtz period ; :date_begin) - 'inception date'}}
value used when processing 2.1. lines. We take date_beg here as depreciation during reporting period will be calculated in ordinary manner for such lines
 */

if (
:SA_DATE_BEG < cast(:date_begin as timestamp)
) then
    begin


    DAYS_FROM_INCEPTION_TO_POSTING = minvalue(:SA_POSTING_DATE, :SA_DATE_END-700)-(:SA_DATE_BEG+30)+1;
    ARMTZD_TO_POST_DATE_REV = SA_DAYLY_REWARD*DAYS_FROM_INCEPTION_TO_POSTING;
    end

else
ARMTZD_TO_POST_DATE_REV =0;

suspend;
end