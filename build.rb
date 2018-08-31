require 'yaml'
#require 'rvg/rvg'
#include Magick
require 'victor'
include Victor

STATIONS = YAML.load(File.open('stations.yaml', 'r').read)
LINES    = YAML.load(File.open('lines.yaml', 'r').read)
SECTIONS = YAML.load(File.open('sections.yaml', 'r').read)
MARGIN = 40 # margin from outer points to image border

START_DATE = '1935-01-01'
END_DATE   = '2018-12-31'

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

SECTIONS.each do |section|
  draw_coords = []
  section['coords'].split(',').each_slice(2) do |pair|
    coords = {'lat' => pair[0].to_f, 'lon' => pair[1].to_f}
    draw_coords << geo_to_px(coords).join(',')
  end
  section['draw_coords'] = draw_coords.join(' ')
end

SECTIONS.each do |section|
  puts section['draw_coords']
end

svg = Victor::SVG.new width: WIDTH, height: HEIGHT

svg.build do
  STATIONS.each do |s|
    x, y = geo_to_px(s['coords'])
    circle cx: x, cy: y, r: 4, fill: '#' + LINES[s['lines'][0]['name']]['color']
  end
  SECTIONS.each do |s|
    polyline points: s['draw_coords'], stroke: '#' + LINES[s['line']]['color'], fill: 'none'
  end
end

svg.save 'metro'
