var gulp = require('gulp'),
	gutil = require('gulp-util'),
	del = require('del'),
	uglify = require('gulp-uglify'),
	size = require('gulp-size')
	peg = require('gulp-peg');

var Path = {
	input: 'js.pegjs',
	output: 'js.js'
};

gulp.task('peg', ['clean'], function() {
	var pegOpts = {
		exportVar: 'nd.exprParser',
		optimize: 'size'
	};
	return gulp.src(Path.input)
		.pipe(peg(pegOpts).on('error', gutil.log))
		.pipe(uglify())
		.pipe(size())
		.pipe(gulp.dest('.'));
});

gulp.task('clean', function(cb) {
	del(Path.output, cb);
});

gulp.task('default', ['peg']);