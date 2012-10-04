SS.ShopSelectorCollectionView = Ember.CollectionView.extend
  classNames: ['block-grid', 'three-up']
  tagName: 'ul'
  itemViewClass: Ember.View.extend
    classNames: ['text-center']
  emptyView: Ember.View.extend
    template: Ember.Handlebars.compile '<h4 class="subheader">No shops.</h4>'
