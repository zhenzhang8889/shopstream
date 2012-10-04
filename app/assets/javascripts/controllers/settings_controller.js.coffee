SS.SettingsController = Ember.ObjectController.extend
  contentBinding: 'SS.router.shopController.content'
  
  save: ->
    @get('content.transaction').commit()

  deleteShop: ->
    transaction = @get('content.transaction')
    @get('content').deleteRecord()
    transaction.commit()
    setTimeout ->
      SS.router.send 'goToIndex'
      location.reload()
    , 1000
