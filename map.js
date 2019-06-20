var map = L.map('map', {
    zoom: 10,
    center: [37.620672, 55.756653],
    timeDimension: true,
    timeDimensionOptions: {
        timeInterval: "1935-01-01/2020-01-01",
        period: "P1M"
    },
    timeDimensionControl: true,
});

$.getJSON('/metro.json', function(data) {
    var layer = new L.StamenTileLayer("toner-lite");
    map.addLayer(layer);
    var geojson = L.geoJson(data, {
        style: function(feature) {
            return {
              "color": feature['properties']['color'],
              "weight": 6
            };
        }
    });
    map.fitBounds(geojson.getBounds());
    L.timeDimension.layer.geoJson(geojson, {
        duration: "P1M",
        updateTimeDimension: true,
        updateTimeDimensionMode: "replace"
    }).addTo(map);
  });
