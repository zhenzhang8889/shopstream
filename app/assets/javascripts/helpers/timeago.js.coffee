Ember.Handlebars.registerBoundHelper 'timeago', ->
  value = @get('value') || new Date
  new Handlebars.SafeString moment(value).fromNow()
