/-  spider, *gato, *s3, *laurel
/+  *strandio, aws
=,  strand=strand:spider
|%
  ::
  ::  Polling loop
  ::
  ++  poll
    |=  arg=vase
    =/  m  (strand ,vase)
    ^-  form:m

    =/  req  !<(request:http arg)
    =/  counter  0      :: time-out after 60 seconds
    =/  exit  'false'   :: exit loop on null http response, non-200 status code,
                        :: status=failed, completed, or cancelled
    =/  return  *[@t (unit @t)]

    |-
    ?:  |((gth counter 60) =(exit 'true'))
      ?:  (gth counter 60)
        (pure:m !>(['failed' `'timed out']))
      (pure:m !>(return))
    ;<  poll-resp=[@t (unit @t)]          bind:m  (poll-replicate req) 
    %=  $
      counter    +(counter)
      return     poll-resp
      exit       ?:(|(=(-.poll-resp 'succeeded') =(-.poll-resp 'failed') =(-.poll-resp 'cancelled') =(-.poll-resp 'completed') =(-.poll-resp 'http-error')) 'true' 'false')
    ==
  ::
  ::  Polling http-request
  ::
  ++  poll-replicate
    |=  =request:http
    =/  m  (strand ,[@t (unit @t)])
    ^-  form:m

    ;<  ~                                 bind:m  (send-request request)
    ;<  resp=(unit client-response:iris)  bind:m  take-maybe-response
    
    ?~  resp 
       (pure:m ['http-error' ~])
        ;<  our=@p     bind:m  get-our
    ;<  now=@da    bind:m  get-time
        :: Extract status-code from xml
    =/  status-code  status-code.response-header.+>-.resp
    ?.  =(status-code 200)
      (pure:m ['http-error' `(crip (weld "HTTP error - status-code: " (trip status-code)))])
    ;<  resp-txt=@t  bind:m  (extract-body (need resp))
    :: 413
    ::=/  resp-json  (de:json:html resp-txt)  
    :: 414+
    =/  resp-json  (need (de-json:html resp-txt))
    =/  response  (decode-replicate-get-resp resp-json)
    ?:  |(=(-.response 'starting') =(-.response 'processing'))
      ;<  ~  bind:m  (sleep ~s1)
      (pure:m [-.response ~])
    (pure:m [-.response +.response])
  ::
  ::
  ::  Decode json response from GET request to Replicate
  ::
  ++  decode-replicate-get-resp
    |=  =json
    ^-  [@t (unit @t)]
    ?>  ?=([%o *] json)
      =/  resp-obj  p.json
      =/  status  (~(got by resp-obj) 'status')
      =/  return-status  (so:dejs:format status)
      ?:  =(return-status 'succeeded')
        =/  output  (~(got by resp-obj) 'output')  
        :: output for images is a url as the single item in an array of cords 
        :: output for text is an array of cords.
        ?>  ?=([%a *] output)
          =/  return-data  ((ar so):dejs:format output)          :: array to list of cords
          =/  return-tape  `tape`(zing (turn return-data trip))  :: array to tape
          =/  return-cord  (crip return-tape)
          [return-status `return-cord]
      ?.  =(return-status 'failed')
        [return-status ~]
      =/  error  (~(got by resp-obj) 'error')
      [return-status `(so:dejs:format error)]
  ::
  ::  Parse user input
  ::    A needle such as "foo=" in a haystack such as "this is foo=bar really"
  ::    Will return the value "bar"
  ::
  ++  parse-input
    |=  [nedl=tape hstk=tape default=tape]
    ^-  tape
    ?~  (find nedl hstk)  default
      =/  idx  (add (dec (lent nedl)) (need (find nedl hstk)))
      =/  rem  (slag +(idx) hstk)
      =/  extract  ?~  (find " " rem)  `tape`rem  `tape`(scag (need (find " " rem)) rem)
      extract
  ::
  ::  Decode json response from OpenAI
  ::
  ++  decode-response-openai
    |=  =json
    ^-  @t
    ?>  ?=([%o *] json)
      =/  choices  (~(got by p.json) 'choices')
      ?>  ?=([%a *] choices)
        =/  answer-li  (snag 0 p.choices)
        ?>  ?=([%o *] answer-li)
          =/  li  p.answer-li
          =/  txt-json  (~(got by li) 'text')
          (so:dejs:format txt-json)
  ::
  ::  Decode json response from HuggingFace/Inference
  ::
  ++  decode-inference-text-gen-response
    |=  =json
    ^-  @t
    ?>  ?=([%a *] json)
      :: json is an array - take the first element
      =/  resp-obj  (snag 0 p.json)
      ::=/  resp-obj  -.p.json
      ?>  ?=([%o *] resp-obj)
        =/  resp-text  p.resp-obj
        =/  generated-text  (~(got by resp-text) 'generated_text')
        (so:dejs:format generated-text)
  ::
  ::  Decode json response from initial POST to Replicate
  ::  (returns both get and cancel urls)
  ::
  ++  decode-replicate-post-resp
    |=  =json
    ^-  [@t @t]
    ?>  ?=([%o *] json)
      =/  resp-obj  p.json
      =/  urls  (~(got by resp-obj) 'urls')
      ?>  ?=([%o *] urls)
        =/  urls-obj  p.urls
        =/  get-url  (~(got by urls-obj) 'get')
        =/  cancel-url  (~(got by urls-obj) 'cancel')
        [(so:dejs:format get-url) (so:dejs:format cancel-url)]
  ::
  :: Custom extract-body to get mime data
  :: 
  ++  extract-mime-body
    |=  =client-response:iris
    =/  m  (strand ,mime)
    ^-  form:m
    ?>  ?=(%finished -.client-response)
    %-  pure:m
    ?~  full-file.client-response
      *mime
      `mime`[~ (as-octs:mimes:html q.data.u.full-file.client-response)]
  ::
  ++  fetch-mime
    |=  [url=tape req=request:http]
    =/  m  (strand ,mime)
    ^-  form:m
    ;<  ~                      bind:m  (send-request req)
    ;<  =client-response:iris  bind:m  take-client-response
    (extract-mime-body client-response)
  ::
  ++  fetch-mime-data
    |=  [url=tape req=request:http]
    =/  m  (strand ,mime)
    ^-  form:m
    ;<  =mime  bind:m  (fetch-mime url req)
    =/  tpe  mime
    ?:  =(tpe [p=/ q=[p=0 q=0]])
      (strand-fail %json-parse-error ~)
    (pure:m tpe)
  ::
  :: Remove Headers from authenticated request
  :: to avoid duplication (Host, Content-Length)
  ::
  ++  evict
    |=  [=request:http header=@t]
    =.  header-list.request
      %+  skim
        header-list.request
      |=  [key=@t value=@t]
      ?!(=(key header))
    request
::
::
--
=/  m  (strand ,vase)
^-  thread:spider
|=  arg=vase
^-  form:m
=/  =bird  !<(bird arg)

:: Set up the model
=/  model=inference-model  !<(inference-model vase.bird)
=/  msg-origin=@p  author.memo.bird
;<  our-ship=@p   bind:m  get-our

:::: Keep these three lines to accept only messages from our
:::: own ship.  Delete for public access to the chatbot
::?.  =(msg-origin our-ship)
::  ~&  "Message origin not our ship - ignoring"
::  !!

=/  question  text.bird

::
:: Build HTTP request for Replicate
::

:: URL
=/  url  'https://api.replicate.com/v1/predictions'

:: Headers
=/  type  ['Content-Type' 'application/json']
=/  auth  ['Authorization' (crip (weld "Token " (trip api-key.model)))]

=/  headers  `(list [@t @t])`[type auth ~]

:: Body
::  Unfortunately input json structure is not consistent accross all models.
=/  model-id  ['version' s+id.model]
=/  prompt  ['prompt' s+question]
=/  input  ['input' (pairs:enjs:format ~[prompt])]
=/  json-body  (crip (en-json:html (pairs:enjs:format ~[model-id input])))



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
::::  =/  json-body  (en:json:html (pairs:enjs:format ~[prompt ['parameters' params]]))
:::: 414+
::=/  json-body  (crip (en-json:html (pairs:enjs:format ~[prompt ['parameters' params]])))


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
::::  =/  json-body  (en:json:html o+(malt (limo ~[model prompt temperature tokens])))
:: 414+
::=/  json-body  (crip (en-json:html o+(malt (limo ~[model prompt temperature tokens]))))
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

~&  "Response is: {<resp>}"

?~  resp 
  :: response is [%done ~] from %cancel
  (pure:m !>(['http error - cancelled' vase.bird]))

;<  our=@p     bind:m  get-our
;<  now=@da    bind:m  get-time

:: Extract status-code from xml
=/  status-code  status-code.response-header.+>-.resp
?.  |(=(status-code 200) =(status-code 201))
    ~&  "Error - AI returned non 200/201 status code"
    ::  All statuses except 200 & 201
    =/  msg  +:(need resp)
    =/  file  +.msg
    =/  xml  (cord +>+.file)
    =/  return-msg  (crip ;:(weld "Error!  AI returned status code " (scow %ud status-code) ": " (trip xml)))
    (pure:m !>([return-msg vase.bird]))

  ::  Status code 200 or 201
  ;<  resp-txt=@t  bind:m  (extract-body (need resp))
  :: 413
  ::=/  resp-json  (de:json:html resp-txt)  
  :: 414+
  =/  resp-json  (need (de-json:html resp-txt))

  =/  replicate-urls  (decode-replicate-post-resp resp-json)
  ~&  "get url: {<-.replicate-urls>}"
  ~&  "cancel url: {<+.replicate-urls>}"
  
  :: A GET request to poll the get URL with, must be authenticated
  =/  get-req=request:http
    :*  method=%'GET'                                   :: 'GET'
        url=-.replicate-urls                            :: url as cord
        header-list=~[auth]                             :: send authentication header
        ~                                               :: empty body
    ==

::  Poll the get url until we get a definitive result  
;<  get-resp=vase       bind:m  (poll !>(get-req))
=/  poll-resp  !<([@t (unit @t)] get-resp)

?.  =(-.poll-resp 'succeeded')
  =/  poll-err  ?~((need +.poll-resp) "unknown" (trip (need +.poll-resp)))
  =/  poll-err-msg  (crip (weld "Error completing your AI request: " poll-err))
  (pure:m !>([poll-err-msg vase.bird]))
  ~&  "Retrieving from {<(need +.poll-resp)>}"


:: ***** THIS BIT FOR IMAGES ONLY ******
::    text is returned directly in the output
::    field, rather than a link to the output.

:::: Success!  We have a link, now download data and process according to type
:::: Send a GET request to the data URL (authenticated??)
::=/  data-req=request:http
::  :*  method=%'GET'                                   :: 'GET'
::      url=(need +.poll-resp)                          :: url as cord
::      header-list=~[auth]                             :: send authentication header
::      ~                                               :: empty body
::  ==
::
::;<  ~                                      bind:m  (send-request data-req)
::;<  data-resp=(unit client-response:iris)  bind:m  take-maybe-response  


:: Status code 200
?-  type.model
  %conversation
:: 
:: Conversation response (to be implemented)
::

(pure:m !>(['Sorry, conversation models have not yet been implemented.' vase.bird]))

  %text-generation
::
:: Text/chat response
::
::;<  answer-txt=@t  bind:m  (extract-body (need data-resp))
::
:::: 413
::::=/  answer-json  (de:json:html answer-txt)  
:::: 414+
::=/  answer-json  (need (de-json:html answer-txt))
::=/  ai-answer  (decode-inference-text-gen-response answer-json)
::
::(pure:m !>([ai-answer vase.bird]))

(pure:m !>([(need +.poll-resp) vase.bird]))
  %image-generation
 ::
 ::Image response (poke silo with returned data)
 ::

:: Download data from returned link via authenticated GET request
=/  data-req=request:http
  :*  method=%'GET'                                   :: 'GET'
      url=(need +.poll-resp)                          :: url as cord
      header-list=~[auth]                             :: send authentication header
      ~                                               :: empty body
  ==

;<  ~                                      bind:m  (send-request data-req)
;<  data-resp=(unit client-response:iris)  bind:m  take-maybe-response  
;<  answer-img=mime                        bind:m  (extract-mime-body (need data-resp))

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

=/  host  (crip (scan (trip endpoint) ;~(pfix (jest 'https://') (star prn))))  :: e.g syd1.digitaloceanspaces.com
=/  filename  ;:(weld "img-" (snap (scow %da now) 0 '-') ".jpg")
=/  s3-url  (crip ;:(weld "https://" (trip host) "/" (trip bucket) "/" filename))

:: Get content-length, convert to cord to go in header
=/  answ-lent  `tape`(scow %ud p.q.answer-img)                      :: gives "13.245" instead of "13245"
=/  cont-lent  (crip `tape`(skip answ-lent |=(a=@ =('.' a))))   :: '13245'

:: Send as application/octet-stream, or jpeg for images?
=/  content-type  'application/octet-stream'
::=/  content-type  'image/jpeg'
::=/  content-type  'text/plain'


::  Set up aws (lib/aws.hoon)
=/  aws-client  ~(. aws [region 's3' secret access-id now])

::  Set up headers
=/  s3-headers=(list [@t @t])  ~[['content-length' cont-lent] ['date' (crip (dust:chrono:userlib (yore now)))] ['host' host] ['x-amz-acl' 'public-read']]

=/  s3-req=request:http
  :*  method=%'PUT'                                   :: 'PUT' file on S3
      url=s3-url                                      :: url as cord
      header-list=s3-headers                          :: (list [key=@t value=@t])
      `q.answer-img                                   :: body - image file as binary (unit octs)
  ==

:::: Create a new bucket
::=/  s3-req=request:http
::  :*  method=%'PUT'
::      url='https://wolfun2.syd1.digitaloceanspaces.com'
::      ::[['date' (crip (dust:chrono:userlib (yore now)))] ['content-length' '4'] ['content-type' content-type] ['host' host] ['x-amz-acl' 'public-read']]
::      header-list=`(list [@t @t])`[['Host' 'wolfun2.syd1.digitaloceanspaces.com'] ~]
::      ~
::  ==

::  Remove 'host' and 'content-length' headers from the final request
::  as iris will add them in automatically creating an invalid HTTP request.
::  We need them for the authentication however, as they are essential for
::  creating the signature.
=/  authenticated-req  (evict [(evict [(auth:aws-client s3-req) 'host']) 'content-length'])

;<  ~                                    bind:m  (send-request authenticated-req)
;<  s3-resp=(unit client-response:iris)  bind:m  take-maybe-response  

?~  s3-resp 
    :: response is [%done ~] from %cancel
    (pure:m !>(['s3 upload failed - cancelled' vase.bird]))

  =/  s3-status-code  status-code.response-header.+>-.s3-resp
  ?.  =(s3-status-code 200)
    ::  Return error message from S3
    =/  s3-msg  +:(need s3-resp)
    =/  s3-file  +.s3-msg
    =/  s3-xml  (cord +>+.s3-file)
    =/  s3-return-msg  (crip ;:(weld "Error!  S3 returned status code " (scow %ud s3-status-code) ": " (trip s3-xml)))
    (pure:m !>([s3-return-msg vase.bird]))
  
  ::  Return image and image link in message
  =/  image-link  (crip ;:(weld "https://" (trip bucket) "." (trip host) "/" filename))
  (pure:m !>([`reply`[%story [[[%image image-link 300 300 'laurel generated image'] ~] [[image-link] ~]]] vase.bird]))
==