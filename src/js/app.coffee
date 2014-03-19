# ------------------
# BASE APP
# ------------------
App = Ember.Application.create
  LOG_TRANSITIONS: true
  LOG_BINDINGS: true
  LOG_VIEW_LOOKUPS: true
  LOG_STACKTRACE_ON_DEPRECATION: true
  LOG_VERSION: true
  debugMode: true

# --------------------
# INIT THE DATA STORE
# --------------------

App.ApplicationAdapter = DS.RESTAdapter.extend
  host: 'http://localhost:3000'
  headers:
    "Authorization": "Token token=74477f01461f16cfcd52a6a01f2fdff7"


# --------------------
# NOTE:
# This is an over-ride obtained here: http://mozmonkey.com/2013/12/loading-json-with-embedded-records-into-ember-data-1-0-0-beta/
# This is so that I can load in embedded JSON vs. sideloading
# as ember would hope for.
# Once this issue is resolved in active model serializer (https://github.com/rails-api/active_model_serializers/pull/493)
# I should update the rails API  to sideload and remove this code
# --------------------
App.ApplicationSerializer = DS.RESTSerializer.extend(

  _generatedIds: 0

  ###
  Sideload a JSON object to the payload
  ###
  sideloadItem: (payload, type, item) ->
    sideloadKey = type.typeKey.pluralize() # The key for the sideload array
    sideloadArr = payload[sideloadKey] or [] # The sideload array for this item
    primaryKey = Ember.get(this, "primaryKey") # the key to this record's ID
    id = item[primaryKey]

    # Missing an ID, generate one
    if typeof id is "undefined"
      id = "generated-" + (++@_generatedIds)
      item[primaryKey] = id

    # Don't add if already side loaded
    return payload  unless sideloadArr.findBy("id", id) is `undefined`

    # Add to sideloaded array
    sideloadArr.push item
    payload[sideloadKey] = sideloadArr
    payload


  ###
  Extract relationships from the payload and sideload them. This function recursively
  walks down the JSON tree
  ###
  extractRelationships: (payload, recordJSON, recordType) ->

    # Loop through each relationship in this record type
    recordType.eachRelationship ((key, relationship) ->
      related = recordJSON[key] # The record at this relationship
      type = relationship.type # belongsTo or hasMany
      if related

        # One-to-one
        if relationship.kind is "belongsTo"

          # Sideload the object to the payload
          @sideloadItem payload, type, related

          # Replace object with ID
          recordJSON[key] = related.id

          # Find relationships in this record
          @extractRelationships payload, related, type

        # Many
        else if relationship.kind is "hasMany"

          # Loop through each object
          related.forEach ((item, index) ->

            # Sideload the object to the payload
            @sideloadItem payload, type, item

            # Replace object with ID
            related[index] = item.id

            # Find relationships in this record
            @extractRelationships payload, item, type
            return
          ), this
      return
    ), this
    payload


  ###
  Overrided method
  ###
  normalizePayload: (type, payload) ->
    typeKey = type.typeKey
    typeKeyPlural = typeKey.pluralize()
    payload = @_super(type, payload)

    # Many items (findMany, findAll)
    unless typeof payload[typeKeyPlural] is "undefined"
      payload[typeKeyPlural].forEach ((item, index) ->
        @extractRelationships payload, item, type
        return
      ), this

    # Single item (find)
    else @extractRelationships payload, payload[typeKey], type  unless typeof payload[typeKey] is "undefined"
    payload
)


# --------------------
# ROUTER
# --------------------
App.Router.map ->
  @route "home"

  @resource "lineups",
    path: "/lineups"

  @resource "lineup", path: "/lineups/:lineup_id", ->
    @route "curators"


# --------------------
# ROUTES
# --------------------

App.BaseRoute     = Ember.Route.extend()


App.LoadMoreRoute = App.BaseRoute.extend

  # because the API returns additional data
  # on the show method vs. the index method
  # let's reload the model when we go into a show
  # method and then set a flag on the model
  # so that the next time we go into this model
  # it doesn't reload from the server
  # -----
  # http://stackoverflow.com/questions/15222739/dynamically-fill-models-with-more-detailed-data-in-emberjs/18553153#18553153

  setupController: (controller, model) ->

    controller.set "model", model

    unless model.get("full") is true
      model.reload().then ->
        model.set "full", true

    return


App.LineupsRoute  = App.BaseRoute.extend
  model: ->
    @store.find "lineup"

App.LineupRoute   = App.LoadMoreRoute.extend
  model: (params) ->
    @store.find "lineup", params.lineup_id

App.IndexRoute    = App.BaseRoute.extend
  redirect: ->
    @transitionTo "lineups"


# --------------------
# CONTROLLERS
# --------------------

App.LineupsController = Ember.ArrayController.extend
  sortProperties:   ['created_at']
  sortAscending:    false



# --------------------
# MODELS
# --------------------


App.User = DS.Model.extend
  first_name: DS.attr "string"
  last_name:  DS.attr "string"

App.Curator = DS.Model.extend
  accepted:   DS.attr "boolean"
  created_at: DS.attr "date"
  owner:      DS.attr "boolean"
  lineup:     DS.belongsTo "lineup"
  user:       DS.belongsTo "user"

App.Lineup = DS.Model.extend
  title:                      DS.attr "string"
  cached_votes_down:          DS.attr "number"
  cached_votes_score:         DS.attr "number"
  cached_votes_total:         DS.attr "number"
  cached_votes_up:            DS.attr "number"
  comments_count:             DS.attr "number"
  created_at:                 DS.attr "date"
  creation_status_percentage: DS.attr "number"
  curators_count:             DS.attr "number"
  date_featured:              DS.attr "date"
  description:                DS.attr "string"
  featured:                   DS.attr "boolean"
  item_themes_count:          DS.attr "number"
  lineup_media_count:         DS.attr "number"
  published:                  DS.attr "boolean"
  published_date:             DS.attr "date"
  recommendations_count:      DS.attr "number"
  posters:                    DS.attr()
  backdrops:                  DS.attr()
  curators:                   DS.hasMany "curator"

App.Lineup.FIXTURES = [{"id":10,"title":"Borrowed nostalgia for the unremembered 70's","description":null,"published":false,"lineup_media_count":2,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":0,"images":{"posters":[],"backdrops":[]},"created_at":"2013-11-23T00:56:13.000Z","creation_status_percentage":33},{"id":4,"title":"70's porn feel","description":null,"published":false,"lineup_media_count":7,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":0,"images":{"posters":[],"backdrops":[]},"created_at":"2013-11-22T16:06:51.000Z","creation_status_percentage":33},{"id":6,"title":"Some fun, light adventure","description":null,"published":false,"lineup_media_count":7,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":0,"images":{"posters":[],"backdrops":[{"medium_id":10,"file_path":"/9obFHiluXvDaALGsrdJIOhh5HO9.jpg","id":null},{"medium_id":48,"file_path":"/iVD1vyB81OJHrqRoLStmzS8xZbW.jpg","id":null},{"medium_id":78,"file_path":"/cKsbbEPAO0zoNxFoVMTs8b9yCH7.jpg","id":null},{"medium_id":78,"file_path":"/pCzPppQLzyw694JSDbtnnvT9Rn5.jpg","id":null},{"medium_id":111,"file_path":"/2JK9IllXGo7V2PZzLmclkB5Cf8k.jpg","id":null},{"medium_id":112,"file_path":"/iVlFvz15zyxxewqQax9GBe4YtDQ.jpg","id":null}]},"created_at":"2013-11-22T18:32:56.000Z","creation_status_percentage":33},{"id":17,"title":"An ode to the lonely. Movies about struggle, defeat and the endurance of the lonely heart","description":null,"published":false,"lineup_media_count":7,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":0,"images":{"posters":[],"backdrops":[{"medium_id":115,"file_path":"/ow0sx3Sk2BvbtpYMXwAQRNMdIMW.jpg","id":null},{"medium_id":116,"file_path":"/y9pUwIn0r1Nlu7Ogjuo1zg4mdtL.jpg","id":null},{"medium_id":118,"file_path":"/5tMJqM3ecc0LxCoB3Y3uWYS3NK8.jpg","id":null},{"medium_id":119,"file_path":"/bjMFRzGa8YwfRybKYxHz3arBo80.jpg","id":null},{"medium_id":164,"file_path":"/ymzaJLm2EIYbG9n7snVfCnHAPQk.jpg","id":null},{"medium_id":165,"file_path":"/AsCyxEogqOHKEb79G5lwjfx8uSa.jpg","id":null}]},"created_at":"2013-11-25T20:59:44.000Z","creation_status_percentage":33},{"id":18,"title":"Thursday night and you had too many beers. Take two (and please don't call me in the morning)","description":null,"published":false,"lineup_media_count":7,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":1,"images":{"posters":[],"backdrops":[{"medium_id":120,"file_path":"/4V0hNC6SEbm836eg2BeaJvx1ZEO.jpg","id":null},{"medium_id":121,"file_path":"/kQzcHOxcjZ8hG0bF0tMNPghAFe0.jpg","id":null},{"medium_id":124,"file_path":"/8ZbrTYsUlbDsaI20BYz8E8WwgWU.jpg","id":null},{"medium_id":149,"file_path":"/39LohvXfll5dGCQIV9B9VJ16ImE.jpg","id":null},{"medium_id":150,"file_path":"/cmEojt7Ykuk6p2argyu0hEDoo0d.jpg","id":null},{"medium_id":151,"file_path":"/rpNWJxp4hy23CyeItratYRDLmgV.jpg","id":null},{"medium_id":156,"file_path":"/ixpnr4IeYWiuPfPcLPnoy8xNQC6.jpg","id":null}]},"created_at":"2013-11-25T21:01:59.000Z","creation_status_percentage":50},{"id":20,"title":"Quirk","description":null,"published":false,"lineup_media_count":5,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":0,"images":{"posters":[],"backdrops":[{"medium_id":135,"file_path":"/ppVUeyIF2vBEA5SCWF8sHVe1IQ5.jpg","id":null},{"medium_id":135,"file_path":"/AmSsrT2lPTlGD0KJSmc1HQCNTgl.jpg","id":null},{"medium_id":136,"file_path":"/20U165sAOpxtO0ASYqcdpqhYPma.jpg","id":null},{"medium_id":137,"file_path":"/judO4PDEDK8rktdCRpqjtKilvm8.jpg","id":null},{"medium_id":138,"file_path":"/tVoD2Vvt98EqRnDpztaYx95gqdf.jpg","id":null}]},"created_at":"2013-11-25T21:06:53.000Z","creation_status_percentage":33},{"id":21,"title":"Awesome music docs","description":null,"published":false,"lineup_media_count":7,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":0,"images":{"posters":[],"backdrops":[{"medium_id":140,"file_path":"/mw079OQwMshKZYASI1FmToIAiwX.jpg","id":null},{"medium_id":141,"file_path":"/1O0cvIh6rtSml4pTuae1ZBplQOj.jpg","id":null},{"medium_id":142,"file_path":"/yrPIcSeEh2EQinE1CwIZK7X3xMq.jpg","id":null},{"medium_id":143,"file_path":"/zkGGfbNoZTiCvrUhlvpfs3whCEW.jpg","id":null},{"medium_id":144,"file_path":"/mJsyN1zfi1pG7SOHIkeHy4JqBI9.jpg","id":null},{"medium_id":145,"file_path":"/4OrsHCNITdpkhAWCKAI2Cmd0gOi.jpg","id":null},{"medium_id":146,"file_path":"/yxqXznxXmrw2x8qqraXJf1RJG7B.jpg","id":null}]},"created_at":"2013-11-25T21:08:19.000Z","creation_status_percentage":33},{"id":23,"title":"Christmas","description":null,"published":false,"lineup_media_count":0,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":0,"images":{"posters":[],"backdrops":[]},"created_at":"2013-12-16T16:30:15.000Z","creation_status_percentage":33},{"id":8,"title":"Jailbreak","description":null,"published":false,"lineup_media_count":9,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":9,"images":{"posters":[],"backdrops":[{"medium_id":11,"file_path":"/nb70B4EXuoegiQ0C5N1fNVHIaYc.jpg","id":null}]},"created_at":"2013-11-22T20:41:05.000Z","creation_status_percentage":83},{"id":14,"title":"Mountains - 1, Humans - 0","description":"i love watching movies about the trials and tribulations of mountain climbers. i gotta tell you, i'm 100% sure i'd die on the way to mountain climb. (poor driver).","published":false,"lineup_media_count":6,"curators_count":1,"published_date":null,"comments_count":0,"cached_votes_total":0,"cached_votes_score":0,"cached_votes_up":0,"cached_votes_down":0,"recommendations_count":0,"featured":false,"date_featured":null,"item_themes_count":3,"images":{"posters":[],"backdrops":[{"medium_id":163,"file_path":"/888jtZz0mWfANiml4Pfe9567o3X.jpg","id":null}]},"created_at":"2013-11-25T20:49:14.000Z","creation_status_percentage":83}]
