SS.Shop = DS.Model.extend
  domain: DS.attr 'string'
  token: DS.attr 'string'
  shopifyAttributes: DS.attr 'object'

  user: DS.belongsTo 'SS.User'
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

  pusherChannelName: (->
    "dashboard-#{@get('token')}"
  ).property 'token'

  checkoutDistributionSeries: (->
    coDistr = @get 'checkoutDistribution'
    yesterdayData = _.zip [0..23], coDistr[0..23]
    todayData = _.zip [0..23], coDistr[24..47]

    yesterdaySeries = { label: 'yesterday', data: yesterdayData }
    todaySeries = { label: 'today', data: todayData }

    [yesterdaySeries, todaySeries]
  ).property 'checkoutDistribution'

  checkoutDistributionChartOptions:
    yaxis:
      min: 0
      minTickSize: 1
    xaxis:
      tickSize: 4
    series:
      lines:
        lineWidth: 2

  setupPusher: (->
    if @get('isLoaded') && !@get('pusherSetup')
      channel = SS.pusher.subscribe @get('pusherChannelName')
      channel.bind 'metrics-updated', (data) =>
        mappedData = {}

        for k, v of data
          mappedData[k.camelize()] = v

        console.log mappedData

        @setProperties mappedData

      channel.bind 'feed-item-created', (item) =>
        mappedItem = {}

        for k, v of item
          mappedItem[k.camelize()] = v

        console.log mappedItem

        @get('feedItems').unshiftObject SS.FeedItem.createRecord(mappedItem)

      @set 'pusherSetup', true
  ).observes 'isLoaded'
