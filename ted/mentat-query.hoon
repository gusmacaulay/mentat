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
=/  question  text.bird
=/  pre-prompt  'You are a helpful, friendly and informative assistant, with professorial overtones.  Your answers should always be factually correct and as helpful as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content.  Please ensure that your responses are socially unbiased.  If a question does make any sense, or is not factually coherent, explain why instead of answering with something incorrect.  If you do not know the answer to a question, please do not share false information.'

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time

::
:: Ignore messages from other ships if set to %private
::
?:  &(=(view.model %private) ?!(=(msg-origin our)))
  ~&  "Message origin not our ship - ignoring"
  !!

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
  (pure:m !>([%error `reply`+.replicate-resp ~]))
    %ok
  :: return %ok, the reply that goes to %gato, and the text returned from replicate (to log)
  (pure:m !>([%ok `reply`+.replicate-resp `@t`+.replicate-resp]))
  ==
