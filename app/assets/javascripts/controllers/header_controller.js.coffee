SS.HeaderController = Ember.ObjectController.extend
  isShop: (-> !!@get('content.id')).property 'content'
