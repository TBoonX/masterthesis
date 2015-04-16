-- Function: utils.replicateuser(text, integer, integer)

-- DROP FUNCTION utils.replicateuser(text, integer, integer);

CREATE OR REPLACE FUNCTION utils.replicateuser(
    _conn text,
    _userid integer,
    _farmid integer)
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

-- Function: utils.replicateuser(text, text, text, text, text, integer, integer)

-- DROP FUNCTION utils.replicateuser(text, text, text, text, text, integer, integer);

CREATE OR REPLACE FUNCTION utils.replicateuser(
    str_hostaddr text,
    str_port text,
    str_db text,
    str_user text,
    str_password text,
    _userid integer,
    _farmid integer)
  RETURNS boolean AS
$BODY$
DECLARE
  _conn text;
  _table text;
  _schema text; 
  _r integer;
  
begin
	RAISE NOTICE 'Replicate User: from db-> %  to db->  %', str_db, (select current_database());
	
	_conn:='hostaddr='|| str_hostaddr || ' port=' || str_port || ' dbname=' || str_db || ' user=' ||str_user || ' password=' ||str_password;

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
ALTER FUNCTION utils.replicateuser(text, text, text, text, text, integer, integer)
  OWNER TO dboperator;


-- Function: utils.replicatesettings(text, text, text, text, text)

-- DROP FUNCTION utils.replicatesettings(text, text, text, text, text);

CREATE OR REPLACE FUNCTION utils.replicatesettings(
    str_hostaddr text,
    str_port text,
    str_db text,
    str_user text,
    str_password text)
  RETURNS boolean AS
$BODY$
DECLARE
  _conn text;
  _table text;
  _schema_table text; 
  
begin
	RAISE NOTICE 'Replicate Settings: from db-> %  to db->  %', str_db, (select current_database());
	
	_conn:='hostaddr='|| str_hostaddr || ' port=' || str_port || ' dbname=' || str_db || ' user=' ||str_user || ' password=' ||str_password;

	-- ############# schema catalogs ##############################
	-- wo farm- spezifische Daten vorhanden sind diese nicht kopieren
	-- ##############################################################

	FOREACH _table IN ARRAY array['fertilizersloc','licencehistory','ltfertilizerinorg','ltfertilizerorg',
					'selectablecrops', 'selectablefertilizer', 'licences' ] LOOP 
		raise warning 'Kopiere Daten catalogs.%', _table;
		Execute format('insert into catalogs.%s Select * from utils.link_catalogs_%s(%s,%s)',_table,_table,
		quote_literal(_conn), quote_literal('where farmid=-1'));
		if (_table = 'ltfertilizerorg' or _table= 'ltfertilizerinorg') then
			Execute 'select setval(' || quote_literal('catalogs.ltfertilizer_id_seq') || ',(select max(max) from (select max(id) ' ||
			'from catalogs.ltfertilizerinorg union select max(id) from catalogs.ltfertilizerorg)x));';
		else
			Execute 'select setval('|| quote_literal('catalogs.' || _table || '_id_seq') || 
			', (select max(id) from catalogs.' || _table || ') +1);';	
		end if;
	end loop; 


	-- ############# schema catalogs ##############################
	-- Nachschlagetabellen
	-- ##############################################################
	
	 FOREACH _table IN ARRAY array['cropcategories','cropcategoryloc','croplanguages','croptypes','croptypesloc','featurefunctions','featurelevels',
					'features','fertilizerconv','ips_statistics','isobusddi','liccosts','licencetypes','ltcategories','ltcountries',
					'ltecstages','ltecstagedetails','ltecmacrostages','ltfertilizercategories','ltfertilizercategoryloc','ltlanduse',
					'ltlanduseloc','ltlanguages','ltlicencetypes','ltmethods','ltmethodsph','ltpfboxagents','ltpfboxapplnum',
					'ltpfboxcrops','ltpfboxdeadbiomass','ltpfboxmineralpot','ltpfboxopmodes','ltpfboxyieldexpct','ltregions',
					'ltroletypes','ltsamplekeys','ltstates','lttaskfillmodes','ltuserroles','ltvariogrammodel','plantprotections',
					'regions','states','tasktype','varieties','worktypes','worktypesloc'] LOOP 
		raise warning 'Kopiere Daten catalogs.%', _table;
		
		Execute format('insert into catalogs.%s Select * from utils.link_catalogs_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('catalogs.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('catalogs.' || _table || '_id_seq') || 
			', (select max(id) from catalogs.' || _table || ') +1);';	
		end if;
	end loop;

	-- ############# schema catalogs ##############################
	-- Metadaten
	-- ##############################################################
	FOREACH _table IN ARRAY array['basemap','basemaploc','layercategories','categorythemes','categorythemeloc','config','defaultviews',
					'ltcategories','defaultviewloc','districts','errorcode','kmlcategories',
					'layercategoryloc','layerthemes','ltcountries','ltecstages',
					'ltlanguages','ltstates','napplicationlayers','significance','userlayerinfocolumns',
					'viewcolumntranslations'] LOOP 
		raise warning 'Kopiere Daten common.%', _table;
		
		Execute format('insert into common.%s Select * from utils.link_common_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('common.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('common.' || _table || '_id_seq') || 
			', (select max(id) from common.' || _table || ') +1);';	
		end if;
	end loop;

	
	-- ############# schema farm ##############################
	-- Metadaten
	-- ##############################################################
	FOREACH _table IN ARRAY array['licencecosts','news'] LOOP 
		raise warning 'Kopiere Daten farm.%', _table;
		
		Execute format('insert into farm.%s Select * from utils.link_farm_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('farm.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('farm.' || _table || '_id_seq') || 
			', (select max(id) from farm.' || _table || ') +1);';	
		end if;
	end loop;

	-- ############# schema file ##############################
	-- Metadaten
	-- ##############################################################
	FOREACH _table IN ARRAY array['filetypes','formattypes','importstatus'] LOOP 
		raise warning 'Kopiere Daten files.%', _table;
		
		Execute format('insert into files.%s Select * from utils.link_files_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('files.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('files.' || _table || '_id_seq') || 
			', (select max(id) from files.' || _table || ') +1);';	
		end if;
	end loop;


	-- ############# schema n ##############################
	-- Metadaten
	-- ##############################################################
	
	FOREACH _table IN ARRAY array['nappformula','nappthresholds','nrecommendation',
		'nvariety','nvarietycorrection','nyrange','scannerperiod'] LOOP 
		raise warning 'Kopiere Daten n.%', _table;
		Alter table n.nvarietycorrection disable trigger all;
		Execute format('insert into n.%s Select * from utils.link_n_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('n.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('n.' || _table || '_id_seq') || 
			', (select max(id) from n.' || _table || ') +1);';	
		end if;
		Alter table n.nvarietycorrection enable trigger all;
		
	end loop;

	-- ############# schema nutrients ##############################
	-- Metadaten
	-- ##############################################################
	FOREACH _table IN ARRAY array['contouringconfig','cropcolors','cropcolorindex',
		'krigconfig','ltappfileformat','ltlevels','ltscannerlevels','rasterthreshold'] LOOP 
		raise warning 'Kopiere Daten nutrients.%', _table;

		Execute format('insert into nutrients.%s Select * from utils.link_nutrients_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('nutrients.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('nutrients.' || _table || '_id_seq') || 
			', (select max(id) from nutrients.' || _table || ') +1);';	
		end if;
		
	end loop;

	-- ############# schema pp ##############################
	-- Metadaten
	-- ##############################################################
	FOREACH _table IN ARRAY array['gragents','grnuptakelevels'] LOOP 
		raise warning 'Kopiere Daten pp.%', _table;
		
		Execute format('insert into pp.%s Select * from utils.link_pp_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('pp.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('pp.' || _table || '_id_seq') || 
			', (select max(id) from pp.' || _table || ') +1);';	
		end if;
	end loop;
	
	-- ############# schema statistics ##############################
	-- Metadaten
	-- ##############################################################
	FOREACH _table IN ARRAY array['cutoffdistance','cutoffs','significance'] LOOP 
		raise warning 'Kopiere Daten statistics.%', _table;
		
		Execute format('insert into statistics.%s Select * from utils.link_statistics_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('statistics.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('statistics.' || _table || '_id_seq') || 
			', (select max(id) from statistics.' || _table || ') +1);';	
		end if;
	end loop;

	-- ############# schema tasks ##############################
	-- Metadaten
	-- ##############################################################
	FOREACH _table IN ARRAY array['applicationmodes','config','spreaderunits',
					'terminaltypes','terminalfolders'] LOOP 
		raise warning 'Kopiere Daten tasks.%', _table;
		
		Execute format('insert into tasks.%s Select * from utils.link_tasks_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('tasks.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('tasks.' || _table || '_id_seq') || 
			', (select max(id) from tasks.' || _table || ') +1);';	
		end if;
	end loop;


	-- ############# schema umn ##############################
	-- Metadaten
	-- ##############################################################
	FOREACH _table IN ARRAY array['labelconfig','printcategories','printlayers'] LOOP 
		raise warning 'Kopiere Daten umn.%', _table;
		
		Execute format('insert into umn.%s Select * from utils.link_umn_%s(%s,%s)',_table,_table,
			quote_literal(_conn), quote_literal(''));
		if exists (select 0 from pg_class where relname = quote_literal('umn.' || _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal('umn.' || _table || '_id_seq') || 
			', (select max(id) from umn.' || _table || ') +1);';	
		end if;
	end loop;
	return true;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION utils.replicatesettings(text, text, text, text, text)
  OWNER TO dboperator;


  -- Function: utils.replicatefarm(text, text, text, text, text, integer)

-- DROP FUNCTION utils.replicatefarm(text, text, text, text, text, integer);

CREATE OR REPLACE FUNCTION utils.replicatefarm(
    str_hostaddr text,
    str_port text,
    str_db text,
    str_user text,
    str_password text,
    _farmid integer)
  RETURNS boolean AS
$BODY$
DECLARE
  _conn text;
  _table text;
  _nested_table text;
  _schema text;
  _r integer;

  
begin
	RAISE NOTICE 'Replicate Farm: %  from db-> %  to db->  %',_farmid::text, str_db, (select current_database());
	
	_conn:='hostaddr='|| str_hostaddr || ' port=' || str_port || ' dbname=' || str_db || ' user=' ||str_user || ' password=' ||str_password;

	-- update used userids for photos

	for _r in SELECT userid FROM public.dblink(_conn, 'SELECT userid FROM farm.photos where farmid =' || _farmid) 
		AS remote (userid int4) loop
		Perform utils.replicateuser(_conn,_r,_farmid);
	end loop;
 
	
	-- ############# schema farm ##############################
	-- Daten
	-- ##############################################################

	_schema:='farm';
	
	FOREACH _table IN ARRAY array['farms','branch_of_activity','campaignyear',
		'fields','photos','photoseries','terminalmail'] LOOP 
		raise warning 'Kopiere Daten %.%',_schema, _table;
		if (_table='farms')then
			Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
				quote_literal(_conn), quote_literal(' where id=' || _farmid));
	
		else
			Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
				quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
		end if;
		
		if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _table || '_id_seq') || 
			', (select max(id) from '|| _schema || '.' || _table || ') +1);';	
		end if;
		
		
	end loop;
	
	--nested tables
	_nested_table:='serieimages';
	Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_nested_table,_schema,_nested_table,
		quote_literal(_conn), quote_literal(' where photoserieid in (select distinct id from farm.photoseries'||
			' where farmid=' || _farmid|| ')'));
	if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _nested_table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _nested_table || '_id_seq') || 
		', (select max(id) from '|| _schema || '.' || _nested_table || ') +1);';	
	end if;

	
	
	-- now create licenses
	_schema:='catalogs';
	_table:='licences';
	Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
				quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
		
		if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _table || '_id_seq') || 
			', (select max(id) from '|| _schema || '.' || _table || ') +1);';	
		end if;
	-- ############# schema files ##############################
	-- Daten
	-- ##############################################################

	_schema:='files';
	
	FOREACH _table IN ARRAY array['fieldimports','grlogfiles','nsensorlogfiles','soilsample_analytic',
		'soilsamplefields','soilsamplefiles','soilsampletracks','soilsampling','soilscannerfields',
		'soilscannerfiles'] LOOP 
		raise warning 'Kopiere Daten %.%',_schema, _table;
		
		Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
				quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
		
		if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _table || '_id_seq') || 
			', (select max(id) from '|| _schema || '.' || _table || ') +1);';	
		end if;
				
	end loop;

	--nested tables
	_nested_table:='sensorofficeuser';
	raise warning 'Kopiere Daten %.%',_schema, _nested_table;
		
	Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_nested_table,_schema,_nested_table,
		quote_literal(_conn), quote_literal(' where kdnr in (select distinct customernumber from farm.farms'||
			' where id=' || _farmid|| ')'));
	if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _nested_table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _nested_table || '_id_seq') || 
		', (select max(id) from '|| _schema || '.' || _nested_table || ') +1);';	
	end if;


	-- ############# schema n ##############################
	-- Daten
	-- ##############################################################


	_schema:='n';
	
	FOREACH _table IN ARRAY array['appliedraster','biraster','logfilestatistics','logheader',
		'nfieldlogheader','nfieldsums','nlogfilefield','nmonitoring','nraster','nsensorlogs',
		'ntoollog','recraster','sumraster','temp'] LOOP 
		raise warning 'Kopiere Daten %.%',_schema, _table;
		
		Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
				quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
		
		if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _table || '_id_seq') || 
			', (select max(id) from '|| _schema || '.' || _table || ') +1);';	
		end if;
				
	end loop;

	--nested tables nmonitoringdetails
	_nested_table:='nmonitoringdetails';
	raise warning 'Kopiere Daten %.%',_schema, _nested_table;
	Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema, _nested_table,_schema, _nested_table,
			quote_literal(_conn), quote_literal(' where nmonitoringid in (select distinct id from n.nmonitoring'||
			' where farmid=' || _farmid|| ')'));

	if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _nested_table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _nested_table || '_id_seq') || 
		', (select max(id) from '|| _schema || '.' || _nested_table || ') +1);';	
	end if;





	-- ############# schema nutrients ##############################
	-- Daten
	-- ##############################################################
	_schema:='nutrients';
	--error mit Trigger
	
	Alter table nutrients.planningperiod disable trigger d_update_nutrientsstatistics;
	
	FOREACH _table IN ARRAY array['samplefields','samples','sampletracks','planningperiod','appdownloadlog',
		'classaverages','planning','crops','fcosts','fertilizations','originalsamples','plannedfields','ruleerrors',
		'rules','selectedrules','soilscannercontour',
		'soilscannerfields','soilscannersparse','soilscannerval','usercalendar'] LOOP 
		raise warning 'Kopiere Daten %.%',_schema, _table;
		
		Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
				quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
		
		if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _table || '_id_seq') || 
			', (select max(id) from '|| _schema || '.' || _table || ') +1);';	
		end if;
				
	end loop;
	Alter table nutrients.planningperiod enable trigger d_update_nutrientsstatistics;
	
	--nested tables distributions

		FOREACH _nested_table IN ARRAY array['kdistribution','mgdistribution','pdistribution','phdistribution'] LOOP 	
		       raise warning 'Kopiere Daten %.%',_schema, _nested_table;
			Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema, _nested_table,_schema, _nested_table,
					quote_literal(_conn), quote_literal(' where fileid in (select distinct id from files.soilsamplefiles'||
					' where farmid=' || _farmid|| ')'));

			if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _nested_table || '_id_seq') )
				then
				Execute 'select setval('|| quote_literal(_schema || '.' || _nested_table || '_id_seq') || 
				', (select max(id) from '|| _schema || '.' || _nested_table || ') +1);';	
			end if;
		end loop;


	-- ############# schema common ##############################
	-- Daten
	-- ##############################################################

	_schema:='common';
	
	FOREACH _table IN ARRAY array['basemap','userviews'] LOOP 
		raise warning 'Kopiere Daten %.%',_schema, _table;
		
		Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
				quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
		
		if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _table || '_id_seq') || 
			', (select max(id) from '|| _schema || '.' || _table || ') +1);';	
		end if;
		
		
	end loop;

	--nested tables
	_nested_table:='userlayers';
	raise warning 'Kopiere Daten %.%',_schema, _nested_table;
	Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema, _nested_table,_schema, _nested_table,
		quote_literal(_conn), quote_literal(' where viewid in (select distinct id from common.userviews'||
			' where farmid=' || _farmid|| ')'));
	if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _nested_table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _nested_table || '_id_seq') || 
		', (select max(id) from '|| _schema || '.' || _nested_table || ') +1);';	
	end if;

	--referenced tables from other schemas
	-- should be generated new

	/*
	_schema:='n';
	_nested_table:='napplicationconfig';
		raise warning 'Kopiere Daten %.%',_schema, _nested_table;
	Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema, _nested_table,_schema, _nested_table,
		quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
	if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _nested_table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _nested_table || '_id_seq') || 
		', (select max(id) from '|| _schema || '.' || _nested_table || ') +1);';	
	end if;
	
	_nested_table:='napplications';
	raise warning 'Kopiere Daten %.%',_schema, _nested_table;
	Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema, _nested_table,_schema, _nested_table,
		quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
	if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _nested_table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _nested_table || '_id_seq') || 
		', (select max(id) from '|| _schema || '.' || _nested_table || ') +1);';	
	end if;
	
*/
	-- ############# schema pp ##############################
	-- Daten
	-- ##############################################################

	_schema:='pp';
	
	FOREACH _table IN ARRAY array['grlogs','grlogheader','rast_grrec','rast_nuptake',
		'grraster','grbiraster','recraster'] LOOP 
		raise warning 'Kopiere Daten %.%',_schema, _table;
		
		Execute format('insert into %s.%s Select * from utils.link_%s_%s(%s,%s)',_schema,_table,_schema,_table,
				quote_literal(_conn), quote_literal(' where farmid=' || _farmid));
		
		if exists (select 0 from pg_class where relname = quote_literal( _schema ||'.'|| _table || '_id_seq') )
		then
		Execute 'select setval('|| quote_literal(_schema || '.' || _table || '_id_seq') || 
			', (select max(id) from '|| _schema || '.' || _table || ') +1);';	
		end if;
		
		
	end loop;

	
	return true;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION utils.replicatefarm(text, text, text, text, text, integer)
  OWNER TO dboperator;






