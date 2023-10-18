:: This is the parent thread for %mentat - it takes input from 
:: %gato, uses the bot, centag, (and label in future) to determine
:: which model should be running with which child thread, and then
:: farms out the work to that child thread.
:: It takes a `reply` and `interaction` in return, sending the reply
:: to %gato for the user, and sending the interaction to the mentat
:: app to be stored for context purposes.

/-  spider, *gato, *s3, *mentat
/-  d=diary, g=groups, c=chat, ha=hark
/+  *strandio, aws, *mentat, regex
=,  strand=strand:spider
=/  m  (strand ,vase)
^-  thread:spider
|=  arg=vase
^-  form:m
=/  =bird  !<(bird arg)

=/  =bot-id  !<(bot-id vase.bird)

::
:: Set up the model
::
=/  msg-origin=@p  author.memo.bird
=/  flag=flag:c  flag.bird  :: this is [ship term] and identifies the chat

;<  our=@p         bind:m  get-our
;<  now=@da        bind:m  get-time

=/  question  text.bird

::
:: Check centags to route question to correct child thread
::

::TODO - error handling for centags that don't exist, currently silently fails
=/  cntg-txt  (run:regex "%[a-z]+" (trip question))                                   :: the first "%blah" in the question
=/  cntg  ?:(=(cntg-txt ~) %default `@tas`(crip (oust [0 1] q.->+:(need cntg-txt))))  :: actual centag  
=/  centag  (centag cntg)

:: Map centag to sub-thread name
=/  cntg-tpl
  :~  [%chat %mentat-chat]
      [%clear %mentat-chat]
      [%query %mentat-query] 
      [%img %mentat-image] 
      [%comment %mentat-note]
      [%edit %mentat-note]
      [%note %mentat-note]
      [%default %mentat-query]
  ==

::
:: Currently label is not used, and is always 'default'
::
=/  label  'default'

::
:: Check for model existence, exit nicely if non-existent
::
;<  scry-models=update  bind:m  (scry update `path`['gx' 'mentat' 'get-models' bot-id 'noun' ~])

?:  =(+:scry-models ~)
  ~&  "No models available for this bot."
  (pure:m !>(['No models available for this bot, check your setup.' vase.bird]))
=/  bot-models  (models +:scry-models)
?.  (~(has by bot-models) centag)
  ~&  "No model available for this centag."
  (pure:m !>(['No model available for this centag, check your setup.' vase.bird]))
=/  mod-map  (~(got by bot-models) centag)
?.  (~(has by mod-map) label)
  ~&  "No model available for this label."
  (pure:m !>(['No model available for this label, check your setup.' vase.bird]))

:: Have a model for this bot/centag/label, scry for details
;<  sub-model=update  bind:m  (scry update `path`['gx' 'mentat' 'get-model' bot-id centag 'default' 'noun' ~])
?:  =(+:sub-model ~)
  ~&  "No model available for this bot-id/centag/label."
  (pure:m !>(['No model available, check your setup.' vase.bird]))
=/  model  (inference-model +:sub-model)

::;<  ~                  bind:m  (check-add-model [bot-id centag 'default' model])

::
:: Run the child-thread
::
=/  cntg-map  (malt (limo cntg-tpl))
=/  child-ted  (~(got by cntg-map) centag)

::TODO - fix all sub-threads input data
::;<  query-vase=vase    bind:m  (custom-await-thread child-ted !>([bird centag]))
;<  query-vase=vase    bind:m  (custom-await-thread child-ted !>([bird centag model]))
=/  query-result  !<([@tas [@tas reply @t]] query-vase)
=/  return-text  ?:(|(=(-.query-result %fail) =(+<.query-result %error)) '%llm-error' +>+.query-result)

:: send centag, label and interaction, that will be easier to unpack
=/  log-user=interaction
  :*  %user
      question
      now  
      model-id.model
  ==

=/  log-ai=interaction
  :*  %ai
      return-text
      now
      model-id.model
  ==

:: Log question and response
;<  ~            bind:m  (poke-our %mentat [%mentat-action !>([%add-interaction [bot-id centag log-user 'default']])])
;<  ~            bind:m  (poke-our %mentat [%mentat-action !>([%add-interaction [bot-id centag log-ai 'default']])])

:: Return response to %gato
=/  return-msg  +.query-result
(pure:m !>([+<.return-msg vase.bird]))
