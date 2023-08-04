/-  spider, *gato, *s3, *laurel
/+  *strandio, aws, *laurel
=,  strand=strand:spider
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
=/  json-body  (build-request-body [model question])

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
    ::  All statuses except 200 & 201
    =/  msg  +:(need resp)
    =/  file  +.msg
    =/  xml  (cord +>+.file)
    =/  return-msg  (crip ;:(weld "Error!  AI returned status code " (scow %ud status-code) ": " (trip xml)))
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
:: Conversation response (to be implemented)
::

(pure:m !>(['Sorry, conversation models have not yet been implemented.' vase.bird]))

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
  ;<  s3-link=vase    bind:m  (s3-upload (need +<.redirect-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?-  -.s3-return
      %error
    (pure:m !>([+.s3-return vase.bird]))
      %ok
    (pure:m !>([`reply`[%story [[[%image +.s3-return 300 300 'laurel generated image'] ~] [[+.s3-return] ~]]] vase.bird]))
  ==
    %fail
  (pure:m !>([(crip (weld "Laurel] error: " (trip (need +<.redirect-data)))) vase.bird]))
    %ok
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.image-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?-  -.s3-return
      %error
    (pure:m !>([+.s3-return vase.bird]))
      %ok
    (pure:m !>([`reply`[%story [[[%image +.s3-return 300 300 'laurel generated image'] ~] [[+.s3-return] ~]]] vase.bird]))
  ==
==


    :: unpack returned vase to url or error message

::=/  image-data  !<([@tas (unit @t) (unit mime)] (get-image (need +.poll-resp) auth))
::~&  "image-data is: {<image-data>}"
::~&  "image-data response is: {<-.image-data>}"

:: ASM convert this to a function: s3-upload
:: Have S3 credentials, download data from returned link via UNauthenticated GET request
::=/  data-req=request:http
::  :*  method=%'GET'                                   :: 'GET'
::      url=(need +.poll-resp)                          :: url as cord
::      ::header-list=~[auth]                             :: send authentication header
::      header-list=~
::      ~                                               :: empty body
::  ==
::
::;<  ~                                      bind:m  (send-request data-req)
::;<  data-resp=(unit client-response:iris)  bind:m  take-maybe-response  
::?~  data-resp
::  (pure:m !>(['[Laurel] error - cannot download generated AI response' vase.bird]))
::
::
:::::: Check status code
::::=/  data-resp-status-code  status-code.response-header.+>-.data-resp
::::?:  =(data-resp-status-code 307)
::::    :: some requests get redirected, have to update pull the image from the new url
::::    =/  redirect=@t  location.response-header.+>-.data-resp
::::    ::..... how do we loop back around to get this data and upload it to S3
::::    ::  this requires moving this into the lib file so we can re-run it.
::::?.  |(=(data-resp-status-code 200) =(data-resp-status-code 201))
::::  :: Error response
::::  (pure:m !>(['[Laurel] error - cannot download generated AI response' vase.bird]))
:::::: Response ok
::
::
::;<  answer-img=mime                        bind:m  (extract-mime-body (need data-resp))
::
::=/  ext-idx  (need (find "." (flop (trip (need +.poll-resp)))))
::=/  file-ext  (flop (scag ext-idx (flop (trip (need +.poll-resp)))))
::
::=/  host  (crip (scan (trip endpoint) ;~(pfix (jest 'https://') (star prn))))  :: e.g syd1.digitaloceanspaces.com
::=/  filename  ;:(weld "img-" (snap (scow %da now) 0 '-') "." file-ext)         :: use file type of returned image
::
::=/  s3-url  (crip ;:(weld "https://" (trip host) "/" (trip bucket) "/" filename))
::
:::: Get content-length, convert to cord to go in header
::=/  answ-lent  `tape`(scow %ud p.q.answer-img)                      :: gives "13.245" instead of "13245"
::=/  cont-lent  (crip `tape`(skip answ-lent |=(a=@ =('.' a))))   :: '13245'
::
:::: Send as application/octet-stream, or jpeg for images?
::=/  content-type  'application/octet-stream'
::
::::  Set up aws (lib/aws.hoon)
::=/  aws-client  ~(. aws [region 's3' secret access-id now])
::
::::  Set up headers
::=/  s3-headers=(list [@t @t])  ~[['content-length' cont-lent] ['date' (crip (dust:chrono:userlib (yore now)))] ['host' host] ['x-amz-acl' 'public-read']]
::
::=/  s3-req=request:http
::  :*  method=%'PUT'                                   :: 'PUT' file on S3
::      url=s3-url                                      :: url as cord
::      header-list=s3-headers                          :: (list [key=@t value=@t])
::      `q.answer-img                                   :: body - image file as binary (unit octs)
::  ==
::
:::::: Create a new bucket
::::=/  s3-req=request:http
::::  :*  method=%'PUT'
::::      url='https://wolfun2.syd1.digitaloceanspaces.com'
::::      ::[['date' (crip (dust:chrono:userlib (yore now)))] ['content-length' '4'] ['content-type' content-type] ['host' host] ['x-amz-acl' 'public-read']]
::::      header-list=`(list [@t @t])`[['Host' 'wolfun2.syd1.digitaloceanspaces.com'] ~]
::::      ~
::::  ==
::
::::  Remove 'host' and 'content-length' headers from the final request
::::  as iris will add them in automatically creating an invalid HTTP request.
::::  We need them for the authentication however, as they are essential for
::::  creating the signature.
::=/  authenticated-req  (evict [(evict [(auth:aws-client s3-req) 'host']) 'content-length'])
::
::;<  ~                                    bind:m  (send-request authenticated-req)
::;<  s3-resp=(unit client-response:iris)  bind:m  take-maybe-response  
::
::?~  s3-resp 
::    :: response is [%done ~] from %cancel
::    (pure:m !>(['s3 upload failed - cancelled' vase.bird]))
::
::  =/  s3-status-code  status-code.response-header.+>-.s3-resp
::  ?.  =(s3-status-code 200)
::    ::  Return error message from S3
::    =/  s3-msg  +:(need s3-resp)
::    =/  s3-file  +.s3-msg
::    =/  s3-xml  (cord +>+.s3-file)
::    =/  s3-return-msg  (crip ;:(weld "Error!  S3 returned status code " (scow %ud s3-status-code) ": " (trip s3-xml)))
::    (pure:m !>([s3-return-msg vase.bird]))
::  
::  ::  Return image and image link in message
::  =/  image-link  (crip ;:(weld "https://" (trip bucket) "." (trip host) "/" filename))
::  (pure:m !>([`reply`[%story [[[%image image-link 300 300 'laurel generated image'] ~] [[image-link] ~]]] vase.bird]))
==