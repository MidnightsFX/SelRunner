require "bundler/gem_tasks"
require "rspec/core/rake_task"

#RSpec::Core::RakeTask.new
#Rake Task to run rspec test cases
RSpec::Core::RakeTask.new(:spec, :tag) do |t, task_args|
  t.rspec_opts = "--tag #{task_args[:tag]}"
end

task :default => :spec
task :test => :spec
