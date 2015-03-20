-- Function: nutrients.get_currentfields()

-- DROP FUNCTION nutrients.get_currentfields();

CREATE OR REPLACE FUNCTION nutrients.get_currentfields(OUT farmid integer, OUT uoid integer, OUT tstart timestamp without time zone, OUT tend timestamp without time zone)
  RETURNS SETOF record AS
$BODY$

DECLARE
	r record;
begin
	for r in
		select f.farmid, f.uoid, min(f.tstart) as tstart, max(f.tend) as tend
		from farm.fields f 
		group by f.farmid, f.uoid 
		order by f.farmid, f.uoid
	loop

		farmid = r.farmid;
		uoid = r.uoid;
		tstart = r.tstart;
		tend = r.tend;
		return next;

	end loop;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION nutrients.get_currentfields()
  OWNER TO dboperator;
COMMENT ON FUNCTION nutrients.get_currentfields() IS 'Liefert aktuelle Schläge mit Zeitraum.';
