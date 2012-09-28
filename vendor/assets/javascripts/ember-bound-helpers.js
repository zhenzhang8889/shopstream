var helpers = Ember.Handlebars.helpers;

Ember.Handlebars.registerBoundHelper = function(name, cp) {
  Ember.Handlebars.registerHelper(name, function(path, options) {
    if(!(cp instanceof Ember.ComputedProperty)) {
      cp = Ember.computed(cp);
    }

    var originalContext,
        bindingPath = "originalContext." + path,
        normalized = Ember.Handlebars.normalizePath(null, path, options.data);

    if (normalized.isKeyword) {
      originalContext = options.data.keywords;
    } else if (Ember.isGlobalPath(path)) {
      originalContext = null;
      bindingPath = path;
    } else if (path === 'this') {
      originalContext = this;
      bindingPath = "originalContext";
    } else {
      originalContext = this;
    }

    var context = Ember.Object.create({
      originalContext: originalContext,
      valueBinding: bindingPath,
      result: cp.property('value')
    }, options.hash);

    if(options.contexts) {
      options.contexts.unshift(context);
    }
    var args = Array.prototype.slice.call(arguments, 1);
    args.unshift('result');
    return helpers.bind.apply(context, args);
  });
};