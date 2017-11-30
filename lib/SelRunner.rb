#!/usr/bin/env ruby
# Files
require 'SelRunner/Platform_Controller'
require 'SelRunner/ServerManager'
require 'SelRunner/TestWrapper'
require 'SelRunner/LogRunner'
require 'SelRunner/WebRunner'
require 'SelRunner/GridAPI'
require 'SelRunner/version'
# Libs
require 'celluloid/current'
require 'celluloid/io'
require 'thread'
require 'yaml'

# SelRunner Test Suite
module SelRunner
  @path = __dir__.gsub(/lib\/SelRunner/,'') # Set current path
  # Accessor for Path
  def self.path
    return @path
  end

  # Core Manager handles how tests are directed, instanced, or groups
  class CoreManager
    include Celluloid
    #trap 'INT' do shutdown end # TODO shutdown add

    def self.setup(args)
      # Aquire the list of platforms to run
      plist = SelRunner::Platforms.select_platforms(args)
      if list.empty?
        Log.write("No Platforms selected!", :W)
        exit
      end
      Log.write("Determing platforms to run on", :I)
      return plist
    end

    def self.manage_test(args, pool_size, cfg_reqs = nil)
      # Pool size is how many threads of tests to run in parallel
      # Get the browser list to run against this shtuff
      preblist = CoreManager.setup(args)
      blist = os_browser_combine(preblist)
      # Clean the environment
      SelRunner::GridAPI.ensure_clean_environment
      futures = []
      Log.write("Tests to run: #{blist.length}", :I)
      pool = TestWrapper.pool(size: pool_size) # One Integration to X browsers
      blist.each do |l|
        begin
          futures << pool.future.runner(args, l, nil)
        rescue DeadActorError, MailboxError, StandardError => e
          Log.write("Dead Actor found in Integration Runner #{e}", :E)
        end # end rescue
      end # end each
      futures.each {|f| f.value }
      # CoreManager.closedown
    end # end manage_test

    def self.os_browser_combine(blist)
      platform_full = []
      blist.each do |osobj|
        osobj[:Browsers].each do |l|
          Log.write("Browser Object on os: #{l}", :D)
          tmp = {} # Clear
          tmp = { os: osobj[:os], osver: osobj[:osver], Browser: l }
          tmp[:api_name] = osobj[:api_name] unless osobj[:api_name].nil?
          platform_full << tmp
        end # End browser loop
      end # end blist loop
      return platform_full
    end

    # TODO: add supervised shutdown of the whole test
    def self.shutdown
      # kill master control supervisor
    end
  end # end CoreManager

  # TODO: rewrite CLI interpreter
  def self.cli_interpreter(args)
    if args[:tag].nil? || args[:tag] == ''
      abort('You must provide a tag to select tests by.')
    end
    # path = SelRunner.path.chomp('lib/')
    # spec = `rspec -t #{args[:tag]}`
    args[:tag]
  end # end cli_interpreter

  # This takes in the user and password for each defined service
  def self.credentials(gridname = nil)
    gridname = :crossbrowsertesting if gridname.nil? # default to CBT right now
    abort('Invalid Grid Provider passed.') unless %i[crossbrowsertesting browserstack saucelabs all].include? gridname
    contents = YAML.load_file(File.absolute_path('lib/config.yaml'))
    return contents[:auth] if gridname == :all
    return contents[:auth][gridname]
  end

end # end SelRunner
