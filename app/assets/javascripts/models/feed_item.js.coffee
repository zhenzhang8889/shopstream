SS.FeedItem = DS.Model.extend
  activityType: DS.attr 'string'
  activityAttributes: DS.attr 'object'
  createdAt: DS.attr 'date'

  # Public: Check if activity is new cart activity.
  isNewCart: (-> @get('activityType') == 'new_cart').property 'activityType'
  # Public: Check if activity is new order activity.
  isNewOrder: (-> @get('activityType') == 'new_order').property 'activityType'

  # Public: Get actor name.
  actorName: (->
    if @get('isNewCart')
      'Someone'
    else
      "#{@get('activityAttributes.customer.first_name')} #{@get('activityAttributes.customer.last_name')}"
  ).property 'activityAttributes', 'isNewCart', 'isNewOrder'

  # Public: Get action description text for the activity.
  madeActionText: (->
    if @get('isNewCart')
      'created cart'
    else
      "made order #{@get('activityAttributes.name')}"
  ).property 'activityAttributes', 'isNewCart', 'isNewOrder'

  # Public: Get actor's email.
  actorEmail: (->
    if @get('isNewCart')
      'anonymous@shopstream.co'
    else
      @get 'activityAttributes.customer.email'
  ).property 'activityAttributes', 'isNewCart', 'isNewOrder'

  # Public: Generate avatar url for actor.
  avatarUrl: (->
    "http://avatars.io/email/#{@get('actorEmail')}"
  ).property 'activityAttributes', 'isNewCart', 'isNewOrder'
