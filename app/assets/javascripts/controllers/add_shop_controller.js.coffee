SS.AddShopController = Ember.Controller.extend
  shopTypes:
    [
      {type: 'shopify', name: 'Shopify Shop'},
      {type: 'custom', name: 'Custom Shop'}
    ]

  shop: null

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

    @makeShop()

  makeShop: ->
    @clearTransaction()

    @set 'shop', SS.Shop.createRecord(type: 'shopify')

  clearTransaction: ->
    if @get 'shop'
      shop.transaction.rollback()
