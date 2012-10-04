SS.DashboardTopColumnView = Ember.View.extend
  templateName: 'dashboard_top_column'
  tagName: 'section'
  classNames: ['column']
  layout: Ember.Handlebars.compile '<div class="panel">{{yield}}</div>'
