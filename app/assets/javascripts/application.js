//= require jquery
//= require jquery_ujs
//= require foundation
//= require handlebars
//= require underscore
//= require ember
//= require ember-bound-helpers
//= require ember-data
//= require accounting
//= require gauge
//= require flot
//= require moment
//= require pusher
//= require_self
//= require ss

SS = Ember.Application.create({
  user: null,
  shop: null,
  pusherKey: null,
  pusher: null,
  timezones: null,

  init: function() {
    this._super();

    this.userId = window.userId;
    this.authToken = window.authToken;
    this.pusherKey = window.pusherKey;
    this.timezones = window.timezones;

    this.initPusher();
  },

  initPusher: function() {
    this.pusher = new Pusher(this.pusherKey);
  }
});

window.SS = SS;