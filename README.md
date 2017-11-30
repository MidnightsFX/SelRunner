# SelRunner

This is a bit of extracted code written probably too long ago for running a series of selenium tests against a selenium grid. I can't promise it is working, since its been quite a while since it was worked on, and this is not the complete code base.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'selrunner'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install SelRunner

## Usage

This gem is designed to be a middle man in to allow running built-out selenium tests by a variety of browsers, versions, etc. You will need provide configuration for your selenium grid provider (which is currently sourced from local config files aka- the gem install location)

```ruby
args = {
    platform: 'crossbrowsertesting',
    project: 'SelRunner Testing',
    build: '1.0.1'
    target: 'https://test_url.com/test',
    os: 'windows',
    osver: '8',
    bname: 'ie',
    #bver: [6, 7]
    callback: method(:your_test_function_or_runner)
}
SelRunner::CoreManager.manage_test(args, 5)
```

## Development

Development interfacing is done through rspec. To run a specific feature or test run rspec -t TagToRunThing

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
