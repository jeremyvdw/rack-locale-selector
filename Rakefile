require 'rake/clean'

task :default => :test

# SPECS =====================================================================

desc 'Run specs with story style output'
task :spec do
  sh 'specrb --specdox -Ilib:spec spec/spec_*.rb'
end

desc 'Run specs with unit test style output'
task :test => FileList['spec/spec_*.rb'] do |t|
  suite = t.prerequisites
  sh "specrb -Ilib:spec #{suite.join(' ')}", :verbose => false
end

desc 'Generate test coverage report'
task :rcov do
  sh "rcov -Ilib:spec spec/spec_*.rb"
end