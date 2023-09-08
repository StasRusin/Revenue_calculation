create or alter procedure STR_LOB_RE (
    N_RI_CONTRACT integer)
returns (
    STR varchar(100))
as
declare variable N integer;
declare variable STR_TEMP varchar(15);
declare variable N_TEMP integer;
declare variable I integer;
begin
/* Procedure Text */
select count(n) from lob l
left join RI_LAYER_LOB rill on l.n=rill.n_lob
left join RI_LAYER rl on rl.n=rill.n_ri_layer
left join ri_contract cn on cn.n=rl.n_ri_contract
where cn.n=:n_ri_contract into :n_temp;
str='';
i=0;
for select distinct l.n from lob l
    left join RI_LAYER_LOB rill on l.n=rill.n_lob
    left join RI_LAYER rl on rl.n=rill.n_ri_layer
    left join ri_contract cn on cn.n=rl.n_ri_contract
    where cn.n=:n_ri_contract into :n do

    begin
        i=i+1;
        select name from lob where n=:n into :str_temp;
        if (i=n_temp) then
        str=str||str_temp;
        else
        str=str||str_temp||', ';
    end
suspend;
end