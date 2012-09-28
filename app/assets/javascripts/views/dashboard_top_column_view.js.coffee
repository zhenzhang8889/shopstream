SS.DashboardTopColumnView = Ember.View.extend
  templateName: 'dashboard_top_column'
  tagName: 'section'
  classNames: ['col']
  layout: Ember.Handlebars.compile '<div class="content">{{yield}}</div>'
