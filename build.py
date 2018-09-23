from PIL import Image, ImageDraw, ImageFont
import yaml
from datetime import date, timedelta
from dateutil.relativedelta import *
import locale

#locale.setlocale(locale.LC_ALL, 'ru_RU')

stations_str = file('stations2.yaml', 'r')
lines_str = file('lines.yaml', 'r')
sections_str = file('sections2.yaml', 'r')

stations = yaml.load(stations_str)
lines    = yaml.load(lines_str)
sections = yaml.load(sections_str)

margin = 40

font_120 = ImageFont.truetype('FreeSans.ttf', 120)
font_240 = ImageFont.truetype('FreeSans.ttf', 240)

#start_date = date(1935, 01, 01)
start_date = date(2019, 7, 01)
end_date = date(2020, 01, 01)

y_min = int(round(float(min(list(map(lambda station: station['coords']['lat'] * 1.76, stations)))), 4) * 10000)
y_max = int(round(float(max(list(map(lambda station: station['coords']['lat'] * 1.76, stations)))), 4) * 10000)
x_min = int(round(float(min(list(map(lambda station: station['coords']['lon'], stations)))), 4) * 10000)
x_max = int(round(float(max(list(map(lambda station: station['coords']['lon'], stations)))), 4) * 10000)



width = int(round(x_max - x_min) + 2 * margin)
height = int(round(y_max - y_min) + 2 * margin)

print(width)
print(height)

def geo_to_px(lat, lon):
  y = int(round(height - (lat * 17600 - y_min + margin)))
  x = int(round(lon * 10000 - x_min + margin))
  return [x, y]
  
def cr_to_xyxy(c, r):
  x1 = c[0] - r/2
  x2 = c[0] + r/2
  y1 = c[1] - r/2
  y2 = c[1] + r/2
  return [x1, y1, x2, y2]
  
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
  draw_coords = []
  coords = section['coords'].split(',')
  for lat, lon in zip(coords[::2], coords[1::2]):
    xy = geo_to_px(float(lat), float(lon))
    draw_coords.append(xy[0])
    draw_coords.append(xy[1])
  section['draw_coords'] = draw_coords
  if not 'to' in section:
    section['to'] = end_date
  

current_date = start_date

while current_date <= end_date:
  print(current_date)
  
  frame = Image.new("RGB", (width, height), "white")
  draw = ImageDraw.Draw(frame)
  
  draw.text((64, 200), unicode(current_date.strftime('%Y %B'),'cp1251'), font = font_120, fill = "black")
  
  for section in sections:
    str_width = 8
    s_since = date(section['since'].year, section['since'].month, 1)
    s_to = date(section['to'].year, section['to'].month, 1)
    if s_since == current_date:
      str_width = 12
    if s_since <= current_date and current_date < s_to:
      draw.line(xy=section['draw_coords'], fill="#" + str(lines[section['line']]['color']), width=str_width)
  
  stations_count = 0
  
  for station in stations:
    exists = False
    radius = 16
    for dt in station['dates']:
      dt_since = date(dt['since'].year, dt['since'].month, 1)
      dt_to = date(dt['to'].year, dt['to'].month, 1)
      if dt_since == current_date:
        radius = 24
      if dt_since <= current_date and current_date < dt_to:
        exists = True
    if exists == True:
      stations_count +=1
      color = ''
      for line in station['lines']:
        line_since = date(line['since'].year, line['since'].month, 1)
        line_to = date(line['to'].year, line['to'].month, 1)
        if line_since == current_date:
          radius = 24
        if relativedelta(current_date, line_since).months < 10 and relativedelta(current_date, line_since).years == 0:
          circle_radius = (relativedelta(current_date, line_since).months + 3) * 8
          color = "#" + str(lines[line['name']]['color'])
          draw.ellipse(xy=cr_to_xyxy(geo_to_px(station['coords']['lat'], station['coords']['lon']), circle_radius), outline=color)
        if line_since <= current_date and current_date < line_to:
          color = "#" + str(lines[line['name']]['color'])
      draw.ellipse(xy=cr_to_xyxy(geo_to_px(station['coords']['lat'], station['coords']['lon']), radius), outline=color, fill=color)

  
  draw.text((64, 400), str(stations_count), font = font_240, fill = "black")
  
  frame = frame.resize(size=(width/2, height/2), resample=Image.LANCZOS)
  
  frame.save(current_date.strftime("png/metro-%Y-%m.png"))
  
  current_date.strftime("png/metro-%Y-%m.png")
  
  current_date = current_date + relativedelta(months = +1)


