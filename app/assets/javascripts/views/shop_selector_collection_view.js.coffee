SS.ShopSelectorCollectionView = Ember.CollectionView.extend
  tagName: 'ul'
  emptyView: Ember.View.extend
    template: Ember.Handlebars.compile '<p>No shops.</p>'