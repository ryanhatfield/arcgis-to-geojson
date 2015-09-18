# Convert ArcGIS service endpoints to GeoJSON files

## Installation

Assuming you have Node.js installed, you can install with NPM

```npm install -g arcgis-to-geojson```

## Usage

```arcGisToJSON http://gis.cityoffargo.com/arcgis/rest/services```

Running the above command will result in the following folder structure:

```
./services/{folder name}/{service name}/google.kmz (zip file)
./services/{folder name}/{service name}/google.kml (google shape file)
./services/{folder name}/{service name}/shapefile.geojson (open format GeoJSON file)
```

## License

[MIT](https://github.com/RyanHatfield/arcgis-to-geojson/master/LICENSE.md)
