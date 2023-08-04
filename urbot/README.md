## Laurel - An Urbit Chatbot

Laurel is an interface to various AI models.  Specifically it
interfaces with replicate models (although it can be tuned for OpenAI 
or inference/huggingface if required).  
Currently image generation and text generation models are supported.  You can find models to use at:
https://replicate.com/


### Installation

Create a new desk, copy in the files from this repository, and install in the usual way.  There is no front-end, so the landscape tile leads nowhere.


### Dependencies

Laurel requires that you have already installed %gato, and for
image generation an S3 bucket must be installed via Silo.  All generated images will be stored in your default S3 bucket, made public, and displayed in the group chat where your bot is operating. 

If you don't have an S3 bucket set up, images will still display, however they are temporary images stored on the replicate.com server, and will be unavailable after 24 hours.


### Starting a chatbot

Start a gato thread as follows:
```
> :gato &add [<bot-name> [<desk> <thread-file>] !>([<bot-type> <model> <auth> <timeout> <tokens>])]
```

timeout and tokens are optional values, if you are not using them simply use ~
* specify timeout, in seconds, as `[%timeout @ud] or ~  (default is 60s)
* specify tokens (maximum output tokens) as `[%tokens @ud] or ~ (default is the model's default)

Examples (assuming the laurel.hoon thread file is in a desk called laurel)
```
> :gato &add ['Talktome' [%laurel %laurel] !>([%text-generation '6282abe6a492de4145d7bb601023762212f9ddbbe78278bd6771c8b3b2f2a13b' 'xxxxxxxxxxxxxxxxxxx'] ~ `[%tokens 1.000])]
> :gato &add ['DrawSomething' [%laurel %laurel] !>([%image-generation 'ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4' 'xxxxxxxxxxxxxxxxxxx'] `[%timeout 120] ~)]
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


### Using the chatbot

In a Group chat access the chatbot like so:
```
> /Talktome Once upon a time on an Urbit ship...
> /DrawSomething A photorealistic image of an Urbit ship
```

####  Other notes: 
1. The current setup answers questions from any ship that can access your group chat.
If you want a chatbot that only answers your questions this can be changed at line 17 in ted/laurel.hoon.
2. Due to breaking changes in JSON parsing with 413 I have included the code for 413 and 414+,
comment out whichever is unnecessary.


####  Thanks:

Thanks to ~nocsyx-lassul for providing the S3 hoon code that allows upload and display of images.