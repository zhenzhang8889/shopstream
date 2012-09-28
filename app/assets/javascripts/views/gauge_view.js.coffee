SS.GaugeView = Ember.View.extend
  tagName: 'canvas'

  didInsertElement: ->
    @gauge = @$('').gauge().data().gauge
    @numberChanged()

  numberChanged: (->
    @gauge.maxValue = @get('maxNumber') || 0
    @gauge.set @get('number') || 0
  ).observes 'number', 'maxNumber'
