require 'yaml'
require 'json'

lines    = YAML.load(File.read('lines.yaml'))
stations = YAML.load(File.read('stations2.yaml'))
sections = YAML.load(File.read('sections2.yaml'))

out = File.new('metro.json', 'w')

data = {}
data['type'] = 'FeatureCollection'
data['features'] = []

START_DATE = Date.new(1935, 01, 01)
END_DATE   = Date.new(2020, 12, 31)

sections.each do |section|
    section['to']    = END_DATE   unless section.key? 'to'
    section['since'] = START_DATE unless section.key? 'since'
    
    s_since = Date.new(section['since'].year, section['since'].month, 1)
    s_to    = Date.new(section['to'].year,    section['to'].month, 1)
    
    feature = {}
    feature['type'] = 'Feature'
    feature['geometry'] = {}
    feature['geometry']['type'] = 'MultiLineString'
    feature['geometry']['coordinates'] = []
    feature['properties'] = {}
    feature['properties']['color'] = '#' + lines[section['line']]['color'].to_s
    feature['properties']['stroke'] = '#' + lines[section['line']]['color'].to_s
    feature['properties']['times'] = []
    
    coords = []
    section['coords'].split(',').each_slice(2) do |pair|
        coords << [pair[1].to_f, pair[0].to_f]
    end
    
    while s_since <= s_to do
        feature['geometry']['coordinates'] << coords
        feature['properties']['times'] << s_since.to_s
        s_since = s_since >> 1
    end
    
    data['features'] << feature
end

out.puts data.to_json
