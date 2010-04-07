require 'rake/rdoctask'
require 'rake/testtask'

task :default => :test

# SPECS =====================================================================

desc 'Run specs with story style output'
task :spec do
  sh 'specrb --specdox -Ilib:spec spec/spec_*.rb'
end

desc "Run spec"
task :test do
  sh "specrb -Ilib:spec -w #{ENV['TEST'] || '-a'} #{ENV['TESTOPTS']}"
end

desc 'Generate test coverage report'
task :rcov do
  sh "rcov -Ilib:spec spec/spec_*.rb"
end
