SS.Router = Ember.Router.extend
  location: 'hash'

  root: Ember.Route.extend
    goToIndex: Ember.Route.transitionTo('index')
    goToDashboard: Ember.Route.transitionTo('dashboard')
    goToFeed: Ember.Route.transitionTo('feed')
    goToSettings: Ember.Route.transitionTo('settings')
    goToConnectShop: Ember.Route.transitionTo('connectShop')

    index: Ember.Route.extend
      route: '/'
      redirectsTo: 'dashboard'

    dashboard: Ember.Route.extend
      route: '/dashboard'

      connectOutlets: (router) ->
        if SS.hasShop
          router.get('applicationController').connectOutlet 'dashboard'
        else
          router.send 'goToConnectShop'

    feed: Ember.Route.extend
      route: '/feed'

      connectOutlets: (router) ->
        router.get('applicationController').connectOutlet 'feed'

    settings: Ember.Route.extend
      route: '/settings'

      connectOutlets: (router) ->
        router.get('applicationController').connectOutlet 'settings'

    connectShop: Ember.Route.extend
      route: '/connect_shop'

      connectOutlets: (router) ->
        router.get('applicationController').connectOutlet 'connectShop'

    connectOutlets: (router) ->
      SS.set 'user', SS.User.find(SS.userId)
