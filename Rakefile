require 'bundler'
Bundler::GemHelper.install_tasks

desc "Run all tests"
task :test do
  # sh "ruby test/sparse_vector_test.rb"
  sh "ruby test/sparse_matrix_test.rb"
end

desc "Run benchmarks"
task :benchmark do
  sh "ruby test/benchmark.rb"
end