SELECT row_to_json(fc)
 FROM
  ( SELECT 'FeatureCollection' As type, array_to_json(array_agg(f)) As features
  FROM (SELECT 'Feature' As type,
      ST_AsGeoJSON(ST_Transform(ST_simplify(lg.way, 1000), 4326))::json As geometry,
          (
	          select row_to_json(t) from (select smoothness, highway, surface_survey, ref) t
	   ) AS properties
			     FROM planet_osm_roads As lg WHERE lg.smoothness is not null and not(lg.highway in ('trunk', 'motorway')) and lg.highway is not null
   ) As f
)  As fc;
			     


