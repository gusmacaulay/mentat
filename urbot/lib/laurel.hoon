::/-  spider, *gato, *s3, *laurel
/-  spider, *laurel
::/+  *strandio, aws
/+  *strandio, aws
=,  strand=strand:spider
|%  
  ++  poll
    |=  [arg=vase timeout=@ud]
    =/  m  (strand ,vase)
    ^-  form:m
    =/  req  !<(request:http arg)
    =/  counter  1      :: time-out after 232 seconds (counter > 60)
    =/  prev  0         :: for fibonacci sequence
    =/  exit  'false'   :: exit on null http response, non-200 status code, status=failed, completed, or cancelled
    =/  return  *[@t (unit @t)]

    :: Polling, with wait times between calls on a fibonacci sequence
    :: would be good to allow user to add their own max time-out
    |-
    ?:  |((gth counter timeout) =(exit 'true'))
      ?:  (gth counter timeout)
        (pure:m !>(['failed' `'timed out']))
      (pure:m !>(return))

    :: convert counter (use prev so as not to go over time) to seconds for timer
    =/  seconds  (crip (weld "~s" (trip `@t`(scot %ud prev))))
    =/  sleeper  `@dr`(slav %dr seconds)
    ~&  "Polling replicate GET url - trying again in {<seconds>} seconds..."
    ;<  ~                                 bind:m  (sleep sleeper)           :: poll on a fibonacci basis
    ;<  poll-resp=[@t (unit @t)]          bind:m  (poll-replicate req) 
    %=  $
      prev       counter
      counter    (add counter prev)
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
        :: Extract status-code from xml
    =/  status-code  status-code.response-header.+>-.resp
    ?.  =(status-code 200)
      (pure:m ['http-error' `(crip (weld "HTTP error - status-code: " (trip status-code)))])
    ;<  resp-txt=@t  bind:m  (extract-body (need resp))
    :: 413
    =/  resp-json  (need (de:json:html resp-txt))  
    :: 414+
    ::=/  resp-json  (need (de-json:html resp-txt))
    =/  response  (decode-replicate-get-resp resp-json)
    ?:  |(=(-.response 'starting') =(-.response 'processing'))
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

        :: test here, some responses are a single string, others are an array
        :: need to return either.

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
  ::  Build body of HTTP request to AI
  ::
  ++  build-request-body
    |=  [model=inference-model question=@t]
    ^-  @t

    =/  model-id  ['version' s+id.model]
    =/  prompt  ['prompt' s+question]
  
    :: At least two ways of specifying tokens, let's send them all and see what happens
    :: hopefully non-functional input parameters will simply be ignored 
    ?~  tokens.model
        =/  input  ['input' (pairs:enjs:format ~[prompt])]
        :: 414
        ::(crip (en-json:html (pairs:enjs:format ~[model-id input])))
        :: 413
        (en:json:html (pairs:enjs:format ~[model-id input]))
      =/  tokens  (numb:enjs:format +:(need tokens.model))
      =/  max-tokens  ['max_tokens' tokens]
      =/  max-new-tokens  ['max_new_tokens' tokens]
      =/  max-length  ['max_length' tokens]
      =/  tokens-input  ['input' (pairs:enjs:format ~[prompt max-tokens max-new-tokens max-length])]
      :: 414
      ::(crip (en-json:html (pairs:enjs:format ~[model-id tokens-input])))
      :: 413
      (en:json:html (pairs:enjs:format ~[model-id tokens-input]))
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
  :: Get image data from AI, 
  :: return error, redirect url or image mime data
  ::
  ++  get-image
    |=  [url=@t auth=[@t @t]]
    =/  m  (strand ,vase)
    ^-  form:m

    =/  req=request:http
      :*  method=%'GET'                                   :: 'GET'
          url=url                                         :: url as cord
          ::header-list=~[auth]                             :: send authentication header
          header-list=~
          ~                                               :: empty body
    ==

    ;<  ~                                 bind:m  (send-request req)
    ;<  resp=(unit client-response:iris)  bind:m  take-maybe-response  
    ?~  resp
      (pure:m !>([%fail `'[Laurel] error - cannot download generated AI response' ~]))
    :: Check status code
    =/  status-code  status-code.response-header.+>-.resp
    =/  headers=(map @t @t)  (malt headers.response-header.+>-.resp)
    
    ?:  =(status-code 307)    
      ?.  (~(has by headers) 'location')
        (pure:m !>([%fail `'[Laurel] error - cannot find redirect URL' ~]))
        :: some requests get redirected, have to pull the image from the new url
      ~&  "... redirecting to {<(~(got by headers) 'location')>} ..."
      (pure:m !>([%redirect `(~(got by headers) 'location') ~]))
    ?.  |(=(status-code 200) =(status-code 201))
      :: Error response
      (pure:m !>([%fail `'[Laurel] error -cannot download generated AI response' ~]))
    :: Response ok
    ;<  image=mime                       bind:m  (extract-mime-body (need resp))
    :: return file extension in the @t
    =/  ext-idx  (need (find "." (flop (trip url))))
    =/  file-ext  (crip (flop (scag ext-idx (flop (trip url)))))
    (pure:m !>([%ok `file-ext `image]))
::
::  Download image data from supplied link, upload to S3
::  and return S3 link for chat message
::
  ++  s3-upload
    ::|=  [url=@t auth=[@t @t] bucket=@t region=@t secret=@t access-id=@t endpoint=@t]
    |=  [answer-img=mime file-ext=@t auth=[@t @t] bucket=@t region=@t secret=@t access-id=@t endpoint=@t]
    =/  m  (strand ,vase)                                 :: vase is [@tas @t] %error or %ok + msg/url
    ^-  form:m
    
    ;<  now=@da    bind:m  get-time
    
    =/  host  (crip (scan (trip endpoint) ;~(pfix (jest 'https://') (star prn))))  :: e.g syd1.digitaloceanspaces.com
    =/  filename  ;:(weld "img-" (snap (scow %da now) 0 '-') "." (trip file-ext))         :: use file type of returned image

    =/  s3-url  (crip ;:(weld "https://" (trip host) "/" (trip bucket) "/" filename))
    
    :: Get content-length, convert to cord to go in header
    =/  answ-lent  `tape`(scow %ud p.q.answer-img)                      :: gives "13.245" instead of "13245"
    =/  cont-lent  (crip `tape`(skip answ-lent |=(a=@ =('.' a))))   :: '13245'
    
    :: Send as application/octet-stream, or jpeg for images?
    =/  content-type  'application/octet-stream'
    
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
    
    ::  Remove 'host' and 'content-length' headers from the final request
    ::  as iris will add them in automatically creating an invalid HTTP request.
    ::  We need them for the authentication however, as they are essential for
    ::  creating the signature.
    =/  authenticated-req  (evict [(evict [(auth:aws-client s3-req) 'host']) 'content-length'])
    
    ;<  ~                                    bind:m  (send-request authenticated-req)
    ;<  s3-resp=(unit client-response:iris)  bind:m  take-maybe-response  
    
    ?~  s3-resp 
        :: response is [%done ~] from %cancel
        (pure:m !>([%error '[Laurel] S3 upload failed - cancelled']))
    
      =/  s3-status-code  status-code.response-header.+>-.s3-resp
      ?.  =(s3-status-code 200)
        ::  Return error message from S3
        =/  s3-msg  +:(need s3-resp)
        =/  s3-file  +.s3-msg
        =/  s3-xml  (cord +>+.s3-file)
        =/  s3-return-msg  (crip ;:(weld "[Laurel] S3 upload failed, returned status code " (scow %ud s3-status-code) ": " (trip s3-xml)))
        (pure:m !>([%error s3-return-msg]))
      
      ::  Return image link
      =/  image-link  (crip ;:(weld "https://" (trip bucket) "." (trip host) "/" filename))
      (pure:m !>([%ok image-link]))
::      (pure:m !>([`reply`[%story [[[%image image-link 300 300 'laurel generated image'] ~] [[image-link] ~]]] vase.bird]))
::    ==    
::
::
--
