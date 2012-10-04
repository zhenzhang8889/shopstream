SS.DashboardTopCollectionView = Ember.CollectionView.extend
  tagName: 'ul'
  classNames: 'no-bullet'
  itemViewClass: Ember.View.extend
    template: Ember.Handlebars.compile '<div class="alert-box">{{view.content}}</div>'
  emptyView: Ember.View.extend
    template: Ember.Handlebars.compile '<h6 class="subheader">No items.</h6>'