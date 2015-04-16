-- Function: notify_inserts()

-- DROP FUNCTION notify_inserts();

CREATE OR REPLACE FUNCTION notify_inserts()
  RETURNS trigger AS
$BODY$
DECLARE
BEGIN
    PERFORM pg_notify('databasewatchdog', 'INSERT,' || TG_TABLE_NAME || ',id,' || NEW.id);
    RETURN null;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION notify_inserts()
  OWNER TO dboperator;
