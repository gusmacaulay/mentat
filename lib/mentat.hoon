/-  spider, *gato, *mentat::, mc=mentat-chat
/-  d=diary, g=groups, c=chat, ha=hark :: not sure which of these we'll need
/+  *strandio, aws, regex
=,  strand=strand:spider
|%
  ::
  :: There are issue with standard strandio.hoon await-thread
  :: build our own in order to pass through error status
  :: rather than failing and killing the calling thread
  ::   
  ++  custom-await-thread
    |=  [file=term args=vase]
    =/  m  (strand ,vase)
    ^-  form:m
  
    ;<  =bowl:spider  bind:m  get-bowl
    =/  tid  `@ta`(cat 3 'strand_' (scot %uv (sham file eny.bowl)))
    ;<  ~             bind:m  (watch-our /awaiting/[tid] %spider /thread-result/[tid])
    ;<  ~             bind:m  %-  poke-our
                              :*  %spider
                                  %spider-start
                                  !>([`tid.bowl `tid byk.bowl(r da+now.bowl) file args])
                              ==
    ;<  =cage         bind:m  (take-fact /awaiting/[tid])
    ;<  ~             bind:m  (take-kick /awaiting/[tid])
    ?+  p.cage  ~|([%strange-thread-result p.cage file tid] !!)
        %thread-done
      :: q.q.cage is (e.g.) [%ok `reply`] as [@ud @ud]
      :: q.q.cage is (e.g. [%ok `reply` @t])
      =/  cage-data  q.q.cage
      =/  ok-txt  [(@tas -.cage-data) (reply +<.cage-data) (@t +>.cage-data)]
      (pure:m !>([%done ok-txt]))                              :: return %done so we can ?+ against this easily
        %thread-fail
      :: q.q.cage is a tang (list tank) in the form [%poke-fail <tang returned from thread>]
      :: unpack it and pass through as a cord
      =/  err  (tang q.q.cage)
      =/  err-tank  (tank (snag 1 err))                        :: first tank in the tang
      =/  err-cord  (crip (weld "Thread failed, unexpected error in" ~(ram re err-tank)))
      (pure:m !>([%fail [%fail `reply`err-cord ~]]))           :: return failure reason rather than fail the thread
    ==
  ::
  :: Poll replicate url until timeout
  ::
  ++  poll
    |=  [arg=vase =flag.c timeout=@ud]
    =/  m  (strand ,vase)
    ^-  form:m
    =/  req  !<(request:http arg)

    =/  counter  1      :: time-out after 232 seconds (counter > 60)
    =/  prev  0         :: for fibonacci sequence
    =/  exit  'false'   :: exit on null http response, non-200 status code, status=failed, completed, or cancelled
    =/  return  *[@t (unit @t)]
    =/  old-id  [*@p *@da]
  
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
    ::~&  "Polling replicate GET url - trying again in {<seconds>} seconds..."
    ;<  ~                                 bind:m  (sleep sleeper)                     :: poll on a fibonacci basis
    ;<  poll-resp=[@t (unit @t)]          bind:m  (poll-replicate req)
    ;<  id=[@p @da]                       bind:m  (poll-message flag old-id counter)  :: "waiting" output
    %=  $
      prev          counter
      counter       (add counter prev)
      old-id        id
      return        poll-resp
      exit          ?:(|(=(-.poll-resp 'succeeded') =(-.poll-resp 'failed') =(-.poll-resp 'cancelled') =(-.poll-resp 'completed') =(-.poll-resp 'http-error')) 'true' 'false')
    ==
  
  ::
  ::  "waiting" message output direct to chat, since we can only return a final value to %gato
  ::
  ++  poll-message
    |=  [=flag.c old-id=[@p @da] counter=@ud]
    =/  m  (strand ,[@p @da])
    ^-  form:m

    ;<  our=@p         bind:m  get-our
    ;<  now=@da        bind:m  get-time

    =/  txt-list  ?:(=(counter 0) ~['...waiting'] ~[(crip (weld "...waiting" `tape`(reap +(counter) '.')))])

    =/  id  [our now]

    =/  memo=memo:c
      :*  replying=~  :: ~ is latest message, an `id, which is [ship time] replies to a specific message
          author=our
          sent=now
          [%story [*(list block.c) `(list inline.c)`txt-list]]
      ==

    =/  delt-add  [%add memo]
    =/  diff-add  `diff:c`[%writs `diff:writs:c`[id delt-add]]
    =/  update-add  [now diff-add]
    =/  action-add=action.c  [flag update-add]
    
    =/  delt-del  [%del ~]
    =/  diff-del  `diff:c`[%writs `diff:writs:c`[old-id delt-del]]  :: old-id is previous add
    =/  update-del  [now diff-del]
    =/  action-del=action.c  [flag update-del]
    
    ?:  (gth counter 0)
      ;<  ~           bind:m  (poke-our %chat [%chat-action !>([action-del])])
      ;<  ~           bind:m  (poke-our %chat [%chat-action !>([action-add])])
      (pure:m id)
    ;<  ~           bind:m  (poke-our %chat [%chat-action !>([action-add])])
    (pure:m id)
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
        :: output for text is either an array of cords, or a single cord (json string)
        ?+  -.output  ['failed: ' `'json parsing error']
            %a
          ?>  ?=([%a *] output)
            =/  return-data  ((ar so):dejs:format output)          :: array to list of cords
            =/  return-tape  `tape`(zing (turn return-data trip))  :: array to tape
            =/  return-cord  (crip return-tape)
            [return-status `return-cord]
            %s
          ?>  ?=([%s *] output)
             [return-status `(so:dejs:format output)]              :: single string to cord
        ==  
      ?.  =(return-status 'failed')
        [return-status ~]
      =/  error  (~(got by resp-obj) 'error')
      [return-status `(so:dejs:format error)]
  ::
  ::  Parse user input
  ::    A needle such as "foo=" in a haystack such as "this is foo=bar really"
  ::    Will return the value "bar"
  ::  TODO: this can be replaced with REGEX
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
      =/  resp-obj  (snag 0 p.json)
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
  ::  Decode json returned from the LLM
  ::  which should specify a notebook and
  ::  some data to add to it/create it with
  ::
  ++  decode-generated-notebook
    |=  =json
    ^-  [@p @tas @tas time @t]              ::  ship, channel, action id(timestamp), text
    ?>  ?=([%o *] json)
      =/  resp-obj  p.json
      =/  data  (so:dejs:format (~(got by resp-obj) 'data'))
      =/  action  `@tas`(so:dejs:format (~(got by resp-obj) 'action'))
      =/  id-text  (~(got by resp-obj) 'notebook')
      ?~  id-text
        ::  No notebook id, therefore return as an %add regardless of passed in action
        [*ship *@tas %add *time data]  
      ::  Parse passed in id to get ship, channel and timestamp
      =/  id  (parse-id (so:dejs:format id-text))
      [-.id +<.id action +>.id data]
  ::
  ::  Parse the LLM text version of the notebook id
  ::  into something useful
  ::
  ++  parse-id
    |=  text=@t
    ^-  [@p @tas time]
    :: format ~let-go/test-notebook/note/9187369876132424
    :: just convert to tape and pull apart between "/"
    =/  txt  (trip text)
    =/  shp=@p  (need (slaw %p (crip (scag (need (find "/" txt)) txt))))
    =/  rm-txt-1  (oust [0 (add 1 (need (find "/" txt)))] txt)
    =/  channel=@tas  (crip (scag (need (find "/" rm-txt-1)) rm-txt-1))
    :: use json parsing to extract unformatted number as a date
    ::`@da`(ni:dejs:format n+'170141184506385861578430265978091732992')
    =/  id-cord  (crip (flop (scag (need (find "/" (flop txt))) (flop txt))))
    =/  id=@da  `@da`(ni:dejs:format n+id-cord)
    [shp channel id]
  ::
  ++  append-note
    |=  [query=@t note-id=@t]
    =/  m  (strand ,vase)
    ^-  form:m

    :: ASM - fix this, we can use parse-id above to do this more simply.

    :: note-id will be: ~let/test-notebook/note/170141184506391138791970685596915990528
    :: the number is a cord version of a date value represented as @ud (use json parsing to fix)

    =/  id-num-tp  `tape`(flop (swag [0 (need (find "/" (flop (trip note-id))))] (flop (trip note-id))))  
    =/  id-num  `tape`(scow %ud (ni:dejs:format n+(crip id-num-tp)))            :: e.g. '170.141.184.506.391.138.791.970.685.596.915.990.528'

    =/  note-id-rgx  (run:regex "~[a-z,-]+/[a-z,0-9,-]+/note" (trip note-id))
    =/  note-id-cleaned  q.->+:(need note-id-rgx)                               :: e.g ~let/test-notebook/note
    =/  note-id-upd  ;:(weld "diary/" note-id-cleaned "s/note/" id-num)         :: e.g /diary/~let/test-notebook/notes/note

    =/  scry-path=path  (stab (crip ;:(weld "/gx/diary/" note-id-upd "/noun")))
    ;<  raw-note-data=note.d    bind:m  (scry note.d scry-path)
    =/  note-txt=tape  (flatten-note raw-note-data)
    =/  upd-query  (crip ;:(weld (trip query) "  Notebook content: " note-txt))  
    (pure:m !>(upd-query))
  ::
  ::  Take a note and flatten it out into a cord (in markdown hopefully) 
  ::  in order to send to LLM
  ::
  ++  flatten-note
    |=  =note.d
    ^-  tape
    =/  ess=essay.d  +.note
    =/  cont=(list verse.d)  content.ess  :: ignore seal, title, image, author, etc.
    =/  txt-list=(list tape)  (turn cont flatten-essay)
    (zing txt-list)
  ::
  ::  flatten-essay
  ::
  ++  flatten-essay
    |=  =verse.d
    ^-  tape
    ?-  -.verse
        %block
      (flatten-block p.verse)
        %inline
      =/  inline-txt=(list tape)  (turn p.verse flatten-inline)
      (zing inline-txt)
    ==
  ::
  ++  flatten-block
    |=  =block.d
    ^-  tape
    ?-  -.block
        %image
      (trip src.block)
        %cite
      "citation" :: TODO - check this, not sure what cite:c is
        %header
      =/  header-lines=(list tape)  (turn q.block flatten-inline)
      ?-  p.block
          %h1
        (weld "#" `tape`(zing header-lines))
          %h2
        (weld "##" `tape`(zing header-lines))
          %h3
        (weld "###" `tape`(zing header-lines))
          %h4
        (weld "####" `tape`(zing header-lines))
          %h5
        (weld "#####" `tape`(zing header-lines))
          %h6
        (weld "######" `tape`(zing header-lines))
      ==
        %listing
      (flatten-listing p.block)
        %rule
      "\0a---\0a"
        %code
      ;:(weld "  Following code is " (trip lang.block) ". ``` " (trip code.block) " ```")
    ==
  ::
  :: Flatten inline
  ::
  ++  flatten-inline
    |=  =inline.d
    ^-  tape
    ?@  inline
      (trip inline)
    ?-  -.inline
::        %task
::      =/  task-text  `tape`(zing `(list tape)`(turn q.inline flatten-inline))
::      ?:  =(p.inline)
::        (weld "[ ] " task-text)
::      (weld "[x] " task-text)
        %italics
      =/  italics-list=(list tape)  (turn p.inline flatten-inline)
      ;:(weld "*" `tape`(zing italics-list) "*")
        %bold
      =/  bold-list=(list tape)  (turn p.inline flatten-inline)
      ;:(weld "**" `tape`(zing bold-list) "**")
        %strike
      =/  strike-list=(list tape)  (turn p.inline flatten-inline)
      ;:(weld "~~" `tape`(zing strike-list) "~~")
        %blockquote
      =/  block-list=(list tape)  (turn p.inline flatten-inline)
      (weld ">" `tape`(zing block-list))
        %inline-code
      ;:(weld "```" (trip p.inline) "```")
        %ship
      (scow %p p.inline)
        %block
      ;:(weld (trip p.inline) " " (trip q.inline))
        %code
      (trip p.inline)
        %tag
      (trip p.inline)
        %link
      ;:(weld "[" (trip p.inline) "](" (trip q.inline) ")")
        %break
      "  \0a"
        %task
      =/  task-text  `tape`(zing `(list tape)`(turn q.inline flatten-inline))
      ?:  p.inline
        (weld "[ ] " task-text)
      (weld "[x] " task-text)
    ==
  ::
  ::  Flatten list
  ::
  ++  flatten-listing
    |=  =listing.d
    ^-  tape

    ?-  -.listing
        %list
      ?-  p.listing
          %ordered
        :: Not sure how to order these?
        =/  or-listing=(list tape)  (turn q.listing flatten-listing)
        =/  or-inline=(list tape)  (turn r.listing flatten-inline)
        (zing (weld or-listing or-inline))
          %unordered
        =/  un-listing=(list tape)  (turn q.listing flatten-listing)
        =/  un-inline=(list tape)  (turn r.listing flatten-inline)
        (zing (weld un-listing un-inline))
          %tasklist
        =/  un-listing=(list tape)  (turn q.listing flatten-listing)
        =/  un-inline=(list tape)  (turn r.listing flatten-inline)
        (zing (weld un-listing un-inline))
      ==
        %item
      =/  item-content=(list tape)  (turn p.listing flatten-inline)
      `tape`(zing item-content)
    ==
  ::
  ::  Build body of HTTP request to AI
  ::
  ++  build-request-body
    |=  [model=inference-model sys-prompt=@t question=@t]
    ^-  @t

    =/  model-id  ['version' s+model-id.model]
    =/  prompt  ['prompt' s+question]
    =/  s-prompt  ['system_prompt' s+sys-prompt]

    :: At least two ways of specifying tokens, let's send them all and see what happens
    :: hopefully non-functional input parameters will simply be ignored 
    ?~  tokens.model
        =/  input  ['input' (pairs:enjs:format ~[s-prompt prompt])]
        (en:json:html (pairs:enjs:format ~[model-id input]))
      =/  tokens  (numb:enjs:format (need tokens.model))
      =/  max-tokens  ['max_tokens' tokens]
      =/  max-new-tokens  ['max_new_tokens' tokens]
      =/  max-length  ['max_length' tokens]
      =/  tokens-input  ['input' (pairs:enjs:format ~[s-prompt prompt max-tokens max-new-tokens max-length])]
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
    
    :: some models require auth, and others have problems if auth is included!
    =/  req=request:http
      :*  method=%'GET'                                   :: 'GET'
          url=url                                         :: url as cord
          header-list=~[auth]                             :: send authentication header
          ::header-list=~
          ~                                               :: empty body
    ==

    ;<  ~                                 bind:m  (send-request req)
    ;<  resp=(unit client-response:iris)  bind:m  take-maybe-response  
    ?~  resp
      (pure:m !>([%fail `'[mentat] error - cannot download generated AI response' ~]))
    :: Check status code
    =/  status-code  status-code.response-header.+>-.resp
    =/  headers=(map @t @t)  (malt headers.response-header.+>-.resp)
    
    ?:  =(status-code 307)    
      ?.  (~(has by headers) 'location')
        (pure:m !>([%fail `'[mentat] error - cannot find redirect URL' ~]))
        :: some requests get redirected, have to pull the image from the new url
      ~&  "... redirecting to {<(~(got by headers) 'location')>} ..."
      (pure:m !>([%redirect `(~(got by headers) 'location') ~]))
    ?.  |(=(status-code 200) =(status-code 201))
      :: Error response
      (pure:m !>([%fail `'[mentat] error -cannot download generated AI response' ~]))
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
        (pure:m !>([%error '[mentat] S3 upload failed - cancelled']))
    
      =/  s3-status-code  status-code.response-header.+>-.s3-resp
      ?.  =(s3-status-code 200)
        ::  Return error message from S3
        =/  s3-msg  +:(need s3-resp)
        =/  s3-file  +.s3-msg
        =/  s3-xml  (cord +>+.s3-file)
        =/  s3-return-msg  (crip ;:(weld "[mentat] S3 upload failed, returned status code " (scow %ud s3-status-code) ": " (trip s3-xml)))
        (pure:m !>([%error s3-return-msg]))
      
      ::  Return image link
      =/  image-link  (crip ;:(weld "https://" (trip bucket) "." (trip host) "/" filename))
      (pure:m !>([%ok image-link]))
::
::  Send a request to a Replicate.com LLM  
::
  ++  query-replicate
    |=  [=bird model=inference-model pre-prompt=@t question=@t]
    =/  m  (strand ,vase)
    ^-  form:m
    ::
    :: Build HTTP request for Replicate
    ::
    =/  url  'https://api.replicate.com/v1/predictions'
    
    :: Headers
    =/  type  ['Content-Type' 'application/json']
    =/  auth  ['Authorization' (crip (weld "Token " (trip api-key.model)))]
    =/  headers  `(list [@t @t])`[type auth ~]
    
    :: Body
    =/  json-body  (build-request-body [model pre-prompt question])
    
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

    ?~  resp 
      :: response is [%done ~] from %cancel
      (pure:m !>([%error 'http error - cancelled']))
      
    :: Extract status-code from xml
    =/  status-code  status-code.response-header.+>-.resp
    ?.  |(=(status-code 200) =(status-code 201))
        ~&  "[mentat] error - AI returned non 200/201 status code"
        =/  return-msg  (crip ;:(weld "Error!  AI returned status code " (scow %ud status-code)))
        (pure:m !>([%error return-msg]))
    
      ::  Status code 200 or 201
      ;<  resp-txt=@t  bind:m  (extract-body (need resp))
      =/  resp-json  (need (de:json:html resp-txt))  
    
      =/  replicate-urls  (decode-replicate-post-resp resp-json)
    
      :: A GET request to poll the get URL with, must be authenticated
      =/  get-req=request:http
        :*  method=%'GET'                                   :: 'GET'
            url=-.replicate-urls                            :: url as cord
            header-list=~[auth]                             :: send authentication header
            ~                                               :: empty body
        ==
    
    ::  Poll the get url until we get a definitive result, set default timeout as 60seconds
    =/  timeout  ?~(timeout.model 60 (need timeout.model))
    ;<  get-resp=vase       bind:m  (poll [!>(get-req) flag.bird timeout])
    =/  poll-resp  !<([@t (unit @t)] get-resp)

    ?.  =(-.poll-resp 'succeeded')
      =/  poll-err  ?~((need +.poll-resp) "unknown" (trip (need +.poll-resp)))
      =/  poll-err-msg  (crip (weld "Error completing your AI request: " poll-err))
      (pure:m !>([%error poll-err-msg]))
    (pure:m !>([%ok (need +.poll-resp)]))
::
::  Extract bot-id from bird
::
  ++  extract-bot-id
    |=  =bird
    ^-  bot-id
    :: this may need to be more robust, we're assuming that the content.memo.bird
    :: is a plain-text, inline, story (i.e. a simple @t)

    :: Type checking for a plain @t, will fail with code, blocks, highlights, embeds, etc.
    ?>  ?=(@t +>-.content.memo.bird)  
      =/  full-text  (trip +>-.content.memo.bird)
      =/  text  (run:regex "/[a-z,A-Z,0-9,-]+" full-text)  :: the first "/Some-thing-123" found in the text
      =/  trimmed-text  (oust [0 1] q.->+:(need text))                  :: trim the slash from the beginning
      (crip trimmed-text)
--
