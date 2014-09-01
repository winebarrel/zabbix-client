# Zabbix::Client

This is a simple client of Zabbix API.

[![Gem Version](https://badge.fury.io/rb/zabbix-client.svg)](http://badge.fury.io/rb/zabbix-client)
[![Build Status](https://travis-ci.org/winebarrel/zabbix-client.svg?branch=master)](https://travis-ci.org/winebarrel/zabbix-client)

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

Method call is a thin wrapper of the JSON-RPC.

JSON is created dynamically, it is checked on the server side.

```ruby
require 'zabbix/client'

client = Zabbix::Client.new('http://localhost/zabbix/api_jsonrpc.php')

# https://www.zabbix.com/documentation/2.0/manual/appendix/api/user/login
client.user.login(user: 'Admin', password: 'zabbix')

# https://www.zabbix.com/documentation/2.0/manual/appendix/api/apiinfo/version
p client.apiinfo.version #=> "2.0.12"

# https://www.zabbix.com/documentation/2.0/manual/appendix/api/template/getobjects
p client.template.getobjects(host: ['Template OS Linux'])
#=> [{"hostid"=>"10001",
#     "proxy_hostid"=>"0",
#     "host"=>"Template OS Linux",
#     ...

# https://www.zabbix.com/documentation/2.0/manual/appendix/api/hostgroup/delete
client.hostgroup.delete([9, 10])
```

### Use proxy

```ruby
Zabbix::Client.new(
  'http://localhost/zabbix/api_jsonrpc.php',
  proxy_host: 'hostname', proxy_port: 8080
)
```

### Basic auth

```ruby
Zabbix::Client.new(
  'http://localhost/zabbix/api_jsonrpc.php',
  basic_auth_user: 'username', basic_auth_password: 'password'
)
```

### Debug mode

```ruby
Zabbix::Client.new(
  'http://localhost/zabbix/api_jsonrpc.php',
  debug: true
)
```

## Related links

* [Zabbix 1.8 API reference](https://www.zabbix.com/documentation/1.8/api)
* [Zabbix 2.0 API reference](https://www.zabbix.com/documentation/2.0/manual/appendix/api/api)
* [Zabbix 2.2 API reference](https://www.zabbix.com/documentation/2.2/manual/api)
* [Zabbix 2.4 API reference](https://www.zabbix.com/documentation/2.4/manual/api)
