# SuperfeedrEngine

This Rails engine lets you integrate [Superfeedr](https://superfeedr.com) smoothly into your application. It lets you consume RSS feeds using Superfeedr's [PubSubHubbub](http://documentation.superfeedr.com/subscribers.html#webhooks) API.

The engine relies on the [Rack Superfeedr](https://rubygems.org/gems/rack-superfeedr) library for subscribing, unsubscribing, listing and retrieving subscriptions. It creates webhook that yields notifications to your feed class.

Most of the gory details are handled for you: building webhook URLs, using secrets and handling signatures verification. All you need to do is build a class to store your feeds and handle notifications.

## Compatibility

This engine is only to be used with [XML feeds subscriptions](http://documentation.superfeedr.com/subscribers.html#xml-based-feeds).

It is built and tested for Rails 4.0-Rails 5.2

## How-To

### Install this gem

In your Gemfile, add `gem 'superfeedr_engine'` and run `bundle update`.

### Build your feed class

SuperfeedrEngine expects you to configure a class, usually an ActiveRecord model, to store your feeds and receive notifications from the webhook.

#### Add the attributes expected by the webhook:

* `url`: should be the main feed url
* `id`: a unique id (string) for each feed (can be the primary index in your relational table)
* `secret`: a secret which should never change and be unique for each feed. It must be hard to guess. (An MD5 or SHA1 string works best.)

#### Write your `:notified` method

Your class also must have a `:notified` method which will be called by the engine when new content is received by the webhook. You'll probably want to save the content of this notification to your database.

The method can have 1, 2 or 3 arguments:

* The first (required) argument is Ruby hash with the parsed content of the notification.
* The second (optional) argument is the raw text notification.
* The third (optional) argument is the raw request object of the notification.

By default, this engine will subscribe to Superfeedr using the `JSON` format. Please check our [JSON schema](http://documentation.superfeedr.com/schema.html#json) for more details.

### Configure

Create an initializer (`config/initializers/superfeedr_engine.rb`) with the following:

    # Use the class you use for feeds. (Its name as a string)
    SuperfeedrEngine::Engine.feed_class = "Feed"

    # Base path for the engine - don't forget the trailing "/"
    SuperfeedrEngine::Engine.base_path = "/superfeedr_engine/"

    # Superfeedr username.
    SuperfeedrEngine::Engine.login = "demo"

    # A valid Superfeedr token. Make sure it has the associated rights you need (subscribe, unsubscribe, retrieve, list).
    SuperfeedrEngine::Engine.password = "8ac38a53cc32f71a6445e880f76fc865"

    # Your hostname (no protocol - just the URL). Used for webhooks!
    # This will be different for each environment and can be read from an environment variable or an
    # environment-specific config file.
    SuperfeedrEngine::Engine.host = "www.myapp.com"
    # OR
    SuperfeedrEngine::Engine.host = "5ea1e5ed83bf5555.a.passageway.io"

    # Protocol/port for your webserver
    SuperfeedrEngine::Engine.scheme = "https"
    # OR
    SuperfeedrEngine::Engine.scheme = "http"
    # OR (custom port)
    SuperfeedrEngine::Engine.scheme = "http"
    SuperfeedrEngine::Engine.port = 12345

### Mount

Update routes in `config/routes.rb` to mount the Engine.

    # This path is configured in your initializer.
    mount SuperfeedrEngine::Engine => SuperfeedrEngine::Engine.base_path

### Profit! (Not really - you should actually just start using the engine!)

You can perform the following calls:

    # Will subscribe your application to the feed object and will retrieve its past content yielded as a JSON string in body.
    body, ok = SuperfeedrEngine::Engine.subscribe(feed, {:retrieve => true})

    # Will retrieve the past content of a feed (but you must be subscribed to it first)
    body, ok = SuperfeedrEngine::Engine.retrieve(feed)

    # Will stop receiving notifications when a feed changes.
    body, ok = SuperfeedrEngine::Engine.unsubscribe(feed)

### Development note:

You probably use localhost in your development environment, which means that your Rails application is not reachable by Superfeedr's servers and won't be able to receive webhook notifications.

To overcome this and fully test your integration with this engine before deployment, consider one of the following tools to expose your dev environment to the web using temporary URLs:

- [passageway](https://www.runscope.com/docs/passageway)
- [forwardhq](https://forwardhq.com/)
- [ngrok](https://ngrok.com/)
