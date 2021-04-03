require 'json'
require 'date'

$wrap = {}
$wrap['type'] = 'FeatureCollection'
$wrap['features'] = []

$outfile = File.new('borders.json', 'w')
$outfile.puts '{"type": "FeatureCollection", "features": ['

R          = 6378137
R_MINOR    = 6356752.314245179
START_DATE = Date.new(1935, 1, 1)
END_DATE   = Date.new(2038, 2, 1)
### translated from LeafletJS
def unproject(coords)
  d = 180 / Math::PI
  r = R
  tmp = R_MINOR / r
  e = Math.sqrt(1 - tmp * tmp)
  ts = Math.exp(-coords[1].to_f / r)
  phi = Math::PI / 2 - 2 * Math.atan(ts)
  i = 0
  dphi = 0.1
  con = nil
  while i < 15 && dphi.abs > 1e-7 do
    con = e * Math.sin(phi)
    con = ((1 - con) / (1 + con)) ** (e / 2)
    dphi = Math::PI / 2 - 2 * Math.atan(ts * con) - phi
    phi += dphi
    i += 1
  end
  return [(coords[0].to_f * d / r).round(4), (phi * d).round(4)]
end

def convert_coords(coords)
  coords.map!{ |c|
    if (c.is_a? Array) && (c.length == 2) && !(c[0].is_a? Array)
      c = unproject(c)
    else
      c = convert_coords(c.reverse)
    end
  }
  return coords
end

def add_times(feature)
  date_min = Date.new(feature['properties']['date_min'].to_i, 1, 1)
  date_max = Date.new(feature['properties']['date_max'].to_i, 1, 1)
  if date_max < START_DATE || date_min > END_DATE
    return nil
  end
  feature.delete 'id'
  feature['type'] = 'Feature'
  coords = convert_coords(feature['geometry']['coordinates'])
  feature['geometry']['type'] = 'MultiPolygon'
  feature['geometry']['coordinates'] = []
  feature['properties'] = {}
  feature['properties']['interval'] = [date_min, date_max].join(' -- ')
  feature['properties']['times'] = []
  date_min = START_DATE if date_min < START_DATE
  date_max = END_DATE   if date_max > END_DATE
  while date_min <= date_max do
    feature['geometry']['coordinates'] << coords
    feature['properties']['times'] << date_min.to_s
    date_min = date_min >> 12
  end
  puts feature['properties']['interval'] + ': ' + feature['geometry']['coordinates'].join(',') + "\n\n\n"
  $outfile.puts feature.to_json(indent: '  ', space: ' ', object_nl: "\n", array_nl: "\n")
  $outfile.puts ",\n"
  $wrap['features'] << feature
  return feature
end

raw = JSON.parse(File.read('borders.geojson'))


#polygon = []
raw.each do |f|
  t = nil
  date_min = Date.new(f['properties']['date_min'].to_i, 1, 1)
  date_max = Date.new(f['properties']['date_max'].to_i, 1, 1)
  if date_max < START_DATE || date_min > END_DATE
    next
  end
  if f['geometry']['type'].strip.casecmp('multipolygon').zero?
    f['geometry']['coordinates'].each do |geometry|
      new_feature = f.clone
      new_feature['geometry']['type'] = 'Polygon'
      new_feature['geometry'].delete 'coordinates'
      new_feature['geometry']['coordinates'] = geometry
      t = add_times(new_feature)
      #polygon.push(t.clone) unless t.nil?
    end
  else
    t = add_times(f)
    #polygon.push(t.clone) unless t.nil?
  end
  #puts t
end
#wrap['features'] = polygon
#polygon.each do |f|
#  puts f['geometry']['coordinates'].join(',') + "\n\n\n"
#end
#puts polygon.to_json(indent: '  ', space: ' ', object_nl: "\n", array_nl: "\n")

#wrap['features'].each do |f|
#  puts f['geometry']['coordinates'].join(',') + "\n\n\n"
#end
#outfile.puts JSON.generate($wrap, indent: '  ', space: ' ', object_nl: "\n", array_nl: "\n")
$outfile.puts "{}]}"
