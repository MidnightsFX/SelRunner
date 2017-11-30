#!/usr/bin/env ruby
# Files
require 'LogRunner'
require 'SelRunner/Assistant'
# Libs
require 'selenium-webdriver'
require 'celluloid/current'
require 'celluloid/io'
require 'addressable'


module SelRunner
  class TestWrapper
    include Celluloid
    
    @limiter = Mutex.new # these are for limiting new connection creation | checking

    # This method provides celluloid a class hook
    # args general purpose configuration # l - the current incoming selenium object information
    def runner(args, l, cfg)
      unless args[:target].nil?
        target = args[:target]
      end
      SelRunner::TestWrapper.wrap_core(args, l, cfg, target)
    end # end runner function

    def self.wrap_core(args, l, cfg, target)
      #begin
        #check_sessions()
        session = build_session(l, args)
        driver = session[:driver]
        cell = session[:cell]
        # navigate target | URL param is a UUID and helps prevent caching
        tries ||= 5
        begin
          driver.navigate.to "#{target}?#{cell['name']}"
        rescue StandardError => e
          Log.write("Issue connecting to test target:#{e}", :W)
          Log.write("Target:#{target} Cell:#{cell['name']}", :W)
          #check_sessions() # wait until there is an open session
          retry unless (tries -= 1).zero?
          ssid = check_active_session(cell['name'])
          fail_timeout(ssid, e) # Fail the session and state the error returned
          # This occurs when the grid provider fails to init a session
        end
        # Call the actual test functions
        begin
          results = SelRunner::TestWrapper.test_wrap(args, l, driver, cell)
        rescue StandardError => e # There was an error during the selenium test
          # this can be your code having an issue, or an actual driver crash/condition
          ssid = GridAPI.get_session(cell['name'])
          if ssid['active'] == true
            driver.quit
            SelRunner::GridAPI.session_set_score(ssid['selenium_test_id'], 'fail')
            SelRunner::GridAPI.session_set_desc(ssid['selenium_test_id'], 'Test Errors Occured.')
            Log.write("Tett Error: #{e}", :E)
            exit
          end
          ssid = check_active_session(cell['name'])
          fail_timeout(ssid, e) # Fail the session and state the error returned
          return false
        end
        driver.quit # Close this selenium grid object once its done
        Log.write("Instance Completed. #{cell['name']}", :I)
        # Set score for the test | Store test result on the Grid
        ssid = check_active_session(cell['name'])
        # Wait until the session is closed to set the score.
        SelRunner::GridAPI.session_set_score(ssid['selenium_test_id'], results[:testresult])
        # No spaces in result details- sorry | talk to your grid provider for their API
        SelRunner::GridAPI.session_set_desc(ssid['selenium_test_id'], results[:testcomment].gsub(/\s+/, "_"))
    end

    def self.fail_timeout(ssid, session_set_desc)
      SelRunner::GridAPI.session_set_score(ssid['selenium_test_id'], 'fail')
      SelRunner::GridAPI.session_set_desc(ssid['selenium_test_id'], session_set_desc.to_s)
    end

    def self.check_active_session(cell)
      ssid = 0
      loop do
        ssid = SelRunner::GridAPI.get_session(cell)
        Log.write("SSID STATUS: #{ssid['active']}", :D)
        break if ssid['active'] == false #puts "SSID #{ssid['active']}"
        sleep rand(1..3)
      end
      return ssid
    end

    def self.build_session(l, args)
      cons_res = TestWrapper.instance_construction(l, args)
      driver = cons_res[:driver] # driver is the actual selenium object
      cell = cons_res[:cell] # Cell = unique information on THIS driver
      Log.write("This Unique Cell #{cons_res.inspect}", :D)
      session = {
        cons_res: cons_res,
        driver: driver,
        cell: cell
      }
      return session
    end

    def self.check_sessions()
      @mxcons ||= 5 # limiter for number of parallel tests
      @cons ||= 0 # Current connections
      n = false
      loop do
        @limiter.synchronize do
          Log.write("@cons:#{@cons}-@mxcons:#{@mxcons}", :D)
          sleep rand(2..5) if @cons >= @mxcons
          net_cons = SelRunner::GridAPI.get_active_sessions.length if @cons >= @mxcons
          Log.write("API Response: #{net_cons}", :D)
          Log.write("MUTEX Retrieved: #{@cons}", :D)
          @cons = net_cons unless net_cons.nil? # set stored connections to api response
          sleep rand(2..5) if @cons >= @mxcons
          n = true if @cons < @mxcons
          next if n == false
          @cons += 1 #add 1 to con if its true and prepare to break out.
        end
        break if n == true
        #Log.write('MUTEX REQUIRES SLEEP.', :D)
      end
    end

    def self.test_wrap(args, l, driver, cell)
      # TODO: function should allow for modular loading of available tests
      targs = {
        instace_spec: l,
        driver: driver,
        jserrors: args[:jserrors],
        required: args[:required],
        reqnot: args[:reqnot],
        testname: args[:testname],
        cell: cell
      }
      # test results are passed back from the test
      results = args[:callback].call(targs)
      return results
    end # end test_wrap

    # Construct the required abillities for the cell
    def self.instance_construction(l, args)
      auth = SelRunner.credentials(args[:platform].to_sym) # get creds and hub location
      hub = Addressable::URI.parse("http://#{auth[:user]}:#{auth[:pass]}@#{auth[:hub]}").normalize.to_s # Normalize URL
      args = args.merge(testname: SecureRandom.hex(15)) # Generate UUID
      cell = SelRunner::Platforms.build_instance(l, args) # Build the resulting cell from its args
      Log.write("Instance Build object #{l}", :D)
      Log.write("#{args[:testname]} #{cell.inspect}", :D)
      check_sessions() # wait until there is an open session
      tries ||= 5 # Construct the driver
      begin
        # Log this retry if it has had to retry the connection more than 3 times.
        Log.write("RETRY SETTINGS: HUB-#{hub} CELL-#{cell.inspect} L-#{l}", :W) if tries < 3
        driver = Selenium::WebDriver.for(
          :remote,
          url: hub,
          desired_capabilities: cell
        ) # Driver started... Floor it!
        Log.write("Instance: #{l[:os]} #{l[:osver]} #{l[:Browser][:bname]} #{l[:Browser][:bver]} #{cell['name']}", :I)
        results = { driver: driver, cell: cell }
      rescue StandardError => e
        Log.write("Issue connecting/Building WebDriver #{e}", :W)
        SelRunner::GridAPI.ensure_session_does_not_exist(3,l[:Browser][:api_name]) # check if a session that is not connected with the same browser is listed, kill it.
        check_sessions() # wait until there is an open session
        retry unless (tries -= 1).zero?
      end
      return results
    end # end instance_construction
  end # end Test Wrapper Class
end # end Module
