import os
import shutil

output_kml_file_path = '.\Kiting spots\doc.kml'

layer_path = os.path.dirname(output_kml_file_path)
kmz_file_path = f"{layer_path}.kmz"
shutil.make_archive(kmz_file_path, 'zip', layer_path)
if os.path.exists(kmz_file_path):
    os.remove(kmz_file_path)
os.rename(f"{kmz_file_path}.zip", kmz_file_path)