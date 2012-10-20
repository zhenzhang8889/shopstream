SS.store = DS.Store.create
  revision: 4
  adapter: DS.RESTAdapter.create
    bulkCommit: false
    namespace: 'v1'

    buildURL: (record, suffix) ->
      # Overrwite buildURL to include authentication token.
      @_super(record, suffix) + '?auth_token=' + SS.get('authToken')

    # Execute custom method on record with extension.
    #
    # type      - the record type
    # record    - the Ember.Object record
    # method    - the String method
    # extension - the String extension
    # data      - the Object data
    #
    # Example:
    #
    #   customMethodOnRecord(Book, book, "POST" "send_description", {email: 'a@b.dev'}
    #   # will execute POST /books/1/send_description with {"email":"a@b.dev"}
    customMethodOnRecord: (type, record, method, extension, json) ->
      id = record.get('id')
      root = @rootForType type

      @ajax @buildURL(root, id + '/' + extension), method, {
        data: json,
        context: this
      }

DS.defaultStore = SS.store
