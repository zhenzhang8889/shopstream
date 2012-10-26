Ember.Handlebars.registerBoundHelper 'number', ->
  value = @get 'value'
  new Handlebars.SafeString accounting.formatNumber value
