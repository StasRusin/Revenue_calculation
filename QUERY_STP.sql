create or alter procedure QUERY_STP (
    DATE_BEGIN date,
    DATE_END date,
    N_GLC_GROUP integer,
    N_PODR integer)
returns (
    STP_MYP varchar(3),
    CLIENT_GROUP varchar(100),
    REWARD_BEG date,
    REWARD_END date,
    REWARD_TYPE varchar(3),
    N_PAYER integer,
    ACC_EXECUTIVE varchar(100),
    STATUS integer,
    LOB varchar(100),
    PRODUCT varchar(150),
    N_SOURCE integer,
    IS_NEW varchar(1),
    IS_RECURRING varchar(1),
    DEP varchar(20),
    NOM_GR_ONE_C_CODE varchar(20),
    EFFECTIVE_DATE date,
    EXPIRY_DATE date,
    COST_REWARD numeric(15,2),
    CURR varchar(20),
    TOT_REV_CUR_NET_VAT numeric(15,2),
    COST_REWARD_ORIG_CUR numeric(15,2),
    DFRD_REV_ON_INCEPT numeric(15,2),
    PER_AMRTZD_REV numeric(15,2),
    N_CURR integer,
    PODR_N integer,
    REF_CERT varchar(100))
as
begin
/* Procedure is run in 10 steps (3*3 + 1) DBC/FEE/Re times short term + long term + DBC policy cancelations*/
for
/* Filling PERIOD_REVENUE.COST_REWARD for DBC short term */
SELECT
"1.1" as STP_MYP,
GLC.name AS CLIENT_GROUP,
p.icept_date as REWARD_BEG,
p.icept_date as REWARD_END,
"DBC" AS Reward_Type,
p.n_client2 as N_PAYER,
br.name AS ACC_EXECUTIVE,
p.n_policy_status AS STATUS,
lob.name AS LOB,
prod.name as PRODUCT,
p.n as N_SOURCE,
p.is_new_renew as IS_NEW,
p.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
p.icept_date as EFFECTIVE_DATE,
p.exp_date as EXPIRY_DATE,
SUM((SELECT res FROM recounttorur(pp.payment_amount*pp.brok_rate/120, p.n_curr1, p.icept_date))) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(pp.brok_rate*pp.payment_amount/120) as TOTAL_REV_ORIG_CUR_NET_VAT,
SUM(pp.brok_rate*pp.payment_amount/120) as COST_REWARD_ORIG_CUR,
0 as DFRD_REV_ON_INCEPT,
0 as PER_AMRTZD_REV,
p.n_curr1 as N_CURR,
podr.n as PODR_N,
p.policy_number as REF_CERT

FROM policy_stas p

LEFT JOIN client cl ON cl.n=p.n_client1
LEFT JOIN glc_group glc ON cl.n_glc_group=glc.n
LEFT JOIN policy_payment pp ON pp.n_policy_stas=p.n
LEFT JOIN client br ON br.n=p.n_client3
LEFT JOIN lob ON lob.n=p.n_lob
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=p.n_product
left join NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.type_reward = 'DBC' and ng.n_legal_entity=1)
left join curr on curr.n = p.n_curr1


WHERE
p.posting_date>=:date_begin AND
p.posting_date<=:date_end AND
p.n_fee_comm IN (2,3)  AND
p.exp_date-p.icept_date<=730   and
(p.is_rejected='F' or p.is_rejected is null or (p.is_rejected='T' and p.reject_posting_date>:date_end)) and
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)
-- added on 20220826
and pp.is_reject_pmnt = 'F'

GROUP BY STP_MYP, CLIENT_GROUP, Reward_Type, REWARD_BEG, REWARD_END, N_PAYER, ACC_EXECUTIVE, STATUS,
LOB, PRODUCT, N_SOURCE, IS_NEW, is_recurring, DEP, NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, CURR, N_CURR, PODR_N, REF_CERT

union
/* Filling PERIOD_REVENUE.COST_REWARD for Fee short term */
SELECT
"1.1" as STP_MYP,
GLC.name AS CLIENT_GROUP,
sa.date_beg as REWARD_BEG,
sa.date_beg as REWARD_END,
"FEE" AS Reward_Type,
sa.n_client as N_PAYER,
br.name AS ACC_EXECUTIVE,
sa.n_serv_agr_stat AS STATUS,
(SELECT str FROM str_lob(sa.n)) AS LOB,
prod.name as PRODUCT,
sa.n as N_SOURCE,
sa.is_new as IS_NEW,
sa.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
sa.date_beg as EFFECTIVE_DATE,
sa.date_end as EXPIRY_DATE,
SUM((SELECT res FROM recounttorur(fp.payment_amount, sa.n_curr, sa.date_beg))/1.20) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(fp.payment_amount/1.2) AS TOTAL_REV_ORIG_CUR_NET_VAT,
SUM(fp.payment_amount/1.2) AS COST_REWARD_ORIG_CUR,
0 as DFRD_REV_ON_INCEPT,
0 as PER_AMRTZD_REV,
sa.n_curr as N_CURR,
podr.n as PODR_N,
sa.agreem_no_our as REF_CERT

FROM serv_agreem sa

LEFT JOIN glc_group glc ON sa.n_glc_group=glc.n
LEFT JOIN fee_payment fp ON fp.n_serv_agreem=sa.n
LEFT JOIN client br ON br.n=sa.n_client1
LEFT JOIN client payer ON payer.n=sa.n_client
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=sa.n_product
left join curr on curr.n=sa.n_curr
left join NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.n_contr_type=sa.n_contr_type and ng.n_legal_entity=1)

WHERE
sa.posting_date>=:date_begin AND
sa.posting_date<=:date_end AND
sa.date_end-sa.date_beg<=730 and
sa.n_serv_agr_stat>3 and
lower(ng.type_reward) starting "fee"  and
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)

GROUP BY
STP_MYP, CLIENT_GROUP, REWARD_BEG, REWARD_END, Reward_Type, N_PAYER, ACC_EXECUTIVE, STATUS, LOB, PRODUCT,
N_SOURCE, IS_NEW, is_recurring, DEP, NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, CURR, N_CURR, PODR_N, REF_CERT

Union
/* Filling PERIOD_REVENUE.COST_REWARD for Re short term */
SELECT
"1.1" as STP_MYP,
GLC.name AS CLIENT_GROUP,
cn.date_beg as REWARD_BEG,
cn.date_beg as REWARD_END,
"RE" as Reward_Type,
payer.n_client as N_PAYER,
br.name AS ACC_EXECUTIVE,
cn.n_contract_status AS STATUS,
(SELECT str FROM str_lob_re(rl.n_ri_contract)) AS LOB,
prod.name as PRODUCT,
cn.n as N_SOURCE,
cn.is_new as IS_NEW,
cn.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
cn.date_beg as EFFECTIVE_DATE,
cn.date_end as EXPIRY_DATE,
SUM((SELECT res FROM recounttorur(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus*payer.perc_cedent /1200000, a.n_curr_comis, cn.date_beg))) as COST_REWARD,
curr.one_c_code as CURR,
SUM(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus*payer.perc_cedent /1200000) AS TOTAL_REV_ORIG_CUR_NET_VAT,
SUM(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus*payer.perc_cedent /1200000) AS COST_REWARD_ORIG_CUR,
0 as DFRD_REV_ON_INCEPT,
0 as PER_AMRTZD_REV,
a.n_curr_comis as N_CURR,
podr.n as PODR_N,
cn.r_number as REF_CERT

FROM layer_cl_reins lcr

LEFT JOIN ri_layer  rl ON rl.n=lcr.n_ri_layer
LEFT JOIN client reer ON reer.n=lcr.n_client
LEFT JOIN accrual a ON a.n_ri_layer=rl.n
/*LEFT JOIN  LAYER_REINS_BRK lrb ON lrb.N_LAYER_CL_REINS=lcr.n
LEFT JOIN BROK_TYPE_DEDUC btd ON btd.N_LAYER_REINS_BRK=lrb.n*/
LEFT JOIN ri_contract cn ON cn.n=rl.n_ri_contract
LEFT JOIN glc_group glc ON cn.n_glc_group=glc.n
LEFT JOIN client br ON br.n=cn.n_client
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=cn.n_product
LEFT JOIN NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.type_reward = 'ReinsComm' and ng.n_legal_entity=1)
left join curr on curr.n=a.n_curr_comis
LEFT JOIN RI_CEDENT payer on payer.n_ri_contract=cn.n

WHERE
cn.posting_date>=:date_begin AND
cn.posting_date<=:date_end AND
cn.date_end-cn.date_beg<=730 AND
cn.n_contract_status>1 and
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)

GROUP BY
STP_MYP, CLIENT_GROUP, REWARD_BEG, REWARD_END, Reward_Type, N_PAYER, ACC_EXECUTIVE, STATUS, rl.n_ri_contract,
PRODUCT, N_SOURCE, IS_NEW, is_recurring, DEP, NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, CURR , N_CURR, PODR_N, REF_CERT

UNION
/* Filling PERIOD_REVENUE.COST_REWARD for DBC long term */
SELECT
"2.1" as STP_MYP,
GLC.name AS CLIENT_GROUP,
p.icept_date as REWARD_BEG,
p.icept_date as REWARD_END,
"DBC" AS Reward_Type,
p.n_client2 as N_PAYER,
br.name AS ACC_EXECUTIVE,
p.n_policy_status AS STATUS,
lob.name AS LOB,
prod.name as PRODUCT,
p.n as N_SOURCE,
p.is_new_renew as IS_NEW,
p.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
p.icept_date as EFFECTIVE_DATE,
p.exp_date as EXPIRY_DATE,
(SELECT res FROM recounttorur((select INCEPT_REV from  LT_REWARD_P(p.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))), p.n_curr1, p.icept_date)) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(pp.brok_rate*pp.payment_amount/120) as TOTAL_REV_ORIG_CUR_NET_VAT,
(SELECT INCEPT_REV FROM lt_reward_p(p.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as COST_REWARD_ORIG_CUR,
SUM(pp.brok_rate*pp.payment_amount/120) - (SELECT INCEPT_REV FROM lt_reward_p(p.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as DFRD_REV_ON_INCEPT,
(SELECT ARMTZD_TO_POST_DATE_REV FROM lt_reward_p(p.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as PER_AMRTZD_REV,
p.n_curr1 as N_CURR,
podr.n as PODR_N,
p.policy_number as REF_CERT


FROM policy_stas p

LEFT JOIN client cl ON cl.n=p.n_client1
LEFT JOIN glc_group glc ON cl.n_glc_group=glc.n
LEFT JOIN policy_payment pp ON pp.n_policy_stas=p.n
LEFT JOIN client br ON br.n=p.n_client3
LEFT JOIN lob ON lob.n=p.n_lob
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=p.n_product
left join NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.type_reward = 'DBC' and ng.n_legal_entity=1)
left join curr on curr.n = p.n_curr1


WHERE
p.posting_date>=:date_begin AND
p.posting_date<=:date_end AND
p.n_fee_comm IN (2,3) AND
p.exp_date-p.icept_date>730 AND
(p.is_rejected='F' or p.is_rejected is null or p.reject_posting_date>:date_end) and
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)
-- added on 20220826
and pp.is_reject_pmnt = 'F'

GROUP BY STP_MYP, CLIENT_GROUP, Reward_Type, REWARD_BEG, REWARD_END, N_PAYER, ACC_EXECUTIVE, STATUS,
LOB, PRODUCT, N_SOURCE, IS_NEW, is_recurring, DEP, NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, CURR, p.n_curr1, p.icept_date, n_curr,  PODR_N, REF_CERT

union

/* Filling PERIOD_REVENUE.COST_REWARD for Fee long term */
SELECT
"2.1" as STP_MYP,
GLC.name AS CLIENT_GROUP,
sa.date_beg as REWARD_BEG,
sa.date_beg as REWARD_END,
"FEE" AS Reward_Type,
sa.n_client as N_PAYER,
br.name AS ACC_EXECUTIVE,
sa.n_serv_agr_stat AS STATUS,
(SELECT str FROM str_lob(sa.n)) AS LOB,
prod.name as PRODUCT,
sa.n as N_SOURCE,
sa.is_new as IS_NEW,
sa.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
sa.date_beg as EFFECTIVE_DATE,
sa.date_end as EXPIRY_DATE,
(SELECT res FROM recounttorur((select INCEPT_REV from LT_REWARD_SA(sa.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))), sa.n_curr, sa.date_beg)) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(fp.payment_amount/1.2) AS TOTAL_REV_ORIG_CUR_NET_VAT,
(select INCEPT_REV from LT_REWARD_SA(sa.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) AS COST_REWARD_ORIG_CUR,
SUM(fp.payment_amount/1.2) - (select INCEPT_REV from LT_REWARD_SA(sa.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as DFRD_REV_ON_INCEPT,
(SELECT ARMTZD_TO_POST_DATE_REV FROM lt_reward_sa(sa.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as PER_AMRTZD_REV,
sa.n_curr as N_CURR,
podr.n as PODR_N,
sa.agreem_no_our as REF_CERT

FROM serv_agreem sa

LEFT JOIN glc_group glc ON sa.n_glc_group=glc.n
LEFT JOIN fee_payment fp ON fp.n_serv_agreem=sa.n
LEFT JOIN client br ON br.n=sa.n_client1
LEFT JOIN client payer ON payer.n=sa.n_client
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=sa.n_product
left join curr on curr.n=sa.n_curr
left join NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.n_contr_type=sa.n_contr_type and ng.n_legal_entity=1)

WHERE
sa.posting_date>=:date_begin AND
sa.posting_date<=:date_end AND
sa.date_end-sa.date_beg>730 AND
sa.n_serv_agr_stat>3 AND
lower(ng.type_reward) starting "fee" and
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)

GROUP BY
STP_MYP, CLIENT_GROUP, REWARD_BEG, REWARD_END, Reward_Type, N_PAYER, ACC_EXECUTIVE, STATUS, LOB, PRODUCT,
N_SOURCE, IS_NEW, is_recurring, DEP, NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, CURR, sa.n_curr, sa.date_beg, N_CURR, PODR_N, REF_CERT

Union
/* Filling PERIOD_REVENUE.COST_REWARD for Re long term */
SELECT
"2.1" as STP_MYP,
GLC.name AS CLIENT_GROUP,
cn.date_beg as REWARD_BEG,
cn.date_beg as REWARD_END,
"RE" as Reward_Type,
payer.n_client as N_PAYER,
br.name AS ACC_EXECUTIVE,
cn.n_contract_status AS STATUS,
(SELECT str FROM str_lob_re(rl.n_ri_contract)) AS LOB,
prod.name as PRODUCT,
cn.n as N_SOURCE,
cn.is_new as IS_NEW,
cn.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
cn.date_beg as EFFECTIVE_DATE,
cn.date_end as EXPIRY_DATE,
(SELECT res FROM recounttorur((select INCEPT_REV from  LT_REWARD_CN(cn.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))), a.n_curr_comis, cn.date_beg)) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus*payer.perc_cedent /1200000) AS TOTAL_REV_ORIG_CUR_NET_VAT,
(SELECT INCEPT_REV FROM lt_reward_cn(cn.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as COST_REWARD_ORIG_CUR,
SUM(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus*payer.perc_cedent /1200000) - (SELECT INCEPT_REV FROM lt_reward_cn(cn.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as DFRD_REV_ON_INCEPT,
(SELECT ARMTZD_TO_POST_DATE_REV FROM lt_reward_cn(cn.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as PER_AMRTZD_REV,
a.n_curr_comis as N_CURR,
podr.n as PODR_N,
cn.r_number as REF_CERT

FROM layer_cl_reins lcr

LEFT JOIN ri_layer  rl ON rl.n=lcr.n_ri_layer
LEFT JOIN client reer ON reer.n=lcr.n_client
LEFT JOIN accrual a ON a.n_ri_layer=rl.n
/*LEFT JOIN  LAYER_REINS_BRK lrb ON lrb.N_LAYER_CL_REINS=lcr.n
LEFT JOIN BROK_TYPE_DEDUC btd ON btd.N_LAYER_REINS_BRK=lrb.n*/
LEFT JOIN ri_contract cn ON cn.n=rl.n_ri_contract
LEFT JOIN glc_group glc ON cn.n_glc_group=glc.n
LEFT JOIN client br ON br.n=cn.n_client
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=cn.n_product
LEFT JOIN NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.type_reward = 'ReinsComm' and ng.n_legal_entity=1)
left join curr on curr.n=a.n_curr_comis
LEFT JOIN RI_CEDENT payer on payer.n_ri_contract=cn.n

WHERE
cn.posting_date>=:date_begin AND
cn.posting_date<=:date_end AND
cn.date_end-cn.date_beg>730 AND
cn.n_contract_status>1  AND
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)

group by
CLIENT_GROUP,
REWARD_BEG,
REWARD_END,
N_PAYER,
ACC_EXECUTIVE,
STATUS,
rl.n_ri_contract, LOB, PRODUCT, N_SOURCE, IS_NEW, cn.is_recurring, DEP, ng.NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, a.n_curr_comis,
COST_REWARD, CURR, COST_REWARD_ORIG_CUR, N_CURR, PODR_N, REF_CERT

Union all

/* counting MYPs revenues between inception and posting date if entered after inception date */

/* Filling PERIOD_REVENUE.COST_REWARD for DBC long term */
SELECT
"2.3" as STP_MYP,
GLC.name AS CLIENT_GROUP,
p.icept_date as REWARD_BEG,
p.icept_date as REWARD_END,
"DBC" AS Reward_Type,
p.n_client2 as N_PAYER,
br.name AS ACC_EXECUTIVE,
p.n_policy_status AS STATUS,
lob.name AS LOB,
prod.name as PRODUCT,
p.n as N_SOURCE,
p.is_new_renew as IS_NEW,
p.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
p.icept_date as EFFECTIVE_DATE,
p.exp_date as EXPIRY_DATE,
(SELECT res FROM recounttorur((select ARMTZD_TO_POST_DATE_REV from  LT_REWARD_P(p.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))), p.n_curr1, p.icept_date)) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(pp.brok_rate*pp.payment_amount/120) as TOTAL_REV_ORIG_CUR_NET_VAT,
(SELECT ARMTZD_TO_POST_DATE_REV FROM lt_reward_p(p.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as COST_REWARD_ORIG_CUR,
SUM(pp.brok_rate*pp.payment_amount/120) - (SELECT INCEPT_REV FROM lt_reward_p(p.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as DFRD_REV_ON_INCEPT,
(SELECT ARMTZD_TO_POST_DATE_REV FROM lt_reward_p(p.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as PER_AMRTZD_REV,
p.n_curr1 as N_CURR,
podr.n as PODR_N,
p.policy_number as REF_CERT


FROM policy_stas p

LEFT JOIN client cl ON cl.n=p.n_client1
LEFT JOIN glc_group glc ON cl.n_glc_group=glc.n
LEFT JOIN policy_payment pp ON pp.n_policy_stas=p.n
LEFT JOIN client br ON br.n=p.n_client3
LEFT JOIN lob ON lob.n=p.n_lob
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=p.n_product
left join NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.type_reward = 'DBC' and ng.n_legal_entity=1)
left join curr on curr.n = p.n_curr1


WHERE
p.posting_date>=:date_begin AND
p.posting_date<=:date_end AND
p.n_fee_comm IN (2,3) AND
p.exp_date-p.icept_date>730 AND
(p.is_rejected='F' or p.is_rejected is null or p.reject_posting_date>:date_end) and
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)
-- added on 20220826
and pp.is_reject_pmnt = 'F'

GROUP BY STP_MYP, CLIENT_GROUP, Reward_Type, REWARD_BEG, REWARD_END, N_PAYER, ACC_EXECUTIVE, STATUS,
LOB, PRODUCT, N_SOURCE, IS_NEW, is_recurring, DEP, NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, CURR, p.n_curr1, p.icept_date, n_curr,  PODR_N, REF_CERT

union
/* ARMOTIZED_BEFORE_POSTING_on_FEEs */
SELECT
"2.3" as STP_MYP,
GLC.name AS CLIENT_GROUP,
sa.date_beg as REWARD_BEG,
sa.date_beg as REWARD_END,
"FEE" AS Reward_Type,
sa.n_client as N_PAYER,
br.name AS ACC_EXECUTIVE,
sa.n_serv_agr_stat AS STATUS,
(SELECT str FROM str_lob(sa.n)) AS LOB,
prod.name as PRODUCT,
sa.n as N_SOURCE,
sa.is_new as IS_NEW,
sa.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
sa.date_beg as EFFECTIVE_DATE,
sa.date_end as EXPIRY_DATE,
(SELECT res FROM recounttorur((select ARMTZD_TO_POST_DATE_REV from LT_REWARD_SA(sa.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))), sa.n_curr, sa.date_beg)) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(fp.payment_amount/1.2) AS TOTAL_REV_ORIG_CUR_NET_VAT,
(select ARMTZD_TO_POST_DATE_REV from LT_REWARD_SA(sa.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) AS COST_REWARD_ORIG_CUR,
SUM(fp.payment_amount/1.2) - (select INCEPT_REV from LT_REWARD_SA(sa.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as DFRD_REV_ON_INCEPT,
(SELECT ARMTZD_TO_POST_DATE_REV FROM lt_reward_sa(sa.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as PER_AMRTZD_REV,
sa.n_curr as N_CURR,
podr.n as PODR_N,
sa.agreem_no_our as REF_CERT

FROM serv_agreem sa

LEFT JOIN glc_group glc ON sa.n_glc_group=glc.n
LEFT JOIN fee_payment fp ON fp.n_serv_agreem=sa.n
LEFT JOIN client br ON br.n=sa.n_client1
LEFT JOIN client payer ON payer.n=sa.n_client
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=sa.n_product
left join curr on curr.n=sa.n_curr
left join NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.n_contr_type=sa.n_contr_type and ng.n_legal_entity=1)

WHERE
sa.posting_date>=:date_begin AND
sa.posting_date<=:date_end AND
sa.date_end-sa.date_beg>730 AND
sa.n_serv_agr_stat>3 AND
lower(ng.type_reward) starting "fee" and
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)

GROUP BY
STP_MYP, CLIENT_GROUP, REWARD_BEG, REWARD_END, Reward_Type, N_PAYER, ACC_EXECUTIVE, STATUS, LOB, PRODUCT,
N_SOURCE, IS_NEW, is_recurring, DEP, NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, CURR, sa.n_curr, sa.date_beg, N_CURR, PODR_N, REF_CERT

Union

/* ARMOTIZED_BEFORE_POSTING_on_Re */

SELECT
"2.3" as STP_MYP,
GLC.name AS CLIENT_GROUP,
cn.date_beg as REWARD_BEG,
cn.date_beg as REWARD_END,
"RE" as Reward_Type,
payer.n_client as N_PAYER,
br.name AS ACC_EXECUTIVE,
cn.n_contract_status AS STATUS,
(SELECT str FROM str_lob_re(rl.n_ri_contract)) AS LOB,
prod.name as PRODUCT,
cn.n as N_SOURCE,
cn.is_new as IS_NEW,
cn.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
cn.date_beg as EFFECTIVE_DATE,
cn.date_end as EXPIRY_DATE,
(SELECT res FROM recounttorur((select ARMTZD_TO_POST_DATE_REV from  LT_REWARD_CN(cn.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))), a.n_curr_comis, cn.date_beg)) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus*payer.perc_cedent /1200000) AS TOTAL_REV_ORIG_CUR_NET_VAT,
(SELECT ARMTZD_TO_POST_DATE_REV FROM lt_reward_cn(cn.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as COST_REWARD_ORIG_CUR,
SUM(a.cost_bonus*lcr.perc_reins*lcr.perc_comis_aonRus*payer.perc_cedent /1200000) - (SELECT INCEPT_REV FROM lt_reward_cn(cn.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as DFRD_REV_ON_INCEPT,
(SELECT ARMTZD_TO_POST_DATE_REV FROM lt_reward_cn(cn.n, cast(:date_begin as timestamp), cast(:date_end as timestamp))) as PER_AMRTZD_REV,
a.n_curr_comis as N_CURR,
podr.n as PODR_N,
cn.r_number as REF_CERT

FROM layer_cl_reins lcr

LEFT JOIN ri_layer  rl ON rl.n=lcr.n_ri_layer
LEFT JOIN client reer ON reer.n=lcr.n_client
LEFT JOIN accrual a ON a.n_ri_layer=rl.n
/*LEFT JOIN  LAYER_REINS_BRK lrb ON lrb.N_LAYER_CL_REINS=lcr.n
LEFT JOIN BROK_TYPE_DEDUC btd ON btd.N_LAYER_REINS_BRK=lrb.n*/
LEFT JOIN ri_contract cn ON cn.n=rl.n_ri_contract
LEFT JOIN glc_group glc ON cn.n_glc_group=glc.n
LEFT JOIN client br ON br.n=cn.n_client
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=cn.n_product
LEFT JOIN NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.type_reward = 'ReinsComm' and ng.n_legal_entity=1)
left join curr on curr.n=a.n_curr_comis
LEFT JOIN RI_CEDENT payer on payer.n_ri_contract=cn.n

WHERE
cn.posting_date>=:date_begin AND
cn.posting_date<=:date_end AND
cn.date_end-cn.date_beg>730 AND
cn.n_contract_status>1  AND
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)

group by
CLIENT_GROUP,
REWARD_BEG,
REWARD_END,
N_PAYER,
ACC_EXECUTIVE,
STATUS,
rl.n_ri_contract, LOB, PRODUCT, N_SOURCE, IS_NEW, cn.is_recurring, DEP, ng.NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, a.n_curr_comis,
COST_REWARD, CURR, COST_REWARD_ORIG_CUR, N_CURR, PODR_N, REF_CERT

union all

/* END of counting MYPs revenues between inception and posting date if entered after inception date */

SELECT
"3.1" as STP_MYP,
GLC.name AS CLIENT_GROUP,
p.icept_date as REWARD_BEG,
p.icept_date as REWARD_END,
"DBC" AS Reward_Type,
p.n_client2 as N_PAYER,
br.name AS ACC_EXECUTIVE,
p.n_policy_status AS STATUS,
lob.name AS LOB,
prod.name as PRODUCT,
p.n as N_SOURCE,
p.is_new_renew as IS_NEW,
p.is_recurring,
podr.n_p as DEP,
ng.NOM_GR_ONE_C_CODE,
p.icept_date as EFFECTIVE_DATE,
p.exp_date as EXPIRY_DATE,
/* line
-SUM(pp.brok_rate*(SELECT res FROM recounttorur(p.reject_sum, p.n_curr1, p.icept_date))/120) AS COST_REWARD,
replaced with below line on 202208226 */
SUM(pp.brok_rate*(SELECT res FROM recounttorur(pp.payment_amount, p.n_curr1, p.icept_date))/120) AS COST_REWARD,
curr.one_c_code as CURR,
SUM(pp.brok_rate*pp.payment_amount/100) AS TOTAL_REV_ORIG_CUR_NET_VAT,
SUM(pp.brok_rate*pp.payment_amount/120) AS COST_REWARD_ORIG_CUR,
0 as DFRD_REV_ON_INCEPT,
0 as PER_AMRTZD_REV,
p.n_curr1 as N_CURR,
podr.n as PODR_N,
p.policy_number as REF_CERT


FROM policy_stas p

LEFT JOIN client cl ON cl.n=p.n_client1
LEFT JOIN glc_group glc ON cl.n_glc_group=glc.n
LEFT JOIN policy_payment pp ON pp.n_policy_stas=p.n
LEFT JOIN client br ON br.n=p.n_client3
LEFT JOIN lob ON lob.n=p.n_lob
LEFT JOIN sotr on sotr.n=br.n_sotr
LEFT JOIN podr on podr.n=sotr.n_otd
LEFT JOIN PRODUCT prod on prod.n=p.n_product
left join NOMENKL_GROUP ng on (ng.n_podr=podr.n and ng.type_reward = 'DBC' and ng.n_legal_entity=1)
left join curr on curr.n = p.n_curr1

WHERE
p.reject_posting_date>=:date_begin AND
p.reject_posting_date<=:date_end AND
p.n_fee_comm IN (2,3) AND
pp.is_reject_pmnt='T' AND
(glc.N=:N_GLC_GROUP or :N_GLC_GROUP=0 )   and
(podr.n<>:N_PODR or :N_PODR=0)

GROUP BY STP_MYP, CLIENT_GROUP, Reward_Type, REWARD_BEG, REWARD_END, N_PAYER, ACC_EXECUTIVE, STATUS,
LOB, PRODUCT, N_SOURCE, IS_NEW, is_recurring, DEP, NOM_GR_ONE_C_CODE, EFFECTIVE_DATE, EXPIRY_DATE, CURR, N_CURR, PODR_N, REF_CERT


into
:STP_MYP,
:CLIENT_GROUP,
:REWARD_BEG,
:REWARD_END,
:REWARD_TYPE,
:N_PAYER,
:ACC_EXECUTIVE,
:STATUS,
:LOB,
:PRODUCT,
:N_SOURCE,
:IS_NEW,
:IS_RECURRING,
:DEP,
:NOM_GR_ONE_C_CODE,
:EFFECTIVE_DATE,
:EXPIRY_DATE,
:COST_REWARD,
:CURR,
:TOT_REV_CUR_NET_VAT,
:COST_REWARD_ORIG_CUR,
:DFRD_REV_ON_INCEPT,
:PER_AMRTZD_REV,
:N_CURR,
:PODR_N,
:REF_CERT

do
suspend;

end