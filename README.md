## mentat - An Urbit Chatbot

mentat is an interface to various AI models.  Specifically it
interfaces with replicate models (although it can be tuned for OpenAI 
or inference/huggingface if required).  
Currently image generation and text generation models are supported.  You can find models to use at:
https://replicate.com/


### Installation

Create a new desk, copy in the files from this repository, and install in the usual way.  There is no front-end, so the landscape tile leads nowhere.


### Dependencies

mentat requires that you have already installed %gato, and for long term image generation an S3 bucket must be installed via Silo.  All generated images will be stored in your default S3 bucket, made public, and displayed in the group chat where your bot is operating.

If you don't have an S3 bucket set up, images will still display, however they are temporary images stored on the replicate.com server, and will be unavailable after 24 hours.


### Starting a chatbot

Start a gato thread as follows:
```
> :gato &add [<bot-name> [<desk> <thread-file>] !>([<bot-view> <bot-type> <model> <auth> <timeout> <tokens>])]
```

Models may be specified as either public or private.
* %public models respond to anyone, %private models only respond to the ship on which they're running.

Valid model types are `%text-generation`, `%image-generation`, and `%conversation`

timeout and tokens are optional values, if you are not using them simply use ~
* specify timeout, in seconds, as `[%timeout @ud] or ~  (default is 60s)
* specify tokens (maximum output tokens) as `[%tokens @ud] or ~ (default is the model's default)

Examples (assuming the mentat.hoon thread file is in a desk called mentat)
```
> :gato &add ['Talktome' [%mentat %mentat] !>([%public %text-generation '6282abe6a492de4145d7bb601023762212f9ddbbe78278bd6771c8b3b2f2a13b' 'xxxxxxxxxxxxxxxxxxx'] ~ `[%tokens 1.000])]
> :gato &add ['DrawSomething' [%mentat %mentat] !>([%private %image-generation 'ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4' 'xxxxxxxxxxxxxxxxxxx'] `[%timeout 120] ~)]
```

See https://github.com/midsum-salrux/gato For more instructions on %gato.


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
* To clear a conversation and start afresh use the clear command in your Groups chat
```
/Chatwithme clear
```

### Using the chatbot

In a Groups chat access the chatbot like so:
```
/Talktome Once upon a time on an Urbit ship...
/DrawSomething A photorealistic image of an Urbit ship
```

####  Other notes: 

1. A %public chatbot will be available in **any** group chat to which your ship has access.
Public chatbots are ideally suited to run off their own moon, which has access to the group chats that are
relevant to it.
2. A %private chatbot will only answer questions from you, and is more suited to running on your main ship.


####  Thanks:

Thanks to ~nocsyx-lassul for providing the S3 hoon code that allows upload and display of images.