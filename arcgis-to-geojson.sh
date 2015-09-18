#!/bin/bash

nodePrefix=$(npm config get prefix)
jsonConvert="$nodePrefix/lib/node_modules/JSON.sh/JSON.sh -b"
geoJsonConvert="$nodePrefix/lib/node_modules/togeojson/togeojson" 
foldersUrl="$1"

mkdir -p services
curl -s $foldersUrl?f=json | $jsonConvert | 
    while read folder;do
        if [[ $folder =~ ^\[\"folders\",(.*)\].\"(.*)\"$ ]]; then
            folderName=${BASH_REMATCH[2]}
            servicesUrl="$foldersUrl/$folderName"
            #echo Folder Name: $folderName
            #echo $folderName Services URL: $servicesUrl
            lastName=""
            lastType=""
            curl -s "$servicesUrl?f=json" | $jsonConvert |
            {
                echo Working on folder $folderName...
                while read service; do
                    if [[ $service =~ ^\[\"services\",([^,]*)(,\"(.*)\")?\].\"(.*)\"$ ]]; then
                        if [[ ${BASH_REMATCH[3]} == "name" ]]; then
                            lastName=${BASH_REMATCH[4]}
                        elif [[ ${BASH_REMATCH[3]} == "type" && ${BASH_REMATCH[4]} == "MapServer" ]]; then
                            lastType=${BASH_REMATCH[4]}
                            serviceUrl="$1/$lastName/$lastType"
                            serviceFolder="services/$lastName/$lastType"
                            serviceZipFile="$serviceFolder/google.kmz"
                            serviceKmlFile="$serviceFolder/google.kml"
                            serviceGeoJsonFile="$serviceFolder/shapefile.geojson"
                            echo URL: $serviceUrl Type: $lastType
                            mkdir -p $serviceFolder
                            curl -s "$serviceUrl?f=KMZ" > "$serviceZipFile"
                            unzip -p "$serviceZipFile" > "$serviceKmlFile"
                            $geoJsonConvert $serviceKmlFile > $serviceGeoJsonFile
                        fi
                    fi
                done
                echo Finished with folder $folderName.
            }
        fi
    done
