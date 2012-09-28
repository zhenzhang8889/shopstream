SS.FeedCollectionView = Ember.CollectionView.extend
  itemViewClass: Ember.View.extend
    classNames: ['com-con']
    templateName: 'feed_item'
  emptyView: Ember.View.extend
    template: Ember.Handlebars.compile '<p>No items in the feed.</p>'