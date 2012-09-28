Ember.Handlebars.registerBoundHelper 'percentage', ->
  value = @get 'value'
  new Handlebars.SafeString "#{accounting.formatNumber value}%"
