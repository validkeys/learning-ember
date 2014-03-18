// ------------------
// BASE APP
// ------------------

App = Ember.Application.create({
  LOG_TRANSITIONS: true,
  LOG_BINDINGS: true,
  LOG_VIEW_LOOKUPS: true,
  LOG_STACKTRACE_ON_DEPRECATION: true,
  LOG_VERSION: true,
  debugMode: true
});


// --------------------
// INIT THE DATA STORE
// --------------------

App.Store = DS.Store.extend({
  revision: 1,
  adapter: DS.FixtureAdapter
});


// --------------------
// ROUTER
// --------------------

App.Router.map(function() {
  this.route('home');
  this.resource('lineups', {path: '/lineups'});
  this.resource('lineup', {path: "/lineups/:lineup_id"});
});

// --------------------
// ROUTES
// --------------------

App.LineupsRoute = Ember.Route.extend({
  model: function(){
    return this.store.find('lineup');
  }
});

App.LineupRoute = Ember.Route.extend({
  model: function(params){
    return this.store.find('lineup', params.lineup_id);
  }
});

App.IndexRoute = Ember.Route.extend({
  redirect: function(){
    this.transitionTo('lineups');
  }
});


// --------------------
// MODELS
// --------------------

App.Lineup = DS.Model.extend({
  title: DS.attr('string')
});

App.Lineup.FIXTURES = [
  {
    id: 1,
    title: "First Lineup"
  },
  {
    id: 2,
    title: "Second Lineup"
  }
];