SS.HeaderView = Ember.View.extend
  templateName: 'header'
  classNames: ['contain-to-grid']
  tagName: 'header'

  didInsertElement: ->
    @$(window).foundationTopBar()
