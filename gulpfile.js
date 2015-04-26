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

var Folder = {
	src: 'src/',
	dest: 'dist/'
};

var Path = {
	input: Folder.src + 'js_expr.pegjs',
	output: Folder.dest + 'js_expr.js'
};

gulp.task('build', ['clean'], function() {
	var pegOpts = {
		optimize: 'size'
	};
	return gulp.src(Path.input)
		.pipe(plumber())
		.pipe(peg(pegOpts).on('error', gutil.log))
		.pipe(size({ title: 'non-minified' }))
		.pipe(uglify())
		.pipe(size({ title: 'minified' }))
		.pipe(gulp.dest(Folder.dest));
});

gulp.task('clean', function(cb) {
	del(Path.output, cb);
});

gulp.task('watch', ['build'], function() {
	watch(Path.input, { verbose: true }, function() {
		gulp.run('build');
	});
});

gulp.task('watch-test', ['build'], function() {
	watch(Path.input, { verbose: true }, function() {
		gulp.run('test');
	});
});

gulp.task('default', ['build']);

gulp.task('build-test', ['build'], function() {
	gulp.run('test');
});

gulp.task('test', ['build'], function(cb) {
	var fs = require('fs'), filepath = 'test/sample_code.js';
	fs.readFile(filepath, 'utf8', function(err, testCode) {
		if (err) throw err;

		testCode = testCode.trim();
		gutil.log("input - test code:\n\n" + testCode + "\n");

		var parser = requireUncached('./js.js');
		gutil.log("output - Abstract Syntax Tree:\n\n" + JSON.stringify(parser.parse(testCode), null, 4));

		cb();
	});
});