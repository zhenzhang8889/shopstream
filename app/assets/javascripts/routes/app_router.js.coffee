SS.Router = Ember.Router.extend
  location: 'hash'

  root: Ember.Route.extend
    goToIndex: Ember.Route.transitionTo('index')
    goToDashboard: Ember.Route.transitionTo('dashboard')
    goToFeed: Ember.Route.transitionTo('feed')

    index: Ember.Route.extend
      route: '/'
      redirectsTo: 'dashboard'

    dashboard: Ember.Route.extend
      route: '/dashboard'

      connectOutlets: (router) ->
        router.get('applicationController').connectOutlet 'dashboard'

    feed: Ember.Route.extend
      route: '/feed'

      connectOutlets: (router) ->
        router.get('applicationController').connectOutlet 'feed'

    connectOutlets: (router) ->
      SS.set 'user', SS.User.find(SS.userId)
