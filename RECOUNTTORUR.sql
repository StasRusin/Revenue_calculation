create or alter procedure RECOUNTTORUR (
    VAL numeric(15,2),
    N_CURR integer,
    DATE_CURR date)
returns (
    RES numeric(15,2))
as
	declare variable RUBNUMBER integer;
	declare variable NUM integer;
	declare variable CURS decimal(15,4);
begin
-- chek if we need to recalculate value, i.e. if value of RUB is given, simply return rounded entered value
    select n from curr where is_lusd='R' into :rubnumber;

    if (n_curr=RUBNumber) then
        select outx from round2up(:val) into Res;
    else
        begin
			select max(date_curr) from rates where n_curr=:n_curr and date_curr<=:date_curr into :date_curr;
			select curr_val from rates where n_curr=:n_curr and date_curr=:date_curr into :curs;
			select num_unit from curr where n=:n_curr into :num;

			if ((curs=0) or (num=0) or (curs is null) or (num is null)) then
				select outx from round2up(:val) into Res;
			else
				select mult(:val,:curs) from rdb$database into :val;
				select outx from round2up(:val/:num) into :res;
		end
    suspend;
end