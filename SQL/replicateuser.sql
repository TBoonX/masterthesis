-- Function: utils.replicateuser(text, integer, integer)

-- DROP FUNCTION utils.replicateuser(text, integer, integer);

CREATE OR REPLACE FUNCTION utils.replicateuser(_conn text, _userid integer, _farmid integer)
  RETURNS boolean AS
$BODY$
DECLARE
 
  _table text;
  _schema text; 
  _r integer;
  
begin
	
	
	_schema:='farm';

	Select id from farm.users into _r where id = _userid;
		if (not found) then
			raise warning 'Kopiere new user %',_userid;

			FOREACH _table IN ARRAY array['users','usersettings'] LOOP 
				
				Select id from farm.users into _r where id = _userid;
				
				Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
						quote_literal(_conn), quote_literal(' where id=' || _userid));
				
				if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _table || '_id_seq') )
				then
				Execute 'select setval('|| quote_literal(_schema || '.' || _table || '_id_seq') || 
					', (select max(id) from '|| _schema || '.' || _table || ') +1);';	
				end if;
				
			end loop; 
		else
			raise warning 'Daten vorhanden % %',_r, _table;
		end if;

	Select id from farm.farms into _r where id=_farmid;
	if found then
		raise warning 'Farm exists % -> add User',_r;
		Select id from farm.farmusers into _r where userid = _userid and farmid = _farmid;
			if (not found) then
				Insert into farm.farmusers (farmid,userid) values (_farmid,_userid);
			end if;
	else
		raise warning 'Farm does not exist % -> please add user to farm later',_r;

	end if;
	return true;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION utils.replicateuser(text, integer, integer)
  OWNER TO dboperator;
