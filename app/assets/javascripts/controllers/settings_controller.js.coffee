SS.SettingsController = Ember.ObjectController.extend
  contentBinding: 'SS.router.shopController.content'
  
  save: ->
    SS.store.commit()
