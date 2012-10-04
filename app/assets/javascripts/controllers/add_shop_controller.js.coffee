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
    @get('shop').transaction.commit()
    @get('shop').addObserver 'id', =>
      location.reload()

  init: ->
    @_super()

    @set 'transaction', SS.store.transaction()
    @makeShop()

  makeShop: ->
    @clearTransaction()

    @set 'shop', @get('transaction').createRecord(SS.Shop, type: 'shopify')

  clearTransaction: ->
    @get('transaction').rollback()
