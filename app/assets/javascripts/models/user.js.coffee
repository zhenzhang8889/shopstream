SS.User = DS.Model.extend
  email: DS.attr 'string'
  shops: DS.hasMany('SS.Shop', embedded: true)
