#!/bin/bash

packageName="arcgis-to-geojson"
nodePrefix=$(npm config get prefix)
packagePrefix=$([ -d node_module ] && echo "./node_modules" || echo "$nodePrefix/lib/node_modules/")
jsonConvert="$packagePrefix/$packageName/node_modules/JSON.sh/JSON.sh -b"
geoJsonConvert="$packagePrefix/$packageName/node_modules/togeojson/togeojson" 
bbox="-1.0779650435980866E7,5920640.483498561,-1.0774611175588211E7,5922096.739715614"
foldersUrl="$1"
echo Starting...
echo Folders URL: $foldersUrl?f=json
mkdir -p services
curl -s "$foldersUrl?f=json" | $jsonConvert | 
    while read folder;do
        if [[ $folder =~ ^\[\"folders\",(.*)\].\"(.*)\"$ ]]; then
            folderName=${BASH_REMATCH[2]}
            servicesUrl="$foldersUrl/$folderName"
            echo Folder Name: $folderName
            echo $folderName Services URL: $servicesUrl
            lastName=""
            lastType=""
            lastStatus=0
            curl -s "$servicesUrl?f=json" | $jsonConvert |
            {
                echo Working on folder $folderName...
                while read service; do
                    if [[ $service =~ ^\[\"services\",([^,]*)(,\"(.*)\")?\].\"(.*)\"$ ]]; then
                        if [[ ${BASH_REMATCH[3]} == "name" ]]; then
                            lastName=${BASH_REMATCH[4]}
                        elif [[ ${BASH_REMATCH[3]} == "type" ]]; then
                                lastType=${BASH_REMATCH[4]}
                                queryString="?where=OBJECTID>0&geometryType=esriGeometryEnvelope&spatialRel=esriSpatialRelIntersects&returnGeometry=true&returnIdsOnly=false&returnCountOnly=false&returnZ=false&returnM=false&returnDistinctValues=false&returnTrueCurves=false&f=kmz"
                                serviceUrl="$1/$lastName/$lastType"
                                serviceFolder="services/$lastName"
                                serviceZipFile="$serviceFolder/google.kmz"
                                serviceKmlFile="$serviceFolder/google.kml"
                                serviceGeoJsonFile="$serviceFolder/shapefile.geojson"
                                echo -e URL: $serviceUrl/{layer}/query$queryString Type: $lastType
                                mkdir -p $serviceFolder
                            if [[ ${BASH_REMATCH[4]} == "MapServer" ]]; then
                                layer=0
                                lastStatus=0
                                while [[ $lastStatus == 0 ]]; do
                                    lastStatus=1
                                    echo Layer: $layer
                                    serviceGeoJsonFile="$serviceFolder/shapefile$layer.geojson"
                                    curl -s "$serviceUrl/$layer/query$queryString" > "$serviceZipFile"
                                    if [[ $? == 0 ]]; then
                                        unzip -p -q "$serviceZipFile" > "$serviceKmlFile"
                                        if [[ $? == 0 ]]; then
                                            $geoJsonConvert $serviceKmlFile > $serviceGeoJsonFile
                                            if [[ $? == 0 ]]; then
                                                lastStatus=0
                                                layer=$((layer+1))
                                            fi
                                        fi
                                    fi
                                done
                            else
                                echo Non Supported Type
                            fi
                        fi
                    fi
                done
                echo Finished with folder $folderName.
            }
        fi
    done
