### urbot-ai

This is a simple ai interface to OpenAI's text-davinci-003 model.
It works as a %gato thread, so simply add your OpenAI key in the file at
line 69, drop the ai-bot.hoon file into your gato/ted folder, commit the
change, and start it with:

> :gato &add ['urbot' [%gato %ai-bot] !>("")]

Or run it from any other desk:

> :gato &add ['urbot' [%<some-desk> %ai-bot] !>("")]

Or with any other command:

> :gato &add ['mentat' [%<some-desk> %ai-bot] !>("")]

See https://github.com/midsum-salrux/gato For more instructions on %gato.


To use the chatbot in a goup chat simply type

> /urbot tell me something interesting about walnuts


Other notes: 
1. The current setup only answers questions from the ship running
urbot-ai.  This can be changed at line 54. 
2. Due to breaking changes in JSON parsing with 413 I have included
the code for 413 and 414+, currently the 413 code is commented out 
at lines 81 and 101.
