class App.Views.ConferenceMap extends Backbone.View
  className: 'map-panel hidden-xs'
  template: JST["templates/conference_map"]
  infoWindowTemplate: JST["templates/conference_info_window"]

  initialize: (options) ->
    _.extend this, options

    @listenTo @conferences, 'reset filter-complete', @addConferenceMarkers

  render: ->
    @$el.html @template
    @ignoreFirstBoundsChange = true
    @map = new GMaps(
      _.extend(
        el: @$('.map')[0],
        dragend: @boundsChanged,
        zoom_changed: @boundsChanged,
        scrollwheel: false,
        @defaultCoordinates
      )
    )

    @addConferenceMarkers()

    this

  minZoomOffset: 0.5 # offset to lat/lng bounds when there is only 1 marker

  defaultCoordinates:
    zoom: 4,
    lat:   38.8722838,
    lng: -457.9752401,

  addConferenceMarkers: ->
    if @map
      @map.removeMarkers()
      markers = @conferences.chain().
        filter(@withLatLng).map(@conferenceMarkerFor).value()

      unless _.isEmpty(markers)
        @map.addMarkers markers
        unless @dontAutoZoom
          @ignoreBoundsChange = true
          @map.fitLatLngBounds @latLngForBounds(markers)
          @ignoreBoundsChange = false

  withLatLng: (conference) =>
    conference.hasLatLng()

  conferenceMarkerFor: (conference, index) =>
    lat: conference.get('latitude'),
    lng: conference.get('longitude'),
    title: conference.get('title'),
    animation: 'DROP',
    icon: googleMapIconForIndex(index)
    click: @bringMarkerToFront
    infoWindow:
      content: @infoWindowTemplate(conference.attributes)

  bringMarkerToFront: (marker) =>
    marker.setZIndex google.maps.Marker.MAX_ZINDEX + @nextZIndex()

  nextZIndex: ->
    @zindex ||= 1
    @zindex += 1

  latLngForBounds: (markers) ->
    latLng = _.map(markers, @markerToLatLng)
    if latLng.length == 1
      m = markers[0]
      # append two more coordinates to prevent zooming in too close with only one marker
      latLng.push new google.maps.LatLng(m.lat + @minZoomOffset, m.lng + @minZoomOffset)
      latLng.push new google.maps.LatLng(m.lat - @minZoomOffset, m.lng - @minZoomOffset)
    latLng

  markerToLatLng: (marker) ->
    new google.maps.LatLng(marker.lat, marker.lng)

  latLngToLiteral: (latLng) ->
    { lat: latLng.lat(), lng: latLng.lng() }

  boundsChanged: =>
    unless @ignoreBoundsChange || @ignoreFirstBoundsChange
      @dontAutoZoom = true
      @trigger 'change:bounds', @map.map.getBounds()
      @dontAutoZoom = false

    @ignoreFirstBoundsChange = false

  popupMarker: (index) ->
    # Simulate click
    google.maps.event.trigger(@map.markers[index], 'click')
