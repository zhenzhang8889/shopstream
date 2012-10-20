SS.Router = Ember.Router.extend
  location: 'hash'

  root: Ember.Route.extend
    goToIndex: Ember.Route.transitionTo('index')
    goToAddShop: Ember.Route.transitionTo('add_shop')
    goToDashboard: Ember.Route.transitionTo('shop.dashboard')
    goToFeed: Ember.Route.transitionTo('shop.feed')
    goToSettings: Ember.Route.transitionTo('shop.settings')

    index: Ember.Route.extend
      route: '/'

      connectOutlets: (router, context) ->
        router.get('applicationController').connectOutlet 'shopSelector'
        router.get('applicationController').connectOutlet 'header', 'header', {}

    add_shop: Ember.Route.extend
      route: '/add_shop'

      connectOutlets: (router, context) ->
        router.get('applicationController').connectOutlet 'addShop'
        router.get('applicationController').connectOutlet 'header', 'header', {}

    shop: Ember.Route.extend
      route: '/shops/:shop_id'

      dashboard: Ember.Route.extend
        route: '/dashboard'

        connectOutlets: (router) ->
          router.get('shopController').connectOutlet 'dashboard'

      feed: Ember.Route.extend
        route: '/feed'

        connectOutlets: (router) ->
          router.get('shopController').connectOutlet 'feed'

      settings: Ember.Route.extend
        route: '/settings'

        connectOutlets: (router) ->
          router.get('shopController').connectOutlet 'settings'

      welcome: Ember.Route.extend
        route: '/welcome'

        connectOutlets: (router) ->
          router.get('shopController').connectOutlet 'welcome'

      connectOutlets: (router, context) ->
        router.get('applicationController').connectOutlet 'shop', context
        router.get('applicationController').connectOutlet 'header', 'header', context

    connectOutlets: (router) ->
      SS.set 'user', SS.User.find(SS.userId)
