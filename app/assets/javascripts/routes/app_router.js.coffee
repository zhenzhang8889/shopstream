SS.Router = Ember.Router.extend
  location: 'hash'

  root: Ember.Route.extend
    goToIndex: Ember.Route.transitionTo('index')
    goToDashboard: Ember.Route.transitionTo('shop.dashboard')
    goToFeed: Ember.Route.transitionTo('shop.feed')
    goToSettings: Ember.Route.transitionTo('shop.settings')

    index: Ember.Route.extend
      route: '/'

      connectOutlets: (router, context) ->
        router.get('applicationController').connectOutlet 'shopSelector'
        router.get('shopSelectorController').connectOutlet 'add', 'addShop'

    shop: Ember.Route.extend
      route: '/shops/:shop_id'

      dashboard: Ember.Route.extend
        route: '/dashboard'

        connectOutlets: (router, context) ->
          console.log context
          
          router.get('shopController').connectOutlet 'dashboard'

      feed: Ember.Route.extend
        route: '/feed'

        connectOutlets: (router) ->
          router.get('shopController').connectOutlet 'feed'

      settings: Ember.Route.extend
        route: '/settings'

        connectOutlets: (router) ->
          router.get('shopController').connectOutlet 'settings'

      connectOutlets: (router, context) ->
        router.get('applicationController').connectOutlet 'shop', context

    connectOutlets: (router) ->
      SS.set 'user', SS.User.find(SS.userId)
