## Laurel - An Urbit Chatbot

Laurel is an interface to various AI models.  Specifically it
interfaces with huggingface/inference models (although OpenAI 
is also possible).  Currently image generation and text generation
models are supported.  You can find models to use at:
https://huggingface.co/models


### Installation

Create a new desk, copy in the files from this repository, and
install in the usual way.  There is no front-end, so it won't 
appear in Landscape.


### Dependencies

Laurel requires that you have already installed %gato, and for
image generation an S3 bucket must be installed via Silo.  All generated images will be stored in your default S3 bucket, made
public, and displayed in the group chat where your bot is operating. 


### Starting a chatbot

Start a gato thread as follows:
```
> :gato &add [<bot-name> [<desk> <thread-file>] !>([<bot-type> <model> <auth>])]
```

Examples (assuming the laurel.hoon thread file is in a desk called laurel)
```
> :gato &add ['Talktome' [%laurel %laurel] !>([%text-generation 'gpt2' 'Bearer xxxxxxxxxxxxxxxxxxx'])]
> :gato &add ['DrawSomething' [%laurel %laurel] !>([%image-generation 'Joeythemonster/anything-midjourney-v-4-1' 'Bearer xxxxxxxxxxxxxxxxxxx'])]
```

See https://github.com/midsum-salrux/gato For more instructions on %gato.


### Using the chatbot

In a Group chat access the chatbot like so:
```
> /Talktome Once upon a time on an Urbit ship...
> /DrawSomething A photorealistic image of an Urbit ship
```

####  Other notes: 
1. The current setup only answers questions from any ship that can access your group chat.
If you want a chatbot that only answers your questions this can be changed at line 102 in ted/laurel.hoon.
2. Due to breaking changes in JSON parsing with 413 I have included the code for 413 and 414+,
comment out whichever is unnecessary.
