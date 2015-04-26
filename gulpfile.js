var gulp = require('gulp'),
	gutil = require('gulp-util'),
	del = require('del'),
	plumber = require('gulp-plumber'),
	uglify = require('gulp-uglify'),
	size = require('gulp-size')
	peg = require('gulp-peg'),
	watch = require('gulp-watch');

function requireUncached(module) {
	delete require.cache[require.resolve(module)];
	return require(module);
}

var Path = {
	input: 'js.pegjs',
	output: 'js.js'
};

gulp.task('peg', ['clean'], function() {
	var pegOpts = {
		// exportVar: 'nd.exprParser',
		optimize: 'size'
	};
	return gulp.src(Path.input)
		.pipe(plumber())
		.pipe(peg(pegOpts).on('error', gutil.log))
		.pipe(size({ title: 'non-minified' }))
		.pipe(uglify())
		.pipe(size({ title: 'minified' }))
		.pipe(gulp.dest('.'));
});

gulp.task('clean', function(cb) {
	del(Path.output, cb);
});

gulp.task('watch', ['peg'], function() {
	watch(Path.input, { verbose: true }, function() {
		gulp.run('peg');
	});
});

gulp.task('watch-test', ['peg'], function() {
	watch(Path.input, { verbose: true }, function() {
		gulp.run('test');
	});
});

gulp.task('default', ['peg']);

gulp.task('peg-test', ['peg'], function() {
	gulp.run('test');
});

gulp.task('test', ['peg'], function(cb) {
	var fs = require('fs'), filepath = 'test/sample_code.js';
	fs.readFile(filepath, 'utf8', function(err, testCode) {
		if (err) throw err;
		gutil.log("input - test code:\n\n" + testCode + "\n");

		var parser = requireUncached('./js.js');
		gutil.log("output - Abstract Syntax Tree:\n\n" + JSON.stringify(parser.parse(testCode), null, 4));

		cb();
	});
});