App = Ember.Application.create({
  LOG_TRANSITIONS: true,
  LOG_BINDINGS: true,
  LOG_VIEW_LOOKUPS: true,
  LOG_STACKTRACE_ON_DEPRECATION: true,
  LOG_VERSION: true,
  debugMode: true
});

App.Store = DS.Store.extend({
  revision: 1,
  adapter: DS.FixtureAdapter
});

App.Router.map(function() {
  this.route('home');
  this.resource('lineups');
  this.resource('lineup', {path: "/lineups/:lineup_id"});
});

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