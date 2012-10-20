SS.Shop = DS.Model.extend
  type: DS.attr 'string'
  token: DS.attr 'string'
  domain: DS.attr 'string'
  name: DS.attr 'string'
  timezone: DS.attr 'string'
  trackerScriptUrl: DS.attr 'string'
  sendDailyNotifications: DS.attr 'boolean'
  soundOnSales: DS.attr 'boolean'

  user: DS.belongsTo('SS.User', key: 'user_id')
  feedItems: DS.hasMany('SS.FeedItem', embedded: true)

  avgPurchase: DS.attr 'number'
  maxAvgPurchase: DS.attr 'number'
  conversionRate: DS.attr 'number'
  maxConversionRate: DS.attr 'number'
  totalSalesToday: DS.attr 'number'
  checkoutDistribution: DS.attr 'array'
  topLinks: DS.attr 'array'
  topSearches: DS.attr 'array'
  topProducts: DS.attr 'array'

  # Public: Check if shop is a shopify shop.
  isShopifyShop: (-> @get('type') == 'shopify').property 'type'
  # Public: Check if shop is a custom shop.
  isCustomShop: (-> @get('type') == 'custom').property 'type'

  isValid: (->
    if @get('isShopifyShop')
      @get('domain') != '' && @get('domain')?
    else
      @get('name') != '' && @get('domain') != '' && @get('timezone') != '' &&
        @get('name')? && @get('domain')? && @get('timezone')?
  ).property 'type', 'name', 'domain', 'timezone'

  isInvalid: (-> !@get('isValid')).property 'isValid'

  # Public: Generate Pusher channel name.
  pusherChannelName: (-> "dashboard-#{@get('token')}").property 'token'

  # Public: Generate checkout distribution series for flot.
  checkoutDistributionSeries: (->
    coDistr = @get 'checkoutDistribution'
    yesterdayData = _.zip [0..23], coDistr[0..23]
    todayData = _.zip [0..23], coDistr[24..47]

    yesterdaySeries = { color: '#6f6f6f', label: 'yesterday', data: yesterdayData }
    todaySeries = { color: '#2ba6cb', label: 'today', data: todayData }

    [yesterdaySeries, todaySeries]
  ).property 'checkoutDistribution'

  # Public: Checkout distribution chart options for flot.
  checkoutDistributionChartOptions:
    yaxis:
      min: 0
      minTickSize: 1
    xaxis:
      tickSize: 4
    series:
      lines:
        lineWidth: 2

  # Internal: Listen to needed messages on shop's pusher channel.
  setupPusher: (->
    if !@get('pusherSetup') && !!@get('token')
      channel = SS.pusher.subscribe @get('pusherChannelName')
      channel.bind 'metrics-updated', (data) =>
        mappedData = {}

        for k, v of data
          mappedData[k.camelize()] = v

        @setProperties mappedData

      channel.bind 'feed-item-created', (item) =>
        mappedItem = {}

        for k, v of item
          mappedItem[k.camelize()] = v

        feedItem = SS.FeedItem.createRecord(mappedItem)

        if feedItem.get('isNewOrder') and @get('soundOnSales')
          $('.beep-sound')[0].play()
        
        @get('feedItems').unshiftObject SS.FeedItem.createRecord(mappedItem)

      @set 'pusherSetup', true
    ).observes 'token'