SS.AnimatedNumbersView = Ember.View.extend
  oldValue: 0
  animatedValue: 0

  didInsertElement: ->
    @numberChanged()

  numberChanged: (->
    _this = @

    $({value: @get('oldValue')}).animate {value: @get('value')}
      duration: 1050
      easing: 'easeInCubic'
      step: ->
        _this.set 'animatedValue', @value
      complete: =>
        @set 'animatedValue', @get('value')

    # Reset old value
    @set 'oldValue', @get('value')
  ).observes 'value'
