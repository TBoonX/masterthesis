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
