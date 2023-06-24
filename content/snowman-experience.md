---
title: "A helpful little Snowman"
date: 2023-06-23T22:57:57-07:00
draft: false
tags: ["cli", "rust"]
---


Snowman is a CLI application that I've been working on to make my life a little easier.

https://github.com/PatOConnor43/snowman

### So What's Snowman?
During my day job, I work with a lot with APIs. Sometimes I'm writing and testing them, sometimes I'm using them to give feedback to other developers. The problem I had though was managing all those variables! I have at least one set of credentials for each environment I work in and I might even have multiple sets with different scopes in order to test different things. You might say to yourself:
> This is a solved problem. Can't you just use something like environments in Postman?

You're right!

I like Postman, I really do. _But_ I also really like the terminal. Writing up a little bash script so I can continuously iterate on and examine the output of a request is how I like to work. So, we're at a bit of a crossroads. Do I use Postman because my team and I can centralize variables and knowledge, _OR_ do I continue to use curl without taking advatage of consistent environment variables?

TRICK QUESTION! LET'S DO BOTH!

Snowman allows me to retrieve all the environments that I have access to, pick one, and then set them as environment variables in my terminal. This allows me to use them in standard scripts that I keep on my machine. Let's look at some examples.

![Screenshot showing a fuzzy matcher with the input "Worksp". The available results are, "My Workspace" and "Aaron's Workspace".](https://github.com/PatOConnor43/PatOConnor43.github.io/assets/6657525/8fc7e5b9-4c0d-419c-b538-41d8a2b7ee2a)

After configuring Snowman for the first time, you can use `snowman activate` to see a list of Workspaces you have access to. This selector does fuzzy matching so you can get to what you need quickly. Selecting a Workspace will show you the list of environments:

![Screenshot showing a lit of 11 environments](https://github.com/PatOConnor43/PatOConnor43.github.io/assets/6657525/9c87abe4-ef91-4aab-bd5b-3560f1c8568a)

As you can see, there's a lot of them. (And maybe I should come up with some slightly more standard naming 😅.) The actual name of the environment is what the selection starts with. The name enclosed in brackets represents the fork it came from. This allows me to keep in sync with any changes to those generic environments, while personalizing them as I want. Next, once I select one, the name of the environment will be populated on my prompt:

![Screenshot showing zsh prompt that includes "⛄ Prod Workiva Testing [prod]"](https://github.com/PatOConnor43/PatOConnor43.github.io/assets/6657525/94f9ea19-79db-45d4-ace6-414173b02c6f)

That's accomplished by a custom [spaceship prompt plugin](https://github.com/PatOConnor43/snowman/tree/master/zsh) I wrote.

Now that I have these standard environment variables set I can use them in scripts to automate fetching a JWT, making requests, waiting for an async job to finish, etc. Then when I'm finished with this environment I can close the shell with Ctrl-D and be back in the parent shell.


### Wrapping up
At this time Snowman is still alpha and I reserve the right to make breaking changes. If you think you can use this too, maybe we can talk about what changes would be necessary for an actual stable release. Thanks for reading!
