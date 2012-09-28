SS.FlotChartView = Ember.View.extend
  series: []
  options: []

  didInsertElement: ->
    @seriesChanged()

  seriesChanged: (->
    @plot = $.plot @$(''), @get('series') || [], @get('options')
  ).observes 'series', 'options'
