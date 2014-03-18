gulp    = require 'gulp'
coffee  = require 'gulp-coffee'
stylus  = require 'gulp-stylus'
path    = require 'path'
watch   = require 'gulp-watch'
connect = require 'gulp-connect'

gulp.task 'connect', connect.server
  root: ['dist']
  port: 1337
  livereload: true
  open:
    browser: 'Google Chrome'

gulp.task 'coffee', ->
  gulp.src './src/js/*.coffee'
    .pipe(watch())
    .pipe(
      coffee
        bare: true
    )
    .pipe(
      gulp.dest './dist/js/'
    )
    .pipe(connect.reload())

gulp.task 'stylus', ->
  gulp.src './src/css/*.styl'
    .pipe(watch())
    .pipe(stylus())
    .pipe(
      gulp.dest './dist/css'
    )
    .pipe(connect.reload())

gulp.task 'copy', ->
  gulp.src './src/index.html'
    .pipe(watch())
    .pipe(gulp.dest './dist/')
    .pipe(connect.reload())
  gulp.src './src/css/*'
    .pipe(watch())
    .pipe(gulp.dest './dist/css/')
    .pipe(connect.reload())
  gulp.src [
    './bower_components/jquery/jquery.js',
    './bower_components/handlebars/handlebars.js',
    './bower_components/ember/ember.js',
    './bower_components/ember-data/ember-data.js'
  ]
    .pipe(gulp.dest './dist/js/')

gulp.task 'default', ['connect','coffee','stylus','copy']
