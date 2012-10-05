SS.SettingsController = Ember.ObjectController.extend
  contentBinding: 'SS.router.shopController.content'
  
  save: ->
    @get('content.transaction').commit()

  deleteShop: ->
    transaction = @get('content.transaction')
    shop = @get('content')
    SS.user.get('shops').removeObject shop
    shop.deleteRecord()
    transaction.commit()
    SS.router.send 'goToIndex'
