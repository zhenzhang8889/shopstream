SS.WelcomeController = Ember.ObjectController.extend
  contentBinding: 'SS.router.shopController.content'

  sendInstructions: ->
    @get('content').sendInstructions @get('developerEmail')
    @set 'sentInstructions', true

  isValid: (->
    @get('developerEmail') != '' && @get('developerEmail')?
  ).property 'developerEmail'

  isInvalid: (->
    !@get('isValid')
  ).property 'isValid'

  isInvalidOrSentInstructions: (->
    @get('isInvalid') or @get('sentInstructions')
  ).property 'isInvalid', 'sentInstructions'
