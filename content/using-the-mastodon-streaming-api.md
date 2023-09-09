---
title: "Using the Mastodon Streaming API"
date: 2023-09-09T15:30:00-07:00
tags:
  - rust
  - API
  - mastodon
  - fediverse
---

I've been thinking about trying to write a Mastodon bot that can do something "useful". Unfortunately, I don't know what that idea is right now 😅 but I do think it could involve direct messaging the bot. But that raises the question, "How would the bot know that it has an unread message"? Well, it could continuously poll the instance to get unread messages. This _feels_ pretty wasteful, especially since our bot probably won't have very much traffic. It would be really nice if we could just get an event and then start doing some work. **This is where the streaming API comes in.**

> TL;DR you can find the code here https://github.com/PatOConnor43/mastodon-websocket-rust-example/tree/master

### Let's start with some research
Unfortunately, the streaming API isn't enabled on every instance. If you want to follow-along with your instance, you should start by checking if it's enabled. We can do that pretty simply with `curl` and `jq`:
```
curl https://botsin.space/api/v2/instance | jq '.configuration.urls.streaming'
```
This tells me that the websocket url for botsin.space is `wss://botsin.space`. Great!

Let's take a peek at the Mastodon Streaming API docs[^1] as well. The API actually allows you to make simple HTTP requests if you prefer, but we'll be jumping down to the websocket section[^2]. It looks like if we want to subscribe to direct message events, we'll want a URL that looks something like: `wss://botsin.space/api/v1/streaming?stream=direct&access_token=<ACCESS_TOKEN>`. There are a lot of different types though. You can see all of them on this same page, some of them are even public and don't require an access_token at all. For the `direct` type, we'll need that so let's make a new Application.

### Let's get an Access Token
- Go to the settings on your instance
- Click 'Development', then 'New Application'.
- Give this new application a name and (optionally) a link to a website.
- Refer to the [OAuth description for the event](https://docs.joinmastodon.org/methods/streaming/#direct) to find out what scope you need.
- You'll need the value from "Your access token" to pass as the environment variable.

### Putting it all together
Now that we've done our research and gotten an access token you can clone/fork/copy this repo[^3] to start playing with the websocket. If you just want to immediately start listening to direct messages you can run something like this:
`STREAMING_DOMAIN="wss://botsin.space" STREAM=direct ACCESS_TOKEN=<YOUR_ACCESS_TOKEN> cargo run`

### What next?
Well you could deploy it somewhere. I really like https://fly.io.

This probably also isn't the most reliable solution. If you remove the `if msg.is_text()` check you should see heartbeat messages every once in a while. It'd probably be a good idea to close the connection and re-establish it if you stop receiving those. In this case you might want to use an http request to catch any unread messages that you might have missed in the meantime.


**References**
[^1]: https://docs.joinmastodon.org/methods/streaming
[^2]: https://docs.joinmastodon.org/methods/streaming/#websocket
[^3]: https://github.com/PatOConnor43/mastodon-websocket-rust-example
