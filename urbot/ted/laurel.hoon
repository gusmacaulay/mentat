/-  spider, *gato, *s3, *laurel
/+  *strandio, aws, *laurel
=,  strand=strand:spider
=/  m  (strand ,vase)
^-  thread:spider
|=  arg=vase
^-  form:m
=/  =bird  !<(bird arg)

::
:: Set up the model
::
=/  model=inference-model  !<(inference-model vase.bird)
=/  msg-origin=@p  author.memo.bird
;<  our-ship=@p    bind:m  get-our

:: Ignore messages from other ships if set to %private
?:  &(=(view.model %private) ?!(=(msg-origin our-ship)))
  ~&  "Message origin not our ship - ignoring"
  !!

=/  question  text.bird

::
:: Clear conversation if requested
::
?:  &(=(question "clear") =(type.model %conversation))
  ;<  clear-key=@t  bind:m  (generate-conv-key bird)
  ;<  ~             bind:m  (poke-our %laurel [%clear !>(clear-key)])
  (pure:m !>(['** conversation cleared **' vase.bird]))
  
::
:: Build conversation for request to %conversation model if necessary
::
;<  qst-vase=vase  bind:m  ?:(=(type.model %conversation) (build-conversation bird) (pure:m !>(question)))
=/  qst  !<(@t qst-vase)

::
:: Build HTTP request for Replicate
::
=/  url  'https://api.replicate.com/v1/predictions'

:: Headers
=/  type  ['Content-Type' 'application/json']
=/  auth  ['Authorization' (crip (weld "Token " (trip api-key.model)))]

=/  headers  `(list [@t @t])`[type auth ~]

:: Body
=/  json-body  (build-request-body [model qst])

:: ==================================================================================
::
:: Build HTTP request for Hugging Face
::

:::: URL
::=/  url  (crip (weld (trip 'https://api-inference.huggingface.co/models/') (trip id.model)))
::
:::: Headers (Auth key must be hidden!  ** DO NOT COMMIT **)
::=/  type  ['Content-Type' 'application/json']
::=/  auth  ['Authorization' api-key.model]
::
::=/  headers  `(list [@t @t])`[type auth ~]
::
:::: Body
::::=/  prompt  ['inputs' s+question]
::=/  prompt  ['prompt' s+question]
::=/  temperature  ['temperature' n+'1.0']
::=/  tokens  ['max_new_tokens' n+'64']
::
::=/  params  (pairs:enjs:format ~[temperature tokens])
::
:::: Depending on whether or not this is running before 
:::: or after the breaking json changes
:::: 413
::  =/  json-body  (en:json:html (pairs:enjs:format ~[prompt ['parameters' params]]))
:::: 414+
::::=/  json-body  (crip (en-json:html (pairs:enjs:format ~[prompt ['parameters' params]])))


:::: ===============================================================================
::::
:::: Build HTTP request for OpenAI
:::: Base our request off this curl request:
:::: https://platform.openai.com/docs/api-reference/completions/create for more info
:::: may also be able to use /chat/completions for a full chatbot experience
::::
:::: URL
::=/  url  'https://api.openai.com/v1/completions'
::
:::: Headers (Authorization key should be hidden! ** DO NOT COMMMIT **)
::=/  type  ['Content-Type' 'application/json']
::=/  auth  ['Authorization' 'Bearer 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']
::=/  headers  `(list [@t @t])`[type auth ~]
::
:::: Body
::=/  model  ['model' s+'text-davinci-003']
::=/  prompt  ['prompt' s+question]
::=/  temperature  ['temperature' n+'0.75']
::=/  tokens  ['max_tokens' n+'256']
::
:: Depending on whether or not this is running before 
:: or after the breaking json changes
:::: 413
::  =/  json-body  (en:json:html o+(malt (limo ~[model prompt temperature tokens])))
:: 414+
::::=/  json-body  (crip (en-json:html o+(malt (limo ~[model prompt temperature tokens]))))
::
:::: =====================================================================================

:: 
:: Make http request to AI
::
=/  =request:http
  :*  method=%'POST'                                  :: 'POST', not 'GET'
      url=url                                         :: url as cord
      header-list=headers                             :: (list [key=@t value=@t])
      `(as-octs:mimes:html json-body)                 :: this needs to be (unit octs) from encoded json
  ==
  
;<  ~                                 bind:m  (send-request request)
;<  resp=(unit client-response:iris)  bind:m  take-maybe-response  
~&  "[Laurel] Have AI response - processing..."

?~  resp 
  :: response is [%done ~] from %cancel
  (pure:m !>(['http error - cancelled' vase.bird]))

;<  our=@p     bind:m  get-our
;<  now=@da    bind:m  get-time

:: Extract status-code from xml
=/  status-code  status-code.response-header.+>-.resp
?.  |(=(status-code 200) =(status-code 201))
    ~&  "[Laurel] error - AI returned non 200/201 status code"
    =/  return-msg  (crip ;:(weld "Error!  AI returned status code " (scow %ud status-code)))
    (pure:m !>([return-msg vase.bird]))

  ::  Status code 200 or 201
  ;<  resp-txt=@t  bind:m  (extract-body (need resp))
  :: 413
  =/  resp-json  (need (de:json:html resp-txt))  
  :: 414+
  ::=/  resp-json  (need (de-json:html resp-txt))

  =/  replicate-urls  (decode-replicate-post-resp resp-json)

  :: A GET request to poll the get URL with, must be authenticated
  =/  get-req=request:http
    :*  method=%'GET'                                   :: 'GET'
        url=-.replicate-urls                            :: url as cord
        header-list=~[auth]                             :: send authentication header
        ~                                               :: empty body
    ==

::  Poll the get url until we get a definitive result, set default timeout as 60seconds
=/  timeout  ?~(timeout.model 60 +:(need timeout.model))  
;<  get-resp=vase       bind:m  (poll [!>(get-req) timeout])
=/  poll-resp  !<([@t (unit @t)] get-resp)

?.  =(-.poll-resp 'succeeded')
  =/  poll-err  ?~((need +.poll-resp) "unknown" (trip (need +.poll-resp)))
  =/  poll-err-msg  (crip (weld "Error completing your AI request: " poll-err))
  (pure:m !>([poll-err-msg vase.bird]))

:: Status code 200
?-  type.model
  %conversation
:: 
:: Conversation response
::

:: poke update to conversation to app
:: update with both question asked and answer returned
;<  conv-key=@t  bind:m  (generate-conv-key bird)
;<  ~            bind:m  (poke-our %laurel [%add !>([conv-key [%user qst]])])
;<  ~            bind:m  (poke-our %laurel [%add !>([conv-key [%ai (need +.poll-resp)]])])

(pure:m !>([(need +.poll-resp) vase.bird]))

  %text-generation
::
:: Text/chat response
::

(pure:m !>([(need +.poll-resp) vase.bird]))

  %image-generation
 ::
 ::Image response (poke silo with returned data)
 ::

:: Get S3 credentials and configuration
;<  cred=update  bind:m  (scry update `path`['gx' 's3-store' 'credentials' 'noun' ~])
;<  cnfg=update  bind:m  (scry update `path`['gx' 's3-store' 'configuration' 'noun' ~])

?>  ?=([%credentials *] cred)
=/  endpoint  endpoint.credentials.cred
=/  secret  secret-access-key.credentials.cred
=/  access-id  access-key-id.credentials.cred

?>  ?=([%configuration *] cnfg)
=/  bucket  current-bucket.configuration.cnfg
=/  region  region.configuration.cnfg

:: No S3 credentials, return error message and replicate link (available 24hrs only)
?:  |(=(endpoint '') =(access-id '') =(secret '') =(bucket '') =(region ''))
  =/  s3-unavailable-msg  (crip (weld "No S3 access - temporary link: " (trip (need +.poll-resp))))
  (pure:m !>([`reply`[%story [[[%image (need +.poll-resp) 300 300 'laurel generated image'] ~] [[s3-unavailable-msg] ~]]] vase.bird]))

;<  image-vase=vase       bind:m  (get-image (need +.poll-resp) auth)
=/  image-data  !<([@tas (unit @t) (unit mime)] image-vase)

?+  -.image-data  (pure:m !>(['[Laurel] unknown error' vase.bird]))
    %redirect
  ::try again with redirect url (just fail out if we don't get an image result)
  ;<  redirect-vase=vase    bind:m  (get-image (need +<.image-data) auth)
  =/  redirect-data  !<([@tas (unit @t) (unit mime)] redirect-vase)
  ?.  =(-.redirect-data %ok)
    (pure:m !>(['[Laurel] image generation redirect error' vase.bird]))
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.redirect-data) (need +<.redirect-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?+  -.s3-return  (pure:m !>(['[Laurel] unknown error' vase.bird]))
      %error
    (pure:m !>([+.s3-return vase.bird]))
      %ok
    (pure:m !>([`reply`[%story [[[%image +.s3-return 300 300 'laurel generated image'] ~] [[+.s3-return] ~]]] vase.bird]))
  ==
    %fail
  (pure:m !>([(crip (weld "Laurel] error: " (trip (need +<.image-data)))) vase.bird]))
    %ok
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.image-data) (need +<.image-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?+  -.s3-return  (pure:m !>(['[Laurel] unknown error' vase.bird]))
      %error
    (pure:m !>([+.s3-return vase.bird]))
      %ok
    (pure:m !>([`reply`[%story [[[%image +.s3-return 300 300 'laurel generated image'] ~] [[+.s3-return] ~]]] vase.bird]))
  ==
==
==