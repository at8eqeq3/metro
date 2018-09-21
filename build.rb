require 'yaml'
require 'date'
#require 'rvg/rvg'
#include Magick
require 'victor'
include Victor

STATIONS = YAML.load(File.open('stations2.yaml', 'r').read)
LINES    = YAML.load(File.open('lines.yaml', 'r').read)
SECTIONS = YAML.load(File.open('sections2.yaml', 'r').read)
MARGIN = 40 # margin from outer points to image border

START_DATE = Date.new(1935, 01, 01)
END_DATE   = Date.new(2018, 12, 31)

Y_MIN = STATIONS.map{|station| station['coords']['lat'] * 1.76}.min.to_f.round(4) * 10000
Y_MAX = STATIONS.map{|station| station['coords']['lat'] * 1.76}.max.to_f.round(4) * 10000
X_MIN = STATIONS.map{|station| station['coords']['lon']}.min.to_f.round(4) * 10000
X_MAX = STATIONS.map{|station| station['coords']['lon']}.max.to_f.round(4) * 10000
WIDTH  = (X_MAX - X_MIN).round(0) + 2 * MARGIN
HEIGHT = (Y_MAX - Y_MIN).round(0) + 2 * MARGIN

def geo_to_px(coords)
  y = HEIGHT - (coords['lat'] * 17600 - Y_MIN + MARGIN).round(0)
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
    rect x: 0, y: 0, width: WIDTH, height: HEIGHT, fill: '#fafafa'
    text current_date.to_s, font_size: 120, font_family: 'arial', font_weight: 'bold', x: 64, y: 200
    
    SECTIONS.each do |s|
      str_width = 8
      s_since = Date.new(s['since'].year, s['since'].month, 1)
      s_to = Date.new(s['to'].year, s['to'].month, 1)
      if s_since == current_date
        str_width = 12
      end
      if s_since <= current_date && s_to >= current_date
        polyline points: s['draw_coords'], stroke: '#' + LINES[s['line']]['color'], fill: 'none', stroke_width: str_width
      end
    end
    
    stations_count = 0
    
    STATIONS.each do |s|
      exists = false
      radius = 16
      s['dates'].each do |dt|
        #puts dt['since'].year
        #puts current_date.year
        dt_since = Date.new(dt['since'].year, dt['since'].month, 1)
        dt_to = Date.new(dt['to'].year, dt['to'].month, 1)
        if dt_since == current_date
#          puts "hit!"
          radius = 24
        end
        if dt_since <= current_date && dt_to >= current_date
          exists = true
        end
      end
#      puts radius if radius > 16
      if exists
        stations_count +=1
        color = ''
        s['lines'].each do |line|
          line_since = Date.new(line['since'].year, line['since'].month, 1)
          line_to = Date.new(line['to'].year, line['to'].month, 1)
          if line_since == current_date
            radius = 24
          end
          if line_since <= current_date && line_to >= current_date
            color = LINES[line['name']]['color']
          end
        end
        x, y = geo_to_px(s['coords'])
        circle cx: x, cy: y, r: radius, fill: '#' + color.to_s
      end
    end
    
    text stations_count.to_s, font_size: 240, font_family: 'arial', font_weight: 'bold', x: 64, y: 400
    
  end

  svg.save current_date.strftime 'svg/metro-%Y-%m'
  
  current_date = current_date >> 1
end

