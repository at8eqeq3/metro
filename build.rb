require 'yaml'
require 'date'
#require 'rvg/rvg'
#include Magick
require 'victor'
include Victor

STATIONS = YAML.load(File.open('stations.yaml', 'r').read)
LINES    = YAML.load(File.open('lines.yaml', 'r').read)
SECTIONS = YAML.load(File.open('sections.yaml', 'r').read)
MARGIN = 40 # margin from outer points to image border

START_DATE = Date.new(1935, 01, 01)
END_DATE   = Date.new(2018, 12, 31)

Y_MIN = STATIONS.map{|station| station['coords']['lat']}.min.to_f.round(4) * 10000
Y_MAX = STATIONS.map{|station| station['coords']['lat']}.max.to_f.round(4) * 10000
X_MIN = STATIONS.map{|station| station['coords']['lon']}.min.to_f.round(4) * 10000
X_MAX = STATIONS.map{|station| station['coords']['lon']}.max.to_f.round(4) * 10000
WIDTH  = (X_MAX - X_MIN).round(0) + 2 * MARGIN
HEIGHT = (Y_MAX - Y_MIN).round(0) + 2 * MARGIN

def geo_to_px(coords)
  y = HEIGHT - (coords['lat'] * 10000 - Y_MIN + MARGIN).round(0)
  x = (coords['lon'] * 10000 - X_MIN + MARGIN).round(0)
  return [x, y]
end

# saturating stations data with omitted values
STATIONS.each do |station|
  # dates of existence
  station['dates'].each do |dt|
    #y, m, d = dt['since'].split('-')
    #dt['since'] = Date.new(y, m, d)
    if dt.has_key? 'to'
    #  y, m, d = dt['to'].split('-')
    #  dt['to'] = Date.new(y, m, d)
    else
      dt['to'] = END_DATE
    end
  end
  # line belongings
  station['lines'].each do |ln|
    if ln.has_key? 'since'
    #  y, m, d = ln['since'].split('-')
    #  ln['since'] = Date.new(y, m, d)
    else
      ln['since'] = station['dates'][0]['since']
    end
    if ln.has_key? 'to'
    #  y, m, d = ln['to'].split('-')
    #  ln['to'] = Date.new(y, m, d)
    else
      ln['to'] = station['dates'][-1]['to']
    end
  end
end

# saturating sections data with omitted values
SECTIONS.each do |section|
  unless section.has_key? 'to'
    section['to'] = END_DATE
  end
end

SECTIONS.each do |section|
  draw_coords = []
  section['coords'].split(',').each_slice(2) do |pair|
    coords = {'lat' => pair[0].to_f, 'lon' => pair[1].to_f}
    draw_coords << geo_to_px(coords).join(',')
  end
  section['draw_coords'] = draw_coords.join(' ')
end

# cycle through dates and make images
current_date = START_DATE
while current_date <= END_DATE do
  puts current_date

  svg = Victor::SVG.new width: WIDTH, height: HEIGHT

  svg.build do
    STATIONS.each do |s|
      exists = false
      s['dates'].each do |dt|
        if dt['since'] <= current_date && dt['to'] >= current_date
          exists = true
        end
      end
      if exists
        x, y = geo_to_px(s['coords'])
        circle cx: x, cy: y, r: 4, fill: '#' + LINES[s['lines'][0]['name']]['color']
      end
    end
    SECTIONS.each do |s|
      if s['since'] <= current_date && s['to'] >= current_date
        polyline points: s['draw_coords'], stroke: '#' + LINES[s['line']]['color'], fill: 'none'
      end
    end
  end

  svg.save current_date.strftime 'svg/metro-%Y-%m'
  
  current_date = current_date >> 1
end

