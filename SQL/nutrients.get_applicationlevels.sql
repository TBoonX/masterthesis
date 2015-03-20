-- Function: nutrients.get_applicationlevels(double precision, double precision)

-- DROP FUNCTION nutrients.get_applicationlevels(double precision, double precision);

CREATE OR REPLACE FUNCTION nutrients.get_applicationlevels(maxv double precision, minv double precision)
  RETURNS SETOF integer AS
$BODY$
 declare
  i integer;
begin
	
	if (maxv-minv >10) then
		for i in select  generate_series(floor(minv)::integer, ceil(maxv)::integer,((ceil(maxv) - floor(minv))/9.5)::integer) loop
			return next i;
		end loop;
	else
		for i in select  generate_series(floor(minv)::integer,ceil(maxv)::integer, 1) loop
			return next i;
		end loop;
	end if;


end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 100;
ALTER FUNCTION nutrients.get_applicationlevels(double precision, double precision)
  OWNER TO dboperator;
COMMENT ON FUNCTION nutrients.get_applicationlevels(double precision, double precision) IS 'Erstellt Intervalle für Streukarten aus Max/Min.';
