SS.ShopSelectorCollectionView = Ember.CollectionView.extend
  classNames: ['block-grid', 'three-up']
  tagName: 'ul'
  itemViewClass: Ember.View.extend
    classNames: ['text-center']
  emptyView: Ember.View.extend
    tagName: 'section'
    classNames: ['text-center']
    templateName: 'no_stores'
