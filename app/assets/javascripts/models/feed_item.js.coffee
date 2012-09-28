SS.FeedItem = DS.Model.extend
  activityType: DS.attr 'string'
  activityAttributes: DS.attr 'object'
  createdAt: DS.attr 'date'

  isNewCart: (-> @get('activityType') == 'new_cart').property 'activityType'
  isNewOrder: (-> @get('activityType') == 'new_order').property 'activityType'

  actorName: (->
    if @get('isNewCart')
      'Someone'
    else
      "#{@get('activityAttributes.customer.first_name')} #{@get('activityAttributes.customer.last_name')}"
  ).property 'activityAttributes', 'isNewCart', 'isNewOrder'

  madeActionText: (->
    if @get('isNewCart')
      'created cart'
    else
      "made order #{@get('activityAttributes.name')}"
  ).property 'activityAttributes', 'isNewCart', 'isNewOrder'

  actorEmail: (->
    if @get('isNewCart')
      'anonymous@shopstream.co'
    else
      @get 'activityAttributes.customer.email'
  ).property 'activityAttributes', 'isNewCart', 'isNewOrder'

  avatarUrl: (->
    "http://avatars.io/email/#{@get('actorEmail')}"
  ).property 'activityAttributes', 'isNewCart', 'isNewOrder'
