require 'bundler'
Bundler::GemHelper.install_tasks
require 'rake/testtask'

task :default => [:test]

desc "Run tests"
Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

desc "Run benchmarks"
task :benchmark do
  sh "ruby test/benchmark.rb"
end
