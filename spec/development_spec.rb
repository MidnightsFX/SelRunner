#require "spec_helper"
require 'celluloid/current'
require 'celluloid/io'

# Testing something in development? Check the coverage
require 'simplecov'
SimpleCov.start

# Overarching SelRunner Module
describe SelRunner do
  describe 'Test Runner Development' do

    it 'Pulls in Creds', creds: true do
      results = SelRunner.credentials
      results.each do |l|
        # a username and pass to be returned
        expect(l[:user]).not_to be(nil)
        expect(l[:pass]).not_to be(nil)
      end
    end # Pulls in Creds

    it 'Updates available platforms Browserstack', blist: true do
      results = SelRunner::Platforms.get_platforms('browserstack')
      results.each do |l|
        # Expect each Entry to have a os and osver
        expect(l[:os]).not_to be(nil)
        expect(l[:osver]).not_to be(nil)
        # Expect Each os to have at least a browser
        expect(l[:Browsers].length).to be >= 1
      end
    end # Updates available platforms

    it 'Updates available platforms CrossBrowserTesting', cblist: true do
      results = SelRunner::Platforms.get_platforms('crossbrowsertesting')
      results.each do |l|
        # Expect each Entry to have a os and osver
        expect(l[:os]).not_to be(nil)
        expect(l[:osver]).not_to be(nil)
        # Expect Each os to have at least a browser
        expect(l[:Browsers].length).to be >= 1
      end
    end # Updates available platforms

    it 'Gets a filtered list', filterbs: true do
      args = { # These values are case sensitive
        platform: 'browserstack',
        os: 'Mac',
        bname: 'safari',
      }
      results = SelRunner::Platforms.select_platforms(args)
      #puts "Selected Platforms: #{JSON.pretty_generate(results)}"
      results.each do |osb|
        puts "OS: #{osb[:os]}-#{osb[:osver]} Browsers: #{osb[:Browsers].length}"
      end
    end # end filtered list check

    it 'Gets a filtered list', filtercbt: true do
      args = { # These values are case sensitive
        platform: 'crossbrowsertesting',
        os: 'Windows',
        osver: '7',
        bname: 'firefox'
      }
      results = SelRunner::Platforms.select_platforms(args)
      #puts "Selected Platforms: #{JSON.pretty_generate(results)}"
      results.each do |osb|
        puts "OS: #{osb[:os]}-#{osb[:osver]} Browsers: #{osb[:Browsers].length}"
      end
    end # end filtered list check

    it 'Gets a filtered list', filtersauce: true do
      args = { # These values are case sensitive
        platform: 'saucelabs',
        os: 'windows',
        #osver: '8',
        bname: 'internet explorer',
        bver: [8, 9, 10, 11]
      }
      results = SelRunner::Platforms.select_platforms(args)
      #puts "Selected Platforms: #{JSON.pretty_generate(results)}"
      results.each do |osb|
        puts "OS: #{osb[:os]}-#{osb[:osver]} Browsers: #{osb[:Browsers].length}"
      end
    end # end filtered list check

    it 'Runs on Chrome', crosstesting: true do
      args = {
        project: 'SelRunner Testing',
        target: 'https://test_url.com/test',
        #os: 'Windows',
        #osver: '8',
        bname: 'chrome',
        bver: [48,49,50,51,52,53,54],
        #jserrors: true, # check for javascript errors
        callback: method(:your_test_function_or_runner)
      }
      SelRunner::CoreManager.manage_test(args, 5)
    end

    it 'Tests the CrossBrowserTesting Integration', devlcb: true do
      args = {
        platform: 'crossbrowsertesting',
        project: 'SelRunner Testing',
        target: 'https://test_url.com/test',
        os: 'windows',
        osver: '8',
        bname: 'ie',
        #bver: [6, 7]
        callback: method(:your_test_function_or_runner)
      }
      args[:build] = '4.x.x_dvl'
      SelRunner::CoreManager.manage_test(args, 5)
    end

    it 'Tests the Saucelabs Integration', devlsl: true do
      args = {
        platform: 'saucelabs',
        project: 'SelRunner Testing',
        target: 'https://test_url.com/test',
        os: 'linux',
        #osver: '8',
        #bname: 'ie',
        # bver: [8]
        callback: method(:your_test_function_or_runner)
      }
      args[:build] = '4.x.x_dvl'
      SelRunner::CoreManager.manage_test(args, 5)
    end

  end # Test Runner Development
end # describe SelRunner
