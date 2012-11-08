Ember.Handlebars.registerBoundHelper 'money', ->
  value = @get 'value'
  new Handlebars.SafeString accounting.formatMoney value, 2
