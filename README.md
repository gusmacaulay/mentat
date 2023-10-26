## %mentat - An Urbit Chatbot

%mentat is an interface to a selection of LLMs.  It is designed to work specifically 
with Replicate.com models.

It currently supports queries, chat, image generation, todo list management and reminders, 
with %turf integration for images, and notifications under construction.

You can find models to use at https://replicate.com/


## Install from Urbit

Install %mentat and %mentat-ui from `~tagrev-lacmur-lomped-firser/mentat`


### Dev Installation

Assuming you are installing from this GitLab repo, clone the repository locally and install into an
empty %mentat desk.  The glob, and instructions for the UI can be found at https://gitlab.com/thuser/mentat-ui


### Dependencies

%mentat requires that you have already installed %gato, and for long term image generation an S3 bucket must be installed via Silo.  All generated images will be stored in your default S3 bucket, made public, and displayed in the group chat where your bot is operating.

If you don't have an S3 bucket set up, images will still display, however they are temporary images stored on the replicate.com server, and will be unavailable after 24 hours.


### Starting a chatbot

%mentat's chatbots utilise %gato (https://github.com/midsum-salrux/gato) for interfacing with Groups Chat, however the UI now handles all the  thread management.  There is no need to start the threads %mentat runs using %gato.


### Available models

#### Image Generation

* Recommended: https://replicate.com/prompthero/openjourney
* Most diffusion models will work: https://replicate.com/collections/diffusion-models
* Some of these may work as well: https://replicate.com/collections/text-to-image

#### Text Generation

* Recommended: https://replicate.com/stability-ai/stablelm-tuned-alpha-7b
* Most of the text models should work: https://replicate.com/collections/language-models

#### Code Generation

* Some code generation models such as https://replicate.com/lucataco/replit-code-v1-3b will run when set up as a text generation model.

#### Chat Mode

* You can use chat models such as https://replicate.com/a16z-infra/llama-2-13b-chat


### Using the chatbot

In your Groups Chat use your bot-id to talk to the bot and direct your query to the appropriate
model with a centag, like so:

```
/mentat %query Once upon a time on an Urbit ship...
/mentat %img A photorealistic image of an Urbit ship
/mentat %remind in five minutes remind me to take a coffee break
/mentat %todo I need to remember to take my passport this afternoon
```

Currently valid centags are:
%chat
%query 
%img 
%todo
%remind

#### %chat
The chat model keeps track of your ongoing conversation with the LLM using it as context for subsequent interactions.  Use is quite straightforward, the same as you would use ChatGPT or any other chatbot.
Remember to use the %chat centag for each interaction.

#### %query
Query provides longer answers to questions than the chat model (currently set to avuncular professor mode), but it does not retain context from previous interactions, so every question is a standalone query.

#### %img
Just what is says on the box.  Images are stored in your current S3 bucket if you have one set up and linked to your Urbit ship.

#### %todo
Todo builds a daily todo list in a notebook in the same group as your current chat.  Todo builds a new todo list if it can't find a current one, and it reads in previous conversation data and the most recent daily todo list as context.

Tasks in the note are shown with checkboxes so you can mark them complete as you go through your day.

#### %remind
Remind sets reminders for you that will pop up in your chat after the given interval or at the given time.  Remind can even set repeated reminders at pre-defined fixed intervals (minutely, daily, hourly, weekly).  To get the best behaviour from this bot you need to use AM/PM time rather than 24hour time.

Currently the bot knows the current date and time, but it does not have the users local time-zone as context, so all times should be interpreted as UTC.

Some basic usage patterns to consider:
* Once-off, interval    `/mentat %remind in fifteen minutes tell me to take a break`
* Once-off, time of day `/mentat %remind at 8am tomorrow tell me to go outside`
* Repeated              `/mentat %remind starting in on hour, every hour, remind me to look at something twenty feet away for twenty seconds`


###  Other notes: 

1. A %public chatbot will be available to **anyone** in a group chat to which your ship has access.
Public chatbots are ideally suited to run off their own moon, which has access to the group chats that are
relevant to it.
2. A %private chatbot will only answer questions from you, and is more suited to running on your main ship.


####  Thanks:

Thanks to ~nocsyx-lassul for providing the S3 hoon code that allows upload and display of images.
