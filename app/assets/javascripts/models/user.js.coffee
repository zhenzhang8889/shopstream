SS.User = DS.Model.extend
  email: DS.attr 'string'
  name: DS.attr 'string'
  shops: DS.hasMany('SS.Shop', embedded: true)
