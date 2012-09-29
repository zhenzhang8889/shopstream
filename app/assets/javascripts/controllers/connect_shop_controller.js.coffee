SS.ConnectShopController = Ember.Controller.extend
  shopUrl: ''

  redirectConnectShop: ->
    window.location = "/shops/connect?shop=#{@get('shopUrl')}"
