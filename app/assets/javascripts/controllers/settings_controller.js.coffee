SS.SettingsController = Ember.ObjectController.extend
  contentBinding: 'SS.shop'

  save: ->
    SS.store.commit()
