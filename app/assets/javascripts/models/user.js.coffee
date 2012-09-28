SS.User = DS.Model.extend
  email: DS.attr 'string'
  shop: DS.belongsTo('SS.Shop', key: 'shop')
