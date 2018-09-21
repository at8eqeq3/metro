from PIL import Image, ImageDraw
import yaml
from datetime import date, timedelta

stations_str = file('stations.yaml', 'r')
lines_str = file('lines.yaml', 'r')
sections_str = file('sections.yaml', 'r')

stations = yaml.load(stations_str)
lines    = yaml.load(lines_str)
sections = yaml.load(sections_str)

margin = 40

start_date = date(1935, 01, 01)
end_date = date(2019, 01, 01)

y_min = round(float(min(list(map(lambda station: station['coords']['lat'], stations)))), 4) * 10000
y_max = round(float(max(list(map(lambda station: station['coords']['lat'], stations)))), 4) * 10000
x_min = round(float(min(list(map(lambda station: station['coords']['lon'], stations)))), 4) * 10000
x_max = round(float(max(list(map(lambda station: station['coords']['lon'], stations)))), 4) * 10000

width = round(x_max - x_min) + 2 * margin
height = round(y_max - y_min) + 2 * margin

def geo_to_px(coords):
  y = round(height - (coords['lat'] * 10000 - y_min + margin))
  x = round(coords['lon'] * 10000 - x_min + margin)
  return [x, y]
  
for station in stations:
  for dt in station['dates']:
    if not 'to' in dt:
      dt['to'] = end_date
  for ln in station['lines']:
    if not 'since' in ln:
      ln['since'] = station['dates'][0]['since']
    if not 'to' in ln:
      ln['to'] = station['dates'][-1]['to']

for section in sections:
  if not 'to' in section:
    section['to'] = end_date

current_date = start_date

