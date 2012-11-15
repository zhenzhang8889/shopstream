SS.ShopSelectorCollectionView = Ember.CollectionView.extend
  classNames: ['block-grid', 'two-up', 'mobile-one-up']
  tagName: 'ul'
  itemViewClass: Ember.View.extend
    classNames: ['text-center']
  emptyView: Ember.View.extend
    tagName: 'section'
    classNames: ['text-center']
    templateName: 'no_stores'
