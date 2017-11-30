#!/usr/bin/env ruby
# Files
require 'SelRunner/LogRunner'
require 'SelRunner'
# Libs
require 'celluloid/current'
require 'celluloid/io'

# Global SelRunner module
module SelRunner
  # WebRunner manages starting/threading actual content server
  class GridAPI
    include Celluloid

    # Define which API your using here | Currently integration/using CBT
    @API = 'https://crossbrowsertesting.com/api/v3/selenium'
    # Because API calls require more than one line...
    # args[:call] = uri request | args[:type] = :put-:delete-:get
    def self.api_call(args)
      uri = URI(args[:call])
      req = case args[:type]
            when :put
              Net::HTTP::Put.new(uri)
            when :delete
              Net::HTTP::Delete.new(uri)
            when :get
              Net::HTTP::Get.new(uri)
            end
      auth = SelRunner.credentials
      req.basic_auth(auth[:user], auth[:pass])
      Log.write("Request: #{uri}", :D)
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
        http.request(req)
      }
      jsnres = JSON.parse(res.body) # not convinced parsing the json body is the way to go
      return jsnres
    end #end api_call

    # Retrieve a list of the active sessions | limit 20
    def self.get_active_sessions
      api = { call: (@API + '?format=json&num=20&active=true'), type: :get }
      res = GridAPI.api_call(api)
      return res['selenium']
    end

    # Retrieve a list of the active sessions | limit 20
    def self.delete_session(id)
      api = { call: "#{@API}/#{id}", type: :delete }
      return GridAPI.api_call(api)
    end

    # Set Session Result | score = pass, fail, unset
    def self.session_set_score(id, score)
      Log.write("Setting Score: #{score} on #{id}", :D)
      api = { call: "#{@API}/#{id}?action=set_score&score=#{score}", type: :put }
      GridAPI.api_call(api)
    end

    # Set Session Result | score = pass, fail, unset
    def self.session_set_desc(id, desc)
      Log.write("Setting Description: #{desc} on #{id}", :D)
      api = { call: "#{@API}/#{id}?action=set_description&description=#{desc}", type: :put }
      GridAPI.api_call(api)
    end

    # Get Session | requires build name
    def self.get_session(testname)
      api = { call: "#{@API}?format=json&num=1&name=#{testname}", type: :get }
      res = GridAPI.api_call(api)
      #Log.write("SESSION RESPONSE: #{res['selenium'][0]}", :D)
      Log.write("SESSION RESPONSE: #{res['selenium'][0]['active']}", :D)
      Log.write("SESSION RESPONSE: #{res['selenium'][0]['selenium_test_id']}", :D)
      return res['selenium'][0]
    end

    def self.ensure_session_does_not_exist(cutoff, bwsr_api_name = nil)
      sessions = GridAPI.get_active_sessions
      return true if sessions.nil? # guard clause, don't need to eval if there are no sessions
      sessions.each do |se|
        statuses = 0
        Log.write("SE #{se}", :D)
        statuses +=1 if se['state'] == "unassigned" # unassigned session - not good
        statuses +=1 if se['selenium_session_id'].nil?
        unless bwsr_api_name.nil?
          statuses +=1 if se['caps']['browser_api_name'] == bwsr_api_name
        end
        # Clean-up the un-initalized session if it matches enough
        if statuses >= cutoff
          Log.write("SE:#{se['selenium_test_id']} SSID:#{se['selenium_session_id'].nil?} STATE:#{se['state']} BAPI:S:#{se['caps']['browser_api_name']}-C:#{bwsr_api_name} Score:#{statuses}", :W)
          Log.write("Terminating Session: #{se['selenium_test_id']}", :W)
          GridAPI.delete_session(se['selenium_test_id'])
          return true # return once the session is killed
        end
      end
    end
    

    # Clean up the environment | delete any active sessions
    def self.ensure_clean_environment
      jsnres = GridAPI.get_active_sessions
      return if jsnres.length.zero? # This method does nothing if there are no sessions to clear
      #puts jsnres
      jsnres.each do |se|
        GridAPI.delete_session(se['selenium_test_id'])
      end
      Log.write('Environment required cleaning. Waiting for sessions to close.', :I)
      sleep 5
      # probably perform another check to validate that sessions are all closed instead of sleeping - if this becomes an issue
    end

  end # end GridAPI

end # end SelRunner Module
