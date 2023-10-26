## %mentat - An Urbit Chatbot

%mentat is an interface to a selection of AI models.  It is designed to work specifically 
with replicate models (https://replicate.com), however, with minor tweaks it can be tuned 
for OpenAI or inference/huggingface models if required.

It currently supports, queries, chat, image generation, and todo list management.  In progress
are message notifications, image generation for %turf and counter-prompted reminders.

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
```

Currently valid centags are:
%chat
%query 
%img 
%todo
%remind

###  Other notes: 

1. A %public chatbot will be available to **anyone** in a group chat to which your ship has access.
Public chatbots are ideally suited to run off their own moon, which has access to the group chats that are
relevant to it.
2. A %private chatbot will only answer questions from you, and is more suited to running on your main ship.


####  Thanks:

Thanks to ~nocsyx-lassul for providing the S3 hoon code that allows upload and display of images.
