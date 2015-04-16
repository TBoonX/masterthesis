
DO $$DECLARE 
_table text;
_schema text;
BEGIN
_schema:='catalogs';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='common';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='farm';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='files';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='ips';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='log';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='n';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='nutrients';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='pp';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='statistics';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
_schema:='tasks';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
 _schema:='umn';
    FOR _table IN SELECT table_name FROM information_schema.tables WHERE table_schema = _schema and table_type = 'BASE TABLE' LOOP
        EXECUTE 'Select utils.dblink_func(' || quote_literal(_schema) || ',' || quote_literal(_table) || ');';
    END LOOP;
END$$;

