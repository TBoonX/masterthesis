-- Function: common.find_utm_srid(geometry)

-- DROP FUNCTION common.find_utm_srid(geometry);

CREATE OR REPLACE FUNCTION common.find_utm_srid(p geometry)
  RETURNS integer AS
$BODY$

DECLARE
         out_srid integer;
         base_srid integer;

BEGIN
         IF st_srid(p) != 4326 THEN
                 RAISE NOTICE 'find_utm_srid: input geometry has wrong SRID %',  st_srid(p);
                 RETURN NULL;
         END IF;

         IF st_y(p) < 0 THEN
                 --- south hemisphere
                 base_srid := 32700;
         ELSE
                 --- north hemisphere or on equator
                 base_srid := 32600;
         END IF;

         out_srid := base_srid + floor((st_x(p)+186)/6);
         IF (st_x(p) = 180) THEN
                 out_srid := base_srid + 60;
         END IF;

         --- TODO: consider special cases around norway etc.
         RETURN out_srid;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION common.find_utm_srid(geometry)
  OWNER TO dboperator;
