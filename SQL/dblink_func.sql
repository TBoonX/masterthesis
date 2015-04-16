-- Function: utils.dblink_func(text, text)

-- DROP FUNCTION utils.dblink_func(text, text);

CREATE OR REPLACE FUNCTION utils.dblink_func(_schema_name text, _table_name text)
  RETURNS text AS
$BODY$
    DECLARE       
        _dblink_schema text :='public';
        _cols          text; 
        _q             text;
        _func_name     text := format('utils.link_%s_%s', $1, $2);
        _func          text;        
    BEGIN

        SELECT array_to_string(array_agg(quote_ident(column_name) || ' ' || udt_name), ', ') INTO _cols
        FROM (Select column_name,case when data_type='USER-DEFINED' then udt_schema ||'.' ||udt_name else  udt_name end as udt_name from information_schema.columns WHERE table_schema = $1
        AND table_name = $2 order by ordinal_position)x;
        
        _q := format('SELECT * FROM %I.dblink(_conn, %L || _whereclause) AS remote (%s)',
            _dblink_schema,            
            format('SELECT * FROM %I.%I ', $1, $2),
            _cols
        );
        

        _func := $_func$
            CREATE OR REPLACE FUNCTION %s(_conn text, _whereclause text)
            RETURNS SETOF %I.%I
            LANGUAGE SQL
            VOLATILE STRICT
            AS $$ %s; $$
        $_func$;
Raise Notice '_func_name: %', _func_name;

        EXECUTE format(_func, _func_name, $1, $2, _q);

        RETURN _func_name;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT
  COST 100;
ALTER FUNCTION utils.dblink_func(text, text)
  OWNER TO dboperator;
