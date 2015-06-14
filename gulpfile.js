var gulp = require('gulp');
var gutil = require('gulp-util');
var bower = require('bower');
var coffee = require('gulp-coffee');
var ngHtml2Js = require("gulp-ng-html2js");
var concat = require('gulp-concat');
var minifyHtml = require("gulp-minify-html");
var uglify = require("gulp-uglify");
var sass = require('gulp-sass');
var minifyCss = require('gulp-minify-css');
var rename = require('gulp-rename');
var sh = require('shelljs');


var paths = {
  coffee: ['./app/js/**/*.coffee'],
  views: ['./app/views/**/*.html'],  
  sass: ['./scss/**/*.scss']
};

gulp.task('default', ['coffee', 'sass']);

gulp.task('sass', function(done) {
  gulp.src('./scss/ionic.app.scss')
    .pipe(sass())
    .pipe(gulp.dest('./www/css/'))
    .pipe(minifyCss({
      keepSpecialComments: 0
    }))
    .pipe(rename({ extname: '.min.css' }))
    .pipe(gulp.dest('./www/css/'))
    .on('end', done);
});

gulp.task('coffee', function(done) {
  gulp.src(paths.coffee)
  .pipe(coffee({bare: true}).on('error', gutil.log))
  // .pipe(concat('application.js'))
  .pipe(gulp.dest('./www/js'))
  .on('end', done)
})

gulp.task('copy:more', function(){
  gulp.src('./app/index.html')
    .pipe(gulp.dest('./www/'));
})

gulp.src(paths.views)
    .pipe(minifyHtml({
        empty: true,
        spare: true,
        quotes: true
    }))
    .pipe(ngHtml2Js({
        moduleName: "partials",
        prefix: "/partials/"
    }))
    .pipe(concat("partials.min.js"))
    // .pipe(uglify())
    .pipe(gulp.dest("./www/partials"));


gulp.task('watch', function() {
  gulp.watch(paths.sass, ['sass']);
});

gulp.task('install', ['git-check'], function() {
  return bower.commands.install()
    .on('log', function(data) {
      gutil.log('bower', gutil.colors.cyan(data.id), data.message);
    });
});

gulp.task('git-check', function(done) {
  if (!sh.which('git')) {
    console.log(
      '  ' + gutil.colors.red('Git is not installed.'),
      '\n  Git, the version control system, is required to download Ionic.',
      '\n  Download git here:', gutil.colors.cyan('http://git-scm.com/downloads') + '.',
      '\n  Once git is installed, run \'' + gutil.colors.cyan('gulp install') + '\' again.'
    );
    process.exit(1);
  }
  done();
});
