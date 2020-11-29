-- Database: zad5
-- pg_dump -h localhost -p 5432 -U postgres -F c -b -v -f "C:\Users\Daria\Desktop\STUDIA\VSEMESTR\BDP\postgis_raster.backup" dem
-- DROP DATABASE zad5;
	create extension postgis_raster CASCADE;
	-- w cmd po dodaniu rozszerzenia i zrobieniu restore
	--  raster2pgsql -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\Daria\Desktop\STUDIA\VSEMESTR\BDP\cw5\rasters\srtm_1arc_v3.tif rasters.dem > C:\Users\Daria\Desktop\STUDIA\VSEMESTR\BDP\cw5\dem.sql
	-- 	raster2pgsql -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\Daria\Desktop\STUDIA\VSEMESTR\BDP\cw5\rasters\srtm_1arc_v3.tif rasters.dem | psql -d dem -h localhost -U postgres -p 5432
	-- raster2pgsql -s 3763 -N -32767 -t 100x100 -I -C -M -d C:\Users\Daria\Desktop\STUDIA\VSEMESTR\BDP\cw5\rasters\Landsat8_L1TP_RGBN.TIF rasters.landsat8 | psql -d dem -h localhost -U postgres -p 5432
	
	--Przykład 1
	
	CREATE TABLE dkawecka.intersects AS
	SELECT a.rast, b.municipality
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';
-- 	1.dodanie serial primary key:
	alter table dkawecka.intersects
	add column rid SERIAL PRIMARY KEY;
-- 	2.utworzenie indeksu przestrzennego:
	CREATE INDEX idx_intersects_rast_gist ON dkawecka.intersects
	USING gist (ST_ConvexHull(rast));
-- 	3.dodanie raster constraints:
	SELECT AddRasterConstraints('dkawecka'::name, 'intersects'::name,'rast'::name);
	
	--Przykład 2
	
	CREATE TABLE dkawecka.clip AS
	SELECT ST_Clip(a.rast, b.geom, true), b.municipality
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';
	
	--Przykład 3 -ST_Union Połączenie wielu kafelków w jeden raster.
	CREATE TABLE dkawecka.union AS
	SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);
	
	--Przykład 1-ST_AsRaster
	CREATE TABLE dkawecka.porto_parishes AS
	WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
	)
	SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
	FROM vectors.porto_parishes AS a, r
	WHERE a.municipality ilike 'porto';
	
	--Przyklad 2 - ST_Union
	DROP TABLE dkawecka.porto_parishes; --> drop table porto_parishes first
	CREATE TABLE dkawecka.porto_parishes AS
	WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
	)
	SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
	FROM vectors.porto_parishes AS a, r
	WHERE a.municipality ilike 'porto';
	
	--Przykład3 -ST_Tile
	DROP TABLE dkawecka.porto_parishes; --> drop table porto_parishes first
	CREATE TABLE dkawecka.porto_parishes AS
	WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1 )
	SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
	FROM vectors.porto_parishes AS a, r
	WHERE a.municipality ilike 'porto';
	
	--Przykład 1 -ST_Intersection
	create table dkawecka.intersection as
	SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);
	
	--Przykład 2 -ST_DumpAsPolygons
	CREATE TABLE dkawecka.dumppolygons AS
	SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);
	
	--Przykład 1 -ST_Band
	CREATE TABLE dkawecka.landsat_nir AS
	SELECT rid, ST_Band(rast,4) AS rast
	FROM rasters.landsat8;
	
	--Przykład 2 -ST_Clip
	CREATE TABLE dkawecka.paranhos_dem AS
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);
	
	--Przykład 3 -ST_Slope
	CREATE TABLE dkawecka.paranhos_slope AS
	SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
	FROM dkawecka.paranhos_dem AS a;
	
	--Przykład 4 -ST_Reclass
	CREATE TABLE dkawecka.paranhos_slope_reclass AS
	SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3', '32BF',0)
	FROM dkawecka.paranhos_slope AS a;
	
	--Przykład 5 -ST_SummaryStats 
	SELECT st_summarystats(a.rast) AS stats
	FROM dkawecka.paranhos_dem AS a;
	
	
	--Przykład 6 -ST_SummaryStats orazUnion
	SELECT st_summarystats(ST_Union(a.rast))
	FROM dkawecka.paranhos_dem AS a;
	
	--Przykład7 -ST_SummaryStats z lepszą kontrolą złożonego typu danych
	WITH t AS (
	SELECT st_summarystats(ST_Union(a.rast)) AS stats
	FROM dkawecka.paranhos_dem AS a
	)
	SELECT (stats).min,(stats).max,(stats).mean FROM t;
	
	--Przykład 8 -ST_SummaryStats w połączeniu z GROUP BY
	WITH t AS (
	SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast, b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	group by b.parish
	)
	SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;
	
	--Przykład 9 -ST_Value
	SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
	FROM
	rasters.dem a, vectors.places AS b
	WHERE ST_Intersects(a.rast,b.geom)
	ORDER BY b.name;
	
	--Przykład 10 -ST_TPI
	create table dkawecka.tpi30 as
	select ST_TPI(a.rast,1) as rast
	from rasters.dem a;
	
	CREATE INDEX idx_tpi30_rast_gist ON dkawecka.tpi30
	USING gist (ST_ConvexHull(rast));
	
	SELECT AddRasterConstraints('dkawecka'::name, 'tpi30'::name,'rast'::name);
	
	--Problem do samodzielnego rozwiązania:
	CREATE TABLE dkawecka.tpi30_porto as
	SELECT ST_TPI(a.rast,1) as rast
	FROM rasters.dem a, vectors.porto_parishes AS b WHERE  ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';
	
	CREATE INDEX idx_tpi30_porto_rast_gist ON dkawecka.tpi30_porto
	USING gist (ST_ConvexHull(rast));
	
	SELECT AddRasterConstraints('dkawecka'::name, 'tpi30_porto'::name,'rast'::name);
	
	--Przykład 1 - Wyrażenie Algebry Map
	
	CREATE TABLE dkawecka.porto_ndvi AS
	WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	)
	SELECT
	r.rid,ST_MapAlgebra(
	r.rast, 1,
	r.rast, 4,
	'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF'
	) AS rast
	FROM r;
	
	CREATE INDEX idx_porto_ndvi_rast_gist ON dkawecka.porto_ndvi
	USING gist (ST_ConvexHull(rast));
	
	SELECT AddRasterConstraints('dkawecka'::name, 'porto_ndvi'::name,'rast'::name);
	
	--Przykład2 – Funkcja zwrotna
	create or replace function dkawecka.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
	)
	RETURNS double precision AS
	$$
	BEGIN
	--
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value [1][1][1]); --> NDVI calculation!
	END;
	$$
	LANGUAGE 'plpgsql' IMMUTABLE COST 1000;
	
	CREATE TABLE dkawecka.porto_ndvi2 AS
	WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	)
	SELECT
	r.rid,ST_MapAlgebra(
	r.rast, ARRAY[1,4],
	'dkawecka.ndvi(double precision[], integer[],text[])'::regprocedure, --> This is the function!
	'32BF'::text
	) AS rast
	FROM r;
	
	CREATE INDEX idx_porto_ndvi2_rast_gist ON dkawecka.porto_ndvi2
	USING gist (ST_ConvexHull(rast));
	
	SELECT AddRasterConstraints('dkawecka'::name, 'porto_ndvi2'::name,'rast'::name);
	
	
	--Przykład 1 - ST_AsTiff
	
	SELECT ST_AsTiff(ST_Union(rast))
	FROM dkawecka.porto_ndvi;
	
	SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
	FROM dkawecka.porto_ndvi;
	
	--Przykład 2 -ST_AsGDALRaster
	SELECT ST_GDALDrivers();
	--Przykład 3 -Zapisywanie danych na dysku za pomocą dużego obiektu (large object, lo)
	CREATE TABLE tmp_out AS
	SELECT lo_from_bytea(0,
	ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
	) AS loid
	FROM dkawecka.porto_ndvi;
	--
	SELECT lo_export(loid, 'C:\myraster.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
	FROM tmp_out;
	-- 
	SELECT lo_unlink(loid)
	FROM tmp_out; --> Delete the large object.
	
	--Przykład 4 - Użycie Gdal
	gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 PG:"host=localhost port=5432 dbname=zad5 user=postgres 
	password=1234 schema=dkawecka table=porto_ndvi mode=2" porto_ndvi.tiff
	
	
	



	
	
	