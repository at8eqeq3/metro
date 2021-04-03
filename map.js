var map = L.map('map', {
    zoom: 10,
    center: [37.620672, 55.756653],
    timeDimension: true,
    timeDimensionOptions: {
        timeInterval: "1935-01-01/2020-01-01",
        period: "P1M",
        currentTime: Date.parse("1935-01-01T00:00:00Z")
    },
    //timeDimensionControl: true,
    timeDimensionControlOptions: {
      minSpeed: 10,
      maxSpeed: 12,
      speedStep: 1
    }
});

L.Control.TimeDimensionCustom = L.Control.TimeDimension.extend({
  _getDisplayDateFormat: function(date){
      return date.toLocaleDateString(["ru", "en"]);
  }
});
var timeDimensionControl = new L.Control.TimeDimensionCustom({
  playerOptions: {
      buffer: 1,
      minBufferReady: -1
  },
  minSpeed: 10,
  maxSpeed: 12,
  speedStep: 1
});
map.addControl(this.timeDimensionControl);

var layer = new L.StamenTileLayer("toner-lite");
map.addLayer(layer);

$.getJSON('/metro.json', function(data) {
    var geojson = L.geoJson(data, {
        style: function(feature) {
            return {
              "color": feature.properties.color,
              "weight": 6
            };
        }
    });
    map.fitBounds(geojson.getBounds());
    L.timeDimension.layer.geoJson(geojson, {
        duration: "P1M",
        updateTimeDimension: true,
        updateTimeDimensionMode: "union"
    }).addTo(map);
  });

$.getJSON('/borders.json', function(data) {
    var geojson = L.geoJson(data, {
        style: function(feature) {
            return {
              "color": '#112233',
              "weight": 3
            };
        }
    });
    //map.fitBounds(geojson.getBounds());
    L.timeDimension.layer.geoJson(geojson, {
        duration: "P1Y",
        updateTimeDimension: true,
        updateTimeDimensionMode: "union"
    }).addTo(map);
  });
