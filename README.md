# Zabbix::Client

This is a simple client of Zabbix API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zabbix-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zabbix-client

## Usage

```ruby
require 'zabbix/client'

client = Zabbix::Client.new('http://localhost/zabbix/api_jsonrpc.php')
client.user.login(user: 'Admin', password: 'zabbix')
p client.apiinfo.version #=> "2.0.12"
```

## Contributing

1. Fork it ( https://github.com/winebarrel/zabbix-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
