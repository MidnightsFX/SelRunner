#!/usr/bin/env ruby
# Files
require 'LogRunner'
require 'SelRunner'
# Libs
require 'selenium-webdriver'
require 'SecureRandom'
require 'celluloid/current'
require 'celluloid/io'
require 'rbconfig'
require 'json'
require 'yaml'

# Variable Inputs: Saucelabs / Browserstack
module SelRunner
  class Platforms
    # include Celluloid

    # accepts a hash with destination/source
    def self.get_platforms(source)
      # Set call depending on source
      if source == 'crossbrowsertesting'
        auth = SelRunner.credentials(:crossbrowsertesting)
        Log.write('Source Selected: crossbrowsertesting', :D)
        platform_list = SelRunner::Platforms.cbt_platform_list(auth[:user], auth[:pass])
      end
      if source == 'saucelabs'
        auth = SelRunner.credentials(:saucelabs)
        Log.write('Source Selected: saucelabs', :D)
        platform_list = SelRunner::Platforms.sauce_platform_list(auth[:user], auth[:pass])
      end
      if source == 'browserstack'
        auth = SelRunner.credentials(:browserstack)
        Log.write('Source Selected: browserstack', :D)
        platform_list = SelRunner::Platforms.browserstack_platform_list(auth[:user], auth[:pass])
      end # end if browserstack
      Log.write('Updating Platforms...', :I)
      Log.write("Platforms List #{platform_list}", :D)
      return platform_list
    end # end get platforms

    def self.sauce_platform_list(user, api_key)
      platform_list = []
      plist = JSON.parse(`curl -u "#{user}:#{api_key}" https://saucelabs.com/rest/v1/info/platforms/webdriver`, symbolize_names: true)
      # Build the os / Version list
      plist.each do |pl|
        osvr = sauce_os_ver(pl)
        platform_list << osvr unless platform_list.include? osvr
      end
      # attach browsers available in each os to each os
      plist.each do |pl|
        next if pl[:short_version].to_i.zero? # Browser version isn't a version, skip (ex:beta no #)
        Log.write("OS: #{pl[:os]} BVS: #{pl[:short_version].to_i}", :D)
        browser = {
          bname: pl[:api_name],
          bver: pl[:short_version]
        }
        osvx = sauce_os_ver(pl)
        platform_list.each do |osl|
          if osl[:os] == osvx[:os] && osl[:osver] == osvx[:osver]
            osl[:Browsers] << browser
          end # end if
        end # end each platform_list
      end # end each plist
      #Log.write("Platforms: #{JSON.pretty_generate(platform_list)}", :D)
      return platform_list
    end

    # Sauce labs silly os version information coagulation
    def self.sauce_os_ver(plobj)
      osvr = {}
      case plobj[:api_name]
      when 'android', 'iphone', 'ipad'
        osvr[:osver] = plobj[:long_name]
        osvr[:os] = plobj[:api_name]
        osvr[:api_name] = plobj[:device]
      when 'firefox', 'chrome', 'safari', 'internet explorer', 'microsoftedge', 'opera'
        osinfo = plobj[:os].split(' ')
        # Munge the server names to the user sided names
        osver = case osinfo[1]
                when '2012'
                  '8'
                when '2008'
                  'vista'
                when '2003'
                  'XP'
                else
                  osinfo[1]
                end
        osvr[:osver] = osver
        osvr[:os] = osinfo[0]
        osvr[:api_name] = plobj[:os]
      else
        Log.write("UNHANDLED os/VERSION! #{plobj}", :W)
      end
      osvr[:Browsers] = []
      return osvr
    end

    # Build the platform object from CrossBrowserTesting
    def self.cbt_platform_list(user, pass)
      platform_list = []
      plist = JSON.parse(`curl -u "#{user}:#{pass}" https://crossbrowsertesting.com/api/v3/selenium/browsers`, symbolize_names: true)
      plist.each do |p|
        browsers = [] # define/clear browsers
        # Grab all of the browsers supported on this os/Platform
        # Log.write("Browsers Available: #{p[:browsers]}", :D)
        p[:browsers].each do |b|
          # change Microsoft Edge to Edge | Internet Explorer to IE
          b[:type] = 'Edge' if b[:type] == 'Microsoft Edge'
          b[:type] = 'IE' if b[:type] == 'Internet Explorer'
          browsers << {
            bname: b[:type],
            bver: b[:version],
            api_name: b[:api_name]
          }
        end
        version = extra_version(p)
        # build the os/Platform Browser/Version list
        platform_list << {
          os: p[:type],
          osver: version,
          api_name: p[:api_name],
          Browsers: browsers
        }
      end
      return platform_list
    end

    def self.extra_version(plobj)
      # Define the version based off the type of os
      version = case plobj[:type]
                when 'Windows'
                  plobj[:version].split(' ')[1] # always second element
                when 'Mac'
                  plobj[:version].split(' ')[2] # always third element
                when 'iPhone', 'Android'
                  plobj[:version]
                end
      return version
    end

    # Get browserstacks platform list and do useful formatting with it
    def self.browserstack_platform_list(user, pass)
      platform_list = []
      plist = JSON.parse(`curl -u "#{user}:#{pass}" https://www.browserstack.com/automate/browsers.json`, symbolize_names: true)
      # Build the os / Version list
      plist.each do |pl|
        # os = pl[:os] == 'OS X' ? 'Mac' : pl[:os]
        # osver = bs_mac_version(pl[:os_version])
        osvr = {
          os: pl[:os],
          osver: pl[:os_version],
          Browsers: []
        }
        platform_list << osvr unless platform_list.include? osvr
      end
      # attach browsers available in each os to each os
      plist.each do |pl|
        browser = {
          bname: pl[:browser],
          bver: pl[:browser_version]
        }
        # os = pl[:os] == 'OS X' ? 'Mac' : pl[:os]
        # osver = bs_mac_version(pl[:os_version])
        platform_list.each do |osl|
          if osl[:os] == pl[:os] && osl[:osver] == pl[:os_version]
            osl[:Browsers] << browser
          end # end if
        end # end each platform_list
      end # end each plist
      return platform_list
    end

    # Changes the OSX names from something silly like names to numbers
    def self.bs_mac_version(plosver)
      res = case plosver
            when 'Snow Leopard', '10.6'
              '10.6' == plosver ? 'Snow Leopard' : '10.6'
            when 'Lion', '10.7'
              '10.7' == plosver ? 'Lion' : '10.7'
            when 'Mountain Lion', '10.8'
              '10.8' == plosver ? 'Mountain Lion' : '10.8'
            when 'Mavericks', '10.9'
              '10.9' == plosver ? 'Mavericks' : '10.9'
            when 'Yosemite', '10.10'
              '10.10' == plosver ? 'Yosemite' : '10.10'
            when 'El Capitan', '10.11'
              '10.11' == plosver ? 'El Capitan' : '10.11'
            when 'Sierra', '10.12'
              '10.12' == plosver ? 'Sierra' : '10.12'
            else
              plosver
            end
      return res
    end

    # Mobile devices are supported by specifying Android / IOS and versions related
    # This accepts a hash of a value and/or version to restrict browser/os to
    # os, osver, Browser, bver
    def self.select_platforms(args)
      safety_filter(args) # check for versions without names
      # use a default provider if not specified
      args[:platform] = 'crossbrowsertesting' if args[:platform].nil?
      # Get a new list of browsers from Whatever provider you want
      platform_list = get_platforms(args[:platform])
      # check which criteria is going to be required
      narrow_list = []
      Log.write('Platforms updated...', :D)
      platform_list.each do |pl|
        narrow_list << eval_filter(pl, args) unless eval_filter(pl, args).nil?
      end
      # # Trim out any of the missings
      # narrow_list.each do |nl|
      #   if nl[:Browsers].empty?
      #     narrow_list.delete(nl)
      #   end
      # end
      Log.write("Narrowed List: #{narrow_list}", :D)
      return narrow_list
    end # end browser selection

    # Make sure that the object passed in meets all of the criteria
    def self.eval_filter(pl_entry, args)
      # Guard, if os/Ver not matched
      return nil if filter_os(args, pl_entry) == false
      # Check for browser filtering
      Log.write("Compare BNames? #{!args[:bname].nil?}", :D)
      unless args[:bname].nil?
        # if Browsers are to be limited return the limited list
        return filter_browsers(args, pl_entry)
      end
      return pl_entry # return the whole browser/os combo if Browsers are not selected
    end # end eval_filter

    # Filter out browsers/versions which should be selected
    def self.filter_browsers(args, pl_entry)
      Log.write('Filtering Browsers.', :D)
      Log.write("Filter Entry #{pl_entry}", :D)
      browsers = [] # browsers to be selected
      browsers_fine = [] # browsers with filtered versions
      pl_entry[:Browsers].each do |brwsr|
        # Very verbose logging
        Log.write("Filter Checking: #{brwsr[:bname]} to #{args[:bname]} #{brwsr[:bname].casecmp(args[:bname]).zero?}:#{brwsr[:bname].casecmp(args[:bname])}.", :D)
        browsers << brwsr if brwsr[:bname].casecmp(args[:bname]).zero?
      end
      unless args[:bver].nil?
        browsers.each do |brwsr|
          # Very verbose logging
          Log.write("Filter Checking: #{args[:bver]} to #{brwsr[:bver]} Result: #{args[:bver].include?(brwsr[:bver])}", :D)
          # Currently not checking minor versions, and including all minor versions, might need to change this in the future
          if args[:bver].include?(brwsr[:bver].to_i)
            Log.write("Browser Added to browsers_fine: #{brwsr[:bname]}-#{brwsr[:bver]}.", :D)
            browsers_fine << brwsr
          end
        end
      end
      # These two log a lot of stuff
      #Log.write("Browsers Selected:: #{browsers}", :D)
      # Log.write("Browsers Finite Selected: #{!browsers_fine.empty?}", :D)
      pl_entry[:Browsers] = args[:bver].nil? ? browsers : browsers_fine # return modified list of browsers
      # Guard clause for no browser/version combo match found on os/Ver
      if pl_entry[:Browsers].empty?
        return nil # nil doesn't get added to the list
      end
      # return a match if all of the criteria is matched
      return pl_entry
    end

    # Validate that the os/osver checked matches what is to be selected
    def self.filter_os(args, pl_entry)
      # Check for alternative OS version names
      unless args[:osver].nil?
        osvers = [args[:osver]]
        osvers << bs_mac_version(osvers[0])
      end
      #puts args
      return true if args[:os].nil? #if OS is nil, everything matches OS validation
      oses = if args[:os].casecmp('Mac').zero?
               [args[:os], 'OS X']
             else
               [args[:os]]
             end

      # If the OS is labeled as OSX, switch it to 'Mac' to make it the same as others
      # pl_entry[:os] = 'Mac' if pl_entry[:os] == 'OS X'
      Log.write("Arguments to sort os #{args} osver #{osvers}", :D)
      Log.write("Arguments to compare #{pl_entry}", :D)
      if !osvers.nil? # Check for osver defined
        Log.write("os & osver both defined, comparing versions #{osvers} #{pl_entry[:osver]} #{osvers.include?(pl_entry[:osver].to_s)}", :D)
        return osvers.include?(pl_entry[:osver].to_s) ? true : false # return current entry if os and osver match
      elsif oses.include?(pl_entry[:os].to_s)
        Log.write('os Matched, osver not defined.', :D)
        return true # return current entry if os Matches | OSV not defined
      else
        Log.write('os/osver not matched.', :D)
        return false # return false if osver and/or os don't match
      end
    end # end filter_os

    # Pre-Check which filters are active
    def self.safety_filter(args)
      # Guard clauses on filter requirements
      if args[:os].nil? && !args[:osver].nil?
        Log.write("Don't filter on osver without an os. Exiting.", :E)
        exit
      end
      # Guard clauses on filter requirements
      if args[:bname].nil? && !args[:bver].nil?
        Log.write("Don't filter on bver without an bname. Exiting.", :E)
        exit
      end
    end

    # Build the Selenium Object
    def self.build_instance(l, args)
      Log.write("Building cell driver with: #{l}", :D)
      cell = Selenium::WebDriver::Remote::Capabilities.new
      if args[:platform] == 'crossbrowsertesting'
        cell['os_api_name'] = l[:api_name]
        cell['browser_api_name'] = l[:Browser][:api_name]
        cell['record_video'] = 'true'
        cell['record_network'] = 'true'
        cell['css_selectors_enabled'] = 'true'
        cell['max_duration'] = 300
      end
      if args[:platform] == 'saucelabs'
        cell['platform'] = l[:api_name]
        cell['browserName'] = l[:Browser][:bname]
        cell['version'] = l[:Browser][:bver]
      end
      if args[:platform] == 'browserstack'
        cell['browser_name'] = l[:Browser][:bname] # this needs to be set for browserstack
        cell['browser_version'] = l[:Browser][:bver] # this needs to be set for browserstack
        cell['os_version'] = l[:osver] # this needs to be set for browserstack
        cell['browserstack.debug'] = 'true'
        cell['os'] = l[:os] # "Windows"
        cell['browserName'] = l[:Browser][:bname] # "IE"
        # Use a full cell name when the browser/version is not reported.
        cell['name'] = "#{l[:os]}-#{l[:osver]}_#{l[:Browser][:bname]}-#{l[:Browser][:bver]}_#{args[:testname]}"
      end
      cell['name'] = "#{args[:testname]}" 
      cell['project'] = args[:project].nil? ? 'Unlisted_Build' : args[:project]
      cell['build'] = args[:build].nil? ? 'Unlisted_Build' : args[:build]
      # Requires javascript
      cell['javascriptEnabled'] = 'true'
      cell['javascript_enabled'] = 'true'
      # Disable all caching and clear system
      cell['browser.cache.disk.enable'] = 'false'
      cell['browser.cache.memory.enable'] = 'false'
      cell['browser.cache.offline.enable'] = 'false'
      cell['network.http.use-cache'] = 'false'
      if args[:aivcert] == true # Accept invalid certs? aivcert
        cell['acceptSslCerts'] = 'true' # opera does not work with invalid SSL certs for automation
      end
      Log.write("CELL DEFINITIONS #{l[:Browser][:bname]} #{l[:Browser][:bver]}", :D)
      return cell
    end # end build_instance

  end # class

end # module
