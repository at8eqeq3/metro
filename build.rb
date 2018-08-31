require 'yaml'
require 'rvg/rvg'
include Magick

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
    draw_coords << geo_to_px(coords)
  end
  section['draw_coords'] = draw_coords.flatten
end

SECTIONS.each do |section|
  puts section['draw_coords']
end

RVG::dpi = 300
rvg = RVG.new(WIDTH.px, HEIGHT.px).viewbox(0, 0, WIDTH, HEIGHT) do |canvas|
  canvas.background_fill = 'white'
  canvas.g do |drw|
    STATIONS.each do |s|
      x, y = geo_to_px(s['coords'])
      drw.circle(4, x, y).styles(fill: '#' + LINES[s['lines'][0]['name']]['color'])
    end
  end
  canvas.g do |drw|
    SECTIONS.each do |s|
      drw.polyline(s['draw_coords']).styles(stroke: '#' + LINES[s['line']]['color'], fill: 'none')
    end
  end
end

rvg.draw.write('metro.png')
