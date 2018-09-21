require 'nokogiri'
require 'open-uri'
require 'yaml'

stations = []

months = {
  'января'   => '01',
  'февраля'  => '02',
  'марта'    => '03',
  'апреля'   => '04',
  'мая'      => '05',
  'июня'     => '06',
  'июля'     => '07',
  'августа'  => '08',
  'сентября' => '09',
  'октября'  => '10',
  'ноября'   => '11',
  'декабря'  => '12'
}

page = Nokogiri::HTML(open("https://ru.wikipedia.org/wiki/%D0%A1%D0%BF%D0%B8%D1%81%D0%BE%D0%BA_%D1%81%D1%82%D0%B0%D0%BD%D1%86%D0%B8%D0%B9_%D0%9C%D0%BE%D1%81%D0%BA%D0%BE%D0%B2%D1%81%D0%BA%D0%BE%D0%B3%D0%BE_%D0%BC%D0%B5%D1%82%D1%80%D0%BE%D0%BF%D0%BE%D0%BB%D0%B8%D1%82%D0%B5%D0%BD%D0%B0"))

table = page.css('table.sortable')[0]

table.css('tr')[1..-1].each do |row|
  station = {}
  name = row.css('td')[1].children[0].text
  date_raw = row.css('td')[2].text
  d, m, y = date_raw.strip.split(' ')
  month = months[m]
  date = y + '-' + month + '-' + d.rjust(2, '0')
  line = row.css('td')[0].css('span')[1]['title']
  coords = row.css('td')[6].css('span')[0]['data-param'].split '_'
  station['name'] = name
  station['dates'] = []
  station['dates'][0] = {}
  station['dates'][0]['since'] = date
  station['lines'] = []
  station['lines'][0] = {}
  station['lines'][0]['name'] = line
  station['coords'] = {}
  station['coords']['lat'] = coords[0].to_f
  station['coords']['lon'] = coords[2].to_f
  stations << station
end

puts stations.to_yaml
