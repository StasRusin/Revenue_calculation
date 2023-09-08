create or alter procedure STR_LOB (
    N_SERV_AGREEM integer)
returns (
    STR varchar(100))
as
declare variable N integer;
declare variable STR_TEMP varchar(15);
declare variable N_TEMP integer;
declare variable I integer;
bEGIN
/* Procedure Text */
select count(L.N)
from LOB L
left join SERV_AGR_LOB SAL on L.N = SAL.N_LOB
left join SERV_AGREEM SA on SA.N = SAL.N_SERV_AGREEM
where SA.N = :N_SERV_AGREEM
into :N_TEMP;
STR = '';
i = 0;
for select distinct L.N
    from LOB L
    left join SERV_AGR_LOB SAL on L.N = SAL.N_LOB
    left join SERV_AGREEM SA on SA.N = SAL.N_SERV_AGREEM
    where SA.N = :N_SERV_AGREEM
    into :N
do
begin
  i = i + 1;
  select NAME
  from LOB
  where N = :N
  into :STR_TEMP;
  if (i = N_TEMP) then
    STR = STR || STR_TEMP;
  else
    STR = STR || STR_TEMP || ', ';
end
suspend;
end