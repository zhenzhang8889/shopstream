SS.DashboardTopCollectionView = Ember.CollectionView.extend
  tagName: 'ul'
  itemViewClass: Ember.View.extend
    classNames: ['layer', 'border-bottom']
    template: Ember.Handlebars.compile '{{view.content}}'
  emptyView: Ember.View.extend
    template: Ember.Handlebars.compile '<p>No items.</p>'