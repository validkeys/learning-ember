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

 DS.RESTAdapter.reopen
  pathForType: (type) ->
    switch type
      when "medium"
        "movies"
      else
        @_super(type)

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

  @route "login"

  @resource "lineups",
    path: "/lineups"

  @resource "lineup", path: "/lineups/:lineup_id", ->
    @route "curators"

  @route "lineup.new", path: "/lineups/new"

  @resource "medium", path: "/media/:medium_id"


# --------------------
# ROUTES
# --------------------

App.BaseRoute     = Ember.Route.extend
  actions:
    error: (reason, transition) ->
      if reason.status == 401
        @transitionTo "login"
      else
        console.error "Something went wrong", reason


# ROUTES THAT REQUIRE A USER TO BE AUTH'D SHOULD
# EXTEND FROM THIS
App.AuthenticatedRoute = App.BaseRoute.extend

  beforeModel: (transition) ->
    if !@controllerFor('login').get "token"
      @redirectToLogin()

  redirectToLogin: (transition) ->
    @controllerFor("login").set "attemptedTransition", transition
    @transitionTo "login"


App.ApplicationRoute = App.BaseRoute.extend
  init: ->
    @_super()
    App.AuthManager = AuthManager.create()


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

    # NOTE:
    #      To make a GET request for all records from the server:
    #       :: this.store.find('model-name') //-> network request
    #      To get a list of just the records already in the store
    #       :: this.store.all('model-name') //-> no network request

    @store.find "lineup"

# EXAMPLE: Filtering
# -------------------
# Let's say that I wanted to have a lineups/published route
# that would only show me the published lineups
# (assuming you've created the route in your router)
# ------
# App.LineupsPublishedRoute = App.BaseRoute.extend({
#   model: function(){
#     return this.store.filter('lineup', function(lineup){
#       return lineup.get('published');
#     });
#   }
# });
# ------


App.LineupRoute   = App.LoadMoreRoute.extend
  model: (params) ->

    # We can pass in query params like this:
    #   ::-> this.store.find('lineup', { published: true })

    @store.find "lineup", params.lineup_id

App.LineupNewRoute = App.BaseRoute.extend

  setupController: (controller, model) ->
    @controller.set 'model', @store.createRecord 'post'

App.MediumRoute    = App.LoadMoreRoute.extend
  model: (params) ->
    console.log "HERE------------------------"
    @store.find "medium", params.medium_id

App.IndexRoute    = App.BaseRoute.extend
  redirect: ->
    @transitionTo "lineups"


# --------------------
# CONTROLLERS
# --------------------

App.LineupsController = Ember.ArrayController.extend

  # NOTE:
  #      if i depended on another controller
  # --------------------------
  # needs: ['comment'] //ie. the CommentController
  # --------------------------
  #      I could then alias it to a computed property
  # --------------------------
  # comment: Ember.computed.alias('controllers.post')
  # --------------------------


  sortProperties:   ['created_at']
  sortAscending:    false

App.LineupNewController = Ember.ObjectController.extend

  title: ''

  actions:
    submitForm: ->
      unless @get("title").length is 0
        console.log "User wants to create a lineup with the title: #{@get 'title'}"
        @store.createRecord "lineup",
          title: @get "title"
          # user:
      else
        alert "you must enter a title"

App.LoginController = Ember.Controller.extend

  token: localStorage.token
  tokenChanged:(->
    localStorage.token = @get "token"
  ).property('token')

  login: ->
    console.log "Logging in!"


# --------------------
# COMPONENTS
# --------------------

App.BackdropImageComponent = Ember.Component.extend
  tagName:            "img"
  attributeBindings: ["src","width"]
  width:(->
    @get "width"
  ).property 'width'
  src:( ->
    "http://images.cdn.kushapp.com/media/movies/" + @get("medium_id") + "/backdrops/w" + @get("width") + @get("file_path")
  ).property 'file_path', 'medium_id'

App.PosterImageComponent = Ember.Component.extend
  tagName:   "img"
  attributeBindings: ["src"]
  src:( ->
    "http://images.cdn.kushapp.com/media/movies/" + @get("medium_id") + "/posters/w" + @get("width") + @get("file_path")
  ).property 'file_path', 'medium_id'



# --------------------
# MODELS
# --------------------

# Ember.Inflector.inflector.irregular('medium', 'media');


# NOTES:
#       -> Creating Records
#       -------------------
#         var post = store.createRecord('post', { attrs... })
#         post.save().then -> (persists then acts on promise)
#
#       -> Deleting Records
#       -------------------
#         OPTION: 1
#                 post.deleteRecord()
#                 post.get('isDeleted') #=> true
#                 post.save()
#         OPTION: 2
#                 post.destroyRecord() // persists immediately
#
#
#        If you've got model data and want to add it to the store
#         (ex. bootstrapped data)
#         post = {title: "My Bootstrapped Post"}
#         this.store.push('post', post)


# ---------
# TIP: put DS.attr, hasMany and belongsTo into vars:
#      var attr = Ds.attr, belongsTo = DS.belongsTo, hasMany = DS.hasMany
#      then: first_name: attr('string')
#      then: user: belongsTo('user')

App.User = DS.Model.extend
  first_name: DS.attr "string"
  last_name:  DS.attr "string"

App.Curator = DS.Model.extend
  accepted:   DS.attr "boolean"
  created_at: DS.attr "date"
  owner:      DS.attr "boolean"
  lineup:     DS.belongsTo "lineup"
  user:       DS.belongsTo "user"

App.Trailer = DS.Model.extend
  provider:     DS.attr "string"
  source:       DS.attr "string"
  size:         DS.attr "string"
  medium_id:    DS.attr "number"
  name:         DS.attr "string"
  created_at:   DS.attr "date"

App.Medium = DS.Model.extend
  api_id:       DS.attr "number"
  backdrop:     DS.attr "string"
  poster:       DS.attr "string"
  release_date: DS.attr "date"
  title:        DS.attr "string"
  type:         DS.attr "string"
  overview:     DS.attr "string"
  runtime:      DS.attr "number"
  status:       DS.attr "string"
  tagline:      DS.attr "string"
  trailers:     DS.hasMany "trailer"


App.Selection = DS.Model.extend
  created_at: DS.attr "date"
  user:       DS.belongsTo "user"
  medium:     DS.belongsTo "medium"


App.Lineup = DS.Model.extend
  title:                      DS.attr "string"
  cached_votes_down:          DS.attr "number"
  cached_votes_score:         DS.attr "number"
  cached_votes_total:         DS.attr "number"
  cached_votes_up:            DS.attr "number"
  comments_count:             DS.attr "number"
  created_at:                 DS.attr "date"
  creation_status_percentage: DS.attr "number",
    defaultValue: 0
  curators_count:             DS.attr "number",
    defaultValue: 1
  date_featured:              DS.attr "date"
  description:                DS.attr "string"
  featured:                   DS.attr "boolean",
    defaultValue: false
  item_themes_count:          DS.attr "number",
    defaultValue: 0
  lineup_media_count:         DS.attr "number",
    defaultValue: 0
  published:                  DS.attr "boolean",
    defaultValue: false
  published_date:             DS.attr "date"
  recommendations_count:      DS.attr "number",
    defaultValue: 0
  posters:                    DS.attr()
  backdrops:                  DS.attr()
  curators:                   DS.hasMany "curator"
  selections:                 DS.hasMany "selection"
