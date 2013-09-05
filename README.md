[![Gem Version](https://badge.fury.io/rb/smess.png)](http://badge.fury.io/rb/smess)
[![Code Climate](https://codeclimate.com/github/eimermusic/smess.png)](https://codeclimate.com/github/eimermusic/smess)

# Smess - A mess of SMS messaging

This is a messy SMS messenger supporting every aggregator I have gotten my hands on.

In 2008 I started working on SMS and MMS messaging applications. Within the first 2 months it was apparent that I needed an abstraction that could route messages to different aggregators (messaging providers) to support different countries. No one API supports the entire word in any useful way.

This is that abstraction finally cleaned up (a little) enabling it to be public. Everyone from mBlox to  Clickatell. The following 7 aggregators are supported.

* Auto - will automatically select the best option for each country. Most often using Global Mouth.
* Clickatell - http://www.clickatell.com
* Global Mouth - http://www.globalmouth.com
* Iconectiv - http://www.iconectiv.com
* IPX - http://www.ipx.com (who knows what'll happen to them)
* mBlox - http://www.mblox.com
* SMS Global - https://www.smsglobal.com
* Twilio - http://www.twilio.com

There is also a _test_ aggregator that you should set evrything to use when running tests in your code.


## Who should use this?

* You want to send SMS messages from Ruby code.
* You want one API to call regardless of which aggregator you switch to.
* You may even want to do it to people in multiple countries using the "best" aggregator for each.

## Why?

It may be old and crappy but it has served many millions of SMS messages in production across all continents of the globe. Being in production it has some nice touches that may serve you well.

There is automatic fallback delivery in places where it really makes a difference. Delivery reliability, particularly in the US, is appalling and being able to reduce non-deliveries by more than half is a big deal when sending transactional messages.

The aggregator outputs are a very simple plugin system so you can subclass, modify and write your own. The protocol is just one method accepting a single argument.

```ruby
module Smess
  class Example

    def deliver_sms(sms)
      # Do work and return a hash like this one
      {
      :response_code => '-1',
        :response  => {
          :temporaryError =>'true',
          :responseCode => '-1',
          :responseText => 'Delivery not implemented.'
        }
      }
    end

  end
end
```



## Installation

### Get the gem going

```
gem "smess"
```
or
```
gem install smess
```

### Set a hundred ENV vars
All credentials, and other account-sepcific settings, have been extracted into ENV vars allowing you to set these any way you like. I use Dotenv but Figaro or other env manager should work equally well. As should setting them any other way.

All ENV variables used by Smess are listed in the file .env. You only need to define the aggregator credentials you actually use though.

## Usage

```ruby
sms = Smess.new(
  to: '46701234567', # phone number in normalized msisdn format
  message: 'Test SMS', # Message text
  originator: 'TestSuite', # originator, sender id. This has many names. Outside the US this can usually be set to whatever you like.
  output: "test" # Name of the output plugin to use. Defaults to auto select.
)
results = sms.deliver
puts result
```

Look in the project test folder for end-to-end test files showcasing normal usage.

There are also convenience methods patched onto String to normalize phone numbers.
```ruby
"\r\n +(070-123)\n45 67\n".msisdn(46)
#=> 46701234567
```
US numbers cannot be banged into shape as much as most international numbers can. This is due to area codes not conforming to leading 0 as most other countries do. Tt is actually not terribly simple to see the difference between the US area code 850 and the North Korean country code 850. :)

More usage is pretty clear from the specs.

## Disclaimers

Being Swedish, disclaimers are required.

* Much of the code is old and crappy. It started in 2008 in PHP, ported to Ruby in 2010.
* There are OK specs for the simple stuff. No specs for the more error-prone API calls. There are live tests that can be run to verify end-to-end messaging, though.
* Does not handle the other part of messaging... accepting and processing Delivery Reports. (I have the code... it is just not extracted yet.)



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request