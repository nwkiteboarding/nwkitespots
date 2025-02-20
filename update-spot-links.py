import json
import xml.etree.ElementTree as ET
from sklearn.neighbors import NearestNeighbors
import numpy as np
import os
import shutil
from geopy import distance

stations_file_path = 'stations.json'
input_kml_file_path = '.\Original\Kiting spots\doc.kml'
output_kml_file_path = '.\Kiting spots\doc.kml'

ET.register_namespace('',"http://www.opengis.net/kml/2.2")
with open(input_kml_file_path, 'r', encoding='utf-8') as file:
    tree = ET.parse(file)

ns = {'':"http://www.opengis.net/kml/2.2"}
root = tree.getroot()
placemarks = root.findall('.//Placemark', ns)

with open(stations_file_path, 'r') as file:
    station_data = json.load(file)
    station_locations = []
    for station in station_data['stations']:
        station_locations.append([station['lat'], station['lng']])        

knn = NearestNeighbors(n_neighbors=1)
knn.fit(np.array(station_locations))

link_section_tag_end = "</spot-links>"
link_section_tag_start = "<spot-links>"

for placemark in placemarks:
    name_node = placemark.find("./name", ns)
    print(name_node.text)

    coordinates_node = placemark.find("./Point/coordinates", ns)
    if coordinates_node == None:
        continue

    description_node = placemark.find("./description", ns)
    if description_node == None:
        continue

    coordinates = coordinates_node.text.split(',')
    if len(coordinates) < 2:
        continue

    lon = float(coordinates[0])
    lat = float(coordinates[1])

    windy_link = f"https://www.windy.com/{lat}/{lon}/wind?{lat},{lon}"
    print(f"Windy: {windy_link}")

    distances, indices = knn.kneighbors(np.array([[lat, lon]]))
    nearest_station = station_data['stations'][indices[0][0]]
    distance_to_station = distance.distance((nearest_station['lat'], nearest_station['lng']), (lat, lon))
    print(f"Nearest tide prediction station: {nearest_station['name']}, {nearest_station['state']}, {distance_to_station.km}km away")
    
    links = [ windy_link ]
    if distance_to_station.km < 50:
        tide_link = f"https://tidesandcurrents.noaa.gov/noaatidepredictions.html?id={nearest_station["id"]}"
        links.append(tide_link)

    links_text = "<br>".join(links)

    try:
        index = description_node.text.index(link_section_tag_end)
        description_text = description_node.text[(index + len(link_section_tag_end)):]
        description_node.text = f"{link_section_tag_start}{links_text}{link_section_tag_end}{description_text}"
    except ValueError:
        description_node.text = f"{link_section_tag_start}{links_text}{link_section_tag_end}<br><br>{description_node.text}"

    #update style
    style_url_node = placemark.find("./styleUrl", ns)
    if style_url_node != None and style_url_node.text == "#icon-ci-1":
        style_url_node.text = "#icon-22"

tree.write(output_kml_file_path, encoding="UTF-8", xml_declaration=True)

layer_path = os.path.dirname(output_kml_file_path)
kmz_file_path = f"{layer_path}.kmz"
shutil.make_archive(kmz_file_path, 'zip', layer_path)
if os.path.exists(kmz_file_path):
    os.remove(kmz_file_path)
os.rename(f"{kmz_file_path}.zip", kmz_file_path)