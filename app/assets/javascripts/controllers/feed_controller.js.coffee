SS.FeedController = Ember.Controller.extend
  contentBinding: 'SS.router.shopController.content.feedItems'
  sortProperties: ['createdAt']
