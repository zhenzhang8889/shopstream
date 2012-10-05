SS.AddShopController = Ember.Controller.extend
  shopTypes:
    [
      {type: 'shopify', name: 'Shopify Shop'},
      {type: 'custom', name: 'Custom Shop'}
    ]

  shop: null
  transaction: null

  isShopifyShopBinding: 'shop.isShopifyShop'
  isCustomShopBinding: 'shop.isCustomShop'
  isValidBinding: 'shop.isValid'

  redirectConnectShop: ->
    window.location = "/shops/connect?shop=#{@get('shop.domain')}"

  createShop: ->
    shop = @get('shop')
    shop.transaction.commit()
    shop.addObserver 'id', =>
      Ember.run.next ->
        SS.user.get('shops').pushObject shop
        SS.router.send 'goToSettings', shop
        
      @makeShop()

  init: ->
    @set 'transaction', SS.store.transaction()
    @makeShop()

    @_super()

  makeShop: ->
    @clearTransaction()

    @set 'shop', @get('transaction').createRecord(SS.Shop, type: 'shopify')

  clearTransaction: ->
    @get('transaction').destroy()
    @set 'transaction', SS.store.transaction()
