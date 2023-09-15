::
:: %mentat sub-thread to process simple Q & A requests to LLM
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
=/  question  text.bird
=/  pre-prompt  'You are a helpful, friendly and informative AI.  Give all your information in the style of an avuncular professor.'

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time

::
:: Query replicate.com
::
;<  replicate-vase=vase  bind:m  (query-replicate [bird model pre-prompt question])
=/  replicate-resp  !<([@tas @t] replicate-vase)

:: TODO add some smarts around incoming centag
:: if it is %default, need to respond differently

::
:: Return [@tas reply] to ted/mentat.hoon
::
?+  -.replicate-resp  (pure:m !>([%error 'Error in replicate.com response']))
    %error
  (pure:m !>([%error `reply`+.replicate-resp]))
    %ok
  (pure:m !>([%ok `reply`+.replicate-resp]))
  ==