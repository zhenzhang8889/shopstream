SS.SettingsController = Ember.ObjectController.extend
  contentBinding: 'SS.router.shopController.content'
  
  save: ->
    @get('content.transaction').commit()
