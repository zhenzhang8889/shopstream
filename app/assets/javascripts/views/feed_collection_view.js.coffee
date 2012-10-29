SS.FeedCollectionView = Ember.CollectionView.extend
  itemViewClass: Ember.View.extend
    classNames: ['panel feed-item']
    templateName: 'feed_item'
  emptyView: Ember.View.extend
    template: Ember.Handlebars.compile "<h5 class='subheader'>We still haven't tracked any feed activities today.</h5>"