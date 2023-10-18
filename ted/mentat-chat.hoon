::
:: %mentat sub-thread to process chat requests to LLM
::
/-  spider, *gato, *mentat, *mentat-chat
/+  *strandio, *mentat, *mentat-chat, regex
=,  strand=strand:spider
=/  m  (strand ,vase)
^-  thread:spider
|=  arg=vase
^-  form:m
:: bird is the complete data coming in from %gato, centag is the
:: incoming centag (useful if we have one sub-thread dealing with multiple centags)
:: model is the inference-model (now replicate model) that this child thread
:: will be running 

=/  [=bird =centag model=inference-model]  !<([bird centag inference-model] arg)
=/  =bot-id  !<(bot-id vase.bird)

::
:: Set up the model
::
=/  msg-origin=@p  author.memo.bird
=/  question  text.bird  ::TODO, strip the centag from the question
=/  pre-prompt  'You are a helpful, friendly and informative assistant.'

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time

::
:: Ignore messages from other ships if set to %private
::
?:  &(=(view.model %private) ?!(=(msg-origin our)))
  ~&  "Message origin not our ship - ignoring"
  !!

::
:: Clear conversation if requested
::
:: TODO this should be replaced with context windows
::?:  =(centag %clear)
::  ;<  ~             bind:m  (poke-our %mentat [%clear-chat !>(key)])
::  (pure:m !>([%ok `reply`'** conversation cleared **' 'new conversation']))

::
:: Build conversation from data
::
:: TODO conversation labels
;<  qst-vase=vase  bind:m  (build-conversation bird bot-id centag 'default')
=/  qst  !<(@t qst-vase)

::
:: Query replicate.com
::
;<  replicate-vase=vase  bind:m  (query-replicate [bird model pre-prompt qst])
=/  replicate-resp  !<([@tas @t] replicate-vase)

:: 
:: Conversation response
:: return [@tas reply @t] to ted/mentat.hoon
::
?+  -.replicate-resp  (pure:m !>([%error 'Error in replicate.com response']))
    %error
  (pure:m !>([%error `reply`+.replicate-resp ~]))
    %ok
  (pure:m !>([%ok `reply`+.replicate-resp `@t`+.replicate-resp]))
  ==