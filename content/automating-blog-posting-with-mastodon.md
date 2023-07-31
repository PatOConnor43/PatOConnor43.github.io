---
title: "Automating Blog Posting With Mastodon"
date: 2023-07-29T20:00:00-07:00
---

I've recently been being a little more active on Mastodon and I've also taken a new interest in getting this blog off the ground.
(Last weekend I finally got the DNS issue fixed up so you can use my actual domain https://🆒🆒🆒.ws).

Anyway, this Saturday morning I thought, "Why don't I automate it?" I already have the deploy automated with Github Actions. Why not save my self 3 seconds posting it to Mastodon by spending a couple hours learning how the Mastodon API works? 😅

## So what's the plan?
- Look at the Mastodon docs to see how the API works
- Write a script that posts a new status for the recently published blog post
- Run that in a scheduled Github Action

Easy right?

## Let's look at the docs
Here's the documentation for creating a new status[^1]. That was easy, but how about authentication? That always seems to take me the longest. This is the page I initially found[^2] (<-- Not as helpful). This talks about creating an application, authentication code flow(?), grant types(?). 

Let's try to break it down and I'll try to explain why this wasn't as helpful as I wanted it to be.

Let's start by making our new application. On my instance this url is:
https://hachyderm.io/settings/applications

You should be able to go to the same path on your instance. After clicking "New Application", you should be greeted by a page like this:

![A screenshot of the New Application page. There are fields for name, website, redirect URI, and scopes](https://github.com/PatOConnor43/PatOConnor43.github.io/assets/6657525/118fe6ad-e2d6-40e9-8eaa-bf6e38c5b98d)

In my case, I called this Application "Mastodon Poster" without any change to the website or redirect URI. Since I only want this Application to post statuses I also only gave it the `write:statuses` scope.

Now that we have an Application, let's try to figure out what's going on with authentication. Based off the token spec[^3], it looks like there are 3 ways to authenticate with the Mastodon API:

- Authorization Code flow
- Password grant flow
- Client credentials grant

Based on previous API experience, I don't think I really want Authorization Code Flow. That's typically used as a way to allow a user to log in using a browser and then take a code and act on behalf of the user. We want this to be totally headless.

Password grant flow sounds gross. I really don't want to use my actual password to authenticate.

Client credentials _might_ work. What happens if we try that? Well we'd make a request like this[^2]:
```bash
curl -X POST \
	-F 'client_id=your_client_id_here' \
	-F 'client_secret=your_client_secret_here' \
	-F 'redirect_uri=urn:ietf:wg:oauth:2.0:oob' \
	-F 'grant_type=client_credentials' \
	https://mastodon.example/oauth/token
```

Okay that looks like it worked. You should have a response that looks like:
```bash
{
  "access_token": "ZA-Yj3aBD8U8Cm7lKUp-lm9O9BmDgdhHzDeqsY8tlL0",
  "token_type": "Bearer",
  "scope": "read",
  "created_at": 1573979017
}
```

Let's try to use that access_token to make a status:
```bash
    curl -X POST -H "Authorization: Bearer $access_token" "$MASTODON_DOMAIN/api/v1/statuses" -d $'
    {
        "status": "test"
    }
'
```

> {"error":"This method requires an authenticated user"}

😮‍💨

What?

Okay, so turns out we can't use client_credentials either because that grant_type isn't meant to act on behalf of a user. It's more for making general queries against your instance. So I spent an hour or so looking for other options, because I _really_ didn't want to use my password. Then I finally found this GitHub issue[^4].

> If you want to, you can also log in manually and create a new application via Settings > Development, then copy-paste the generated access token into your config file or environment variables or whatever.

Oh? We haven't talked about this yet, but when you made an application there should be 3 IDs there. A client ID, a client secret, and an Access Token. 
![A screenshot with an arrow pointing at the value for the "Your access token" field](https://github.com/PatOConnor43/PatOConnor43.github.io/assets/6657525/a54417e8-3abc-48dc-8fec-f569889cfc1a)


We haven't tried anything with the Access Token. So it sounds like this person says we can do something like this?
```bash
    curl -X POST -H "Authorization: Bearer $access_token" "$MASTODON_DOMAIN/api/v1/statuses" \
        -F "status=Test
```

Oh hey! That worked!

Alright let's wrap this up in a script we can call in GitHub Actions. You can find the most recent version of that in my blog repo here[^5].


## Time for some Action 😎
A key consideration for this whole thing was that I wanted it to be mostly stateless. I don't want to have to worry about double posting a blog post if I fix a small typo on master. So the current plan is:
- Allow current github-pages deployment to happen as normal
- Create a separate scheduled workflow that runs once per day
- In this workflow make a request to my rss feed to see if something was published in the last day
- If it was, post a status on Mastodon

I think there's plenty of other ways to do it but that's what I'm going with for now.

Let's get started on that workflow. Here's the cron syntax for running this at 9 AM every day
```yaml
name: Publish Mastodon status if new blog is available
on:
  schedule:
    - cron: "0 9 * * *"
```

> I didn't realize this was GMT, but we can change that later.

Based off the script we need a couple dependencies:
- `jq` to parse json
- `hq` to parse html (the rss feed is xml)
- checkout the branch so we can run the script

Let's drop the checkout action in here because that's easy:
```yaml
jobs:
  publish:
    environment:
      name: mastodon-poster
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
```

Next, let's install `jq`. It turns out there's an existing action for this:
```yaml
      - name: 'Install jq'
              uses: dcarbone/install-jq-action@v1.0.1
```
This has some additional options if you want to specify a specific version. I don't care about that in this case though.

Lastly, we need to get `hq` installed. You can find that project here[^6]. I didn't _see_ a predefined action for this so let's just try getting this installed ourselves. Here's what I came up with:
```yaml
      - name: 'Install hq'
        run: |
          _version='1.0.1'
          # Probably this is the right arch right?
          _dl_url="https://github.com/orf/hq/releases/download/v$_version/hq-Linux-x86_64.tar.gz"
          _dl_path="$RUNNER_TEMP/hq.tar.gz"
          wget -O- "$_dl_url" > "$_dl_path"
          tar -xzf "$_dl_path" --directory $RUNNER_TEMP
          _executable_path="$RUNNER_TEMP/hq"


          echo "Creating tool cache directory $RUNNER_TOOL_CACHE/hq"
          mkdir -p "$RUNNER_TOOL_CACHE/hq"

          echo "Installing into tool cache:"
          echo "Src: $_executable_path"
          echo "Dst: $RUNNER_TOOL_CACHE/hq/hq"
          mv "$_executable_path" "$RUNNER_TOOL_CACHE/hq/hq"

          chmod +x "$RUNNER_TOOL_CACHE/hq/hq"

          echo "Adding $RUNNER_TOOL_CACHE/hq to path..."
          echo "$RUNNER_TOOL_CACHE/hq" >> $GITHUB_PATH
```

Nice, hopefully that should pull the right architecture for the runner and then add it on the path. Another option would probably be to use an existing Rust image and then use `cargo install html-query`.

Lastly, let's run our publish script:
```yaml
      - name: 'Run publish script'
        env:
          MASTODON_ACCESS_TOKEN: ${{ secrets.MASTODON_ACCESS_TOKEN }}
          MASTODON_DOMAIN: https://hachyderm.io
        run: bash ./scripts/publish.sh
          ./scripts/publish.sh
```

Notice `MASTODON_ACCESS_TOKEN` variable coming from `secrets.MASTODON_ACCESS_TOKEN`. You'll need to set this up as a secret in GitHub. You can do that by going to Settings > Environment > New Environment and then finding this tab and adding the new secret:
![A Screenshot showing a panel with the MASTODON_ACCESS_TOKEN added as a secret](https://github.com/PatOConnor43/PatOConnor43.github.io/assets/6657525/8048a82c-ec5e-44b2-b8cd-88b9eefbfd2a)

Remember to assign this environment when you're defining your job:
```yaml
jobs:
  publish:
      environment:
            name: mastodon-poster
```

Here's a link to the current version of the workflow[^7]

## Wrapping up
At the time of writing this post I haven't actually run this GitHub Action yet 😅 I set it up to run on a schedule and I thought it'd be fun if I did it right on the first try 😬 Maybe I'll put a small update if it worked out.

*Edit: It didn't work first try, but it did work second try after I fixed the date command flags I was using. Turns out they're different between Mac and Linux.*

## References
[^1]: https://docs.joinmastodon.org/methods/statuses/#create
[^2]: https://docs.joinmastodon.org/client/token/
[^3]: https://docs.joinmastodon.org/spec/oauth/#token
[^4]: https://github.com/mastodon/documentation/issues/1014
[^5]: https://github.com/PatOConnor43/PatOConnor43.github.io/blob/master/scripts/publish.sh
[^6]: https://github.com/orf/hq
[^7]: https://github.com/PatOConnor43/PatOConnor43.github.io/blob/master/.github/workflows/mastodon_publish.yaml
