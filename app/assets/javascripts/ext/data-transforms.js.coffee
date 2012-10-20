DS.attr.transforms.array =
  from: (serialized) ->
    if Ember.none(serialized) then [] else serialized

  to: (deserialized) ->
    if Ember.none(deserialized) then [] else deserialized

DS.attr.transforms.object =
  from: (serialized) ->
    if Ember.none(serialized) then {} else serialized

  to: (deserialized) ->
    if Ember.none(deserialized) then {} else deserialized
