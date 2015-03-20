-- Function: nutrients.get_samplesofperiod(integer)

-- DROP FUNCTION nutrients.get_samplesofperiod(integer);

CREATE OR REPLACE FUNCTION nutrients.get_samplesofperiod(IN p_periodid integer, OUT sampleid integer)
  RETURNS SETOF integer AS
$BODY$
DECLARE
	r record;
	v_farmid integer;
	v_fieldgeom geometry;
	v_tstart timestamp without time zone;
	v_year integer;
begin
	----------------------------------------------------------------
	-- Sucht Proben zum Schlag einer Planungsperiode;
	-- fieldid in planningperiod ist uoid des aktuellen
	-- Schlags der Schlagkartei
	----------------------------------------------------------------

	-- Geometrie suchen
	select p.farmid, f.geom, p.tstart into v_farmid, v_fieldgeom, v_tstart
	from nutrients.planningperiod p
	inner join nutrients.get_currentfields() c on c.farmid=p.farmid and c.uoid=p.fieldid
	inner join farm.fields f on f.farmid=c.farmid and f.uoid=c.uoid and f.tend=c.tend
	where p.id = p_periodid;

	if (v_farmid is  null or v_fieldgeom is null or v_tstart is null) then
		return;
	end if;

	-- Beprobungsdatum kann ein Jahr später als
	-- Start der Planungsperiode liegen
	--
	-- Periode enthält frühestes Beprobungsdatum,
	-- es können spätere Proben für weitere Beprobung
	-- im Folgejahr vorhanden sein
	
	v_year = date_part('year', v_tstart);

	for r in
		select * from nutrients.samples s
		where s.farmid = v_farmid and st_intersects(s.geom, v_fieldgeom)
		and date_part('year', s.sampledate) >= v_year 
		and date_part('year', s.sampledate) <= v_year + 1
	loop
		sampleid = r.id;
		return next;
	end loop;

end;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION nutrients.get_samplesofperiod(integer)
  OWNER TO dboperator;
COMMENT ON FUNCTION nutrients.get_samplesofperiod(integer) IS 'Sucht Proben einer Planungsperiode über Startzeit und uoid des Schlags';
