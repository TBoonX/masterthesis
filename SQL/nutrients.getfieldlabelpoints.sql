-- Function: nutrients.getfieldlabelpoints(text, integer)

-- DROP FUNCTION nutrients.getfieldlabelpoints(text, integer);

CREATE OR REPLACE FUNCTION nutrients.getfieldlabelpoints(multiline text, fieldid integer)
  RETURNS SETOF nutrients.contourpolygon AS
$BODY$

DECLARE
	v_linestring alias for $1;
	v_fieldid alias for $2;
	v_srid integer;
	v_farmid integer;
	v_mgeom geometry;
	v_fieldgeom geometry;
	v_line geometry;
	v_pgcoll geometry[];
	v_flag integer;
	v_pg geometry;
	v_pgtest geometry;
	v_point geometry;
	v_cpg nutrients.contourpolygon;
	v_upper integer;
	
	-- db logging
	v_errmsg text;
	v_errdetail text;
	v_errhint text;
	v_errcontext text;
	v_params text;
BEGIN

EXECUTE 'Select common.find_utm_srid(st_centroid(geom)), farmid from farm.fields where id =$1'  
INTO v_srid, v_farmid USING v_fieldid;

EXECUTE 'SELECT st_transform(geom,$2) FROM farm.fields WHERE id = $1'  
INTO v_fieldgeom USING v_fieldid, v_srid;

v_mgeom :=st_setsrid( v_linestring::geometry,v_srid);	
--Execute 'Create or replace view xmultiline as select 1, ' || quote_literal(v_mgeom::text) || '::geometry' ;
v_pgcoll[1]:= v_fieldgeom;
for v_line in select (st_dump(v_mgeom)).geom  loop
	v_upper:=array_upper(v_pgcoll, 1);
	for k in 1 .. v_upper loop 
		v_pgtest:=v_pgcoll[k];
		if ( st_intersects(v_pgtest,v_line)) then
			v_flag:=0;
			for v_pg IN select (st_dump(st_split(v_pgtest ,v_line))).geom  loop
				if (v_flag=0) then
					v_pgcoll[k]:=v_pg;
					v_flag:=1;
				else
					v_pgcoll[array_upper(v_pgcoll, 1)+1]:= v_pg;
				end if;									
			end loop;
		end if;
 	end loop;	
end loop;

for l in 1 .. array_upper(v_pgcoll, 1) loop 
	v_pg:=v_pgcoll[l];
	v_point:=st_pointonsurface(v_pg);
	select into v_cpg 0 as "level", v_pg as polygon,  st_x(v_point) as cx, st_y(v_point) as cy;
	return next v_cpg;
end loop;
return;

EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS
	    v_errmsg  = MESSAGE_TEXT,
	    v_errdetail  = PG_EXCEPTION_DETAIL,
	    v_errhint    = PG_EXCEPTION_HINT,
	    v_errcontext = PG_EXCEPTION_CONTEXT;

	   Insert into  common.errors (functionname,parameters, farmid, errormessage,"datetime") Values(
		'nutrients.contouringapplication', 
		'fieldid=' || v_fieldid::text, v_farmid, 
		v_errmsg ||  ' ' ||
		v_errdetail || ' ' ||
		v_errhint|| ' ' ||
		v_errcontext , now());			

return;
END;



$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION nutrients.getfieldlabelpoints(text, integer)
  OWNER TO dboperator;
COMMENT ON FUNCTION nutrients.getfieldlabelpoints(text, integer) IS 'Kontur-Geometrie für Streukarte';
