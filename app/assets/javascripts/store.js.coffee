SS.store = DS.Store.create
  revision: 4
  adapter: DS.RESTAdapter.create
    bulkCommit: false
    namespace: 'v1'

    buildURL: (record, suffix) ->
      # Overrwite buildURL to include authentication token.
      @_super(record, suffix) + '?auth_token=' + SS.get('authToken')

DS.defaultStore = SS.store
