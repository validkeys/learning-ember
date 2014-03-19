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

App.ApplicationSerializer = DS.ActiveModelSerializer.extend({});    

# App.Store = DS.Store.extend
#   revision: 1
#   adapter:  App.ApplicationAdapter


# --------------------
# ROUTER
# --------------------
App.Router.map ->
  @route "home"

  @resource "lineups",
    path: "/lineups"

  @resource "lineup",
    path: "/lineups/:lineup_id"


# --------------------
# ROUTES
# --------------------
App.LineupsRoute = Ember.Route.extend
  model: ->
    @store.find "lineup"

App.LineupRoute = Ember.Route.extend
  model: (params) ->
    @store.find "lineup", params.lineup_id

App.IndexRoute = Ember.Route.extend
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


# Ember.Inflector.inflector.irregular('curator', 'curators')

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
  curators:                   DS.hasMany "curator", async: true


App.Curator = DS.Model.extend
  accepted:   DS.attr "boolean"
  created_at: DS.attr "date"
  owner:      DS.attr "boolean"
  lineup:     DS.belongsTo "lineup"

