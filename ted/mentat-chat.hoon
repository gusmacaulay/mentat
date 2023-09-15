::
:: %mentat sub-thread to process chat requests to LLM
::
/-  spider, *gato, *mentat
/+  *strandio, *mentat, regex
=,  strand=strand:spider
=/  m  (strand ,vase)
^-  thread:spider
|=  arg=vase
^-  form:m
:: bird is the complete data coming in from %gato, cen-type is the
:: incoming centag (useful if we have one sub-thread dealing with multiple centags)
=/  [=bird cntp=cen-type]  !<([bird cen-type] arg)

::
:: Set up the model
::
=/  model=inference-model  !<(inference-model vase.bird)
=/  msg-origin=@p  author.memo.bird
=/  question  text.bird  ::TODO, strip the centag from the question
=/  pre-prompt  'You are a helpful, friendly and informative assistant.'

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time

::
:: Clear conversation if requested
::
?:  =(cntp %clear)
  ::TODO - how to clear current conversation context
  :: and keep entire conversation
  ;<  clear-key=@t  bind:m  (generate-conv-key bird)
  ;<  ~             bind:m  (poke-our %mentat [%clear !>(clear-key)])
  (pure:m !>([%ok `reply`'** conversation cleared **']))

::
:: Build conversation from data
::
;<  qst-vase=vase  bind:m  (build-conversation bird)
=/  qst  !<(@t qst-vase)

::
:: Query replicate.com
::
;<  replicate-vase=vase  bind:m  (query-replicate [bird model pre-prompt qst])
=/  replicate-resp  !<([@tas @t] replicate-vase)

:: 
:: Conversation response
:: return [@tas reply] to ted/mentat.hoon
::
?+  -.replicate-resp  (pure:m !>([%error 'Error in replicate.com response']))
    %error
  (pure:m !>([%error `reply`+.replicate-resp]))
    %ok
  :: TODO this can all move to ted/mentat.hoon as we'll be recording all conversation data
  :: poke update to conversation to app
  :: update with both question asked and answer returned
  ;<  conv-key=@t  bind:m  (generate-conv-key bird)
  ;<  ~            bind:m  (poke-our %mentat [%add !>([conv-key [%user qst]])])
  ;<  ~            bind:m  (poke-our %mentat [%add !>([conv-key [%ai +.replicate-resp]])])
  (pure:m !>([%ok `reply`+.replicate-resp]))
  ==