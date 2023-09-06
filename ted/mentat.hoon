/-  spider, *gato, *s3, *mentat
/-  d=diary, g=groups, ha=hark :: not sure which of these we'll need
/+  *strandio, aws, *mentat, regex
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
;<  now=@da        bind:m  get-time

::
:: Pre-prompt
::
::=/  pre-prompt  'You are a helpful and very clever editor.  Always answer as helpfully as possible.  Your answers must always be returned as correctly formatted as JSON.  If you find a string in the input text that is in the format "~let/test-notebook/note/$id" it must be returned in the JSON field "notebook", otherwise return a null "notebook" field.  All other parts of your response must be returned in the field "data".'
::=/  pre-prompt  'You are a helpful and very clever editor.  Always answer as helpfully as possible.  Your answers must always be returned as correctly formatted as JSON.  If you find a string in the input text that is in the format "~let/test-notebook/note/$id" it must be returned in the JSON field "notebook", otherwise return a null "notebook" field.  If you are asked to edit or modify a file, text or data, return a JSON field "action" with the value "edit".  If asked to comment or respond to a file, text or data return the value "comment" in the "action" field. All other parts of your response must be returned as a text string, prepended with "%mentat:" in the field "data".'
=/  pre-prompt  'You are a helpful and very clever editor.  Always answer as helpfully as possible.  Your answers must always be returned as correctly formatted JSON in the format: {"notebook": $notebook-id "action": $action"data": $data}.  If you find a string in the input text that is in the format "~let/test-notebook/note/170141184506385861578430265978091732992" it must be returned as $notebook-id, otherwise return "null".  If you are asked to edit or modify a file, text or data, return $action with the value "edit".  If asked to comment or respond to a file, text or data return $action with the value "comment".  All other parts of your response must be returned as $data, a text string, prepended with "%mentat:".'


:: Ignore messages from other ships if set to %private
?:  &(=(view.model %private) ?!(=(msg-origin our-ship)))
  ~&  "Message origin not our ship - ignoring"
  !!

=/  question  text.bird

:::: TODO:
:::: Check "hashtags" (actually cen-tags e.g %blah) to route question to correct LLM
::::
::=/  query-txt  (run:regex "%[a-z]*" txt)
::=/  query-type  ?~(query-txt %default `@tas`(crip (oust [0 1] q.->+:(need query-txt))))
::?+  query-type  (pure:m !>('[%mentat] catastrophic regex error')) 
::    %chat
::  :: chatbot
::    %query
::  :: simple q & a (no chat component)
::    %pic
::  :: image
::    %comment
::  :: comment on a notebook
::    %default
::  :: default to chat, but maybe add some other smarts around it
::  :: can search for note-id, if it's there assume it's a comment/edit
::  :: can have some default output to let the user know that they
::  :: haven't selected an action


::
:: Scan for note-id, if found, read in as context
::    note id format ~let/test-notebook/note/170141184506391138791970685596915990528
::
=/  note-id  (run:regex "~[a-z,-]+/[a-z,0-9,-]+/note/[0-9]*" (trip question))
;<  upd-q=vase  bind:m  ?:(=(note-id ~) (pure:m !>(question)) (append-note question (crip q.->+:(need note-id))))
=/  upd-question  !<(@t upd-q)

::
:: Clear conversation if requested
::
?:  &(=(question 'clear') =(type.model %conversation))
  ;<  clear-key=@t  bind:m  (generate-conv-key bird)
  ;<  ~             bind:m  (poke-our %mentat [%clear !>(clear-key)])
  (pure:m !>(['** conversation cleared **' vase.bird]))
  
::
:: Build conversation for request to %conversation model if necessary
::
::;<  qst-vase=vase  bind:m  ?:(=(type.model %conversation) (build-conversation bird) (pure:m !>(question)))
;<  qst-vase=vase  bind:m  ?:(=(type.model %conversation) (build-conversation bird) (pure:m !>(upd-question)))
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
=/  json-body  (build-request-body [model pre-prompt qst])

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
~&  "[mentat] Have AI response - processing..."

?~  resp 
  :: response is [%done ~] from %cancel
  (pure:m !>(['http error - cancelled' vase.bird]))

;<  our=@p     bind:m  get-our
;<  now=@da    bind:m  get-time

:: Extract status-code from xml
=/  status-code  status-code.response-header.+>-.resp
?.  |(=(status-code 200) =(status-code 201))
    ~&  "[mentat] error - AI returned non 200/201 status code"
    =/  return-msg  (crip ;:(weld "Error!  AI returned status code " (scow %ud status-code)))
    (pure:m !>([return-msg vase.bird]))

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
;<  ~            bind:m  (poke-our %mentat [%add !>([conv-key [%user qst]])])
;<  ~            bind:m  (poke-our %mentat [%add !>([conv-key [%ai (need +.poll-resp)]])])

(pure:m !>([(need +.poll-resp) vase.bird]))

  %text-generation
::
:: Text response
::

:: let's take the text output and use it to create a notebook instead
:: we need to poke diary.hoon with %diary-action and the diary-action

:: parse the (need +.poll-resp) as json, looking for the
:: notebook and data fields.
:: return the ship, channel, notebook id, and data
=/  json-resp  (need (de:json:html (need +.poll-resp)))
~&  "json-resp: {<json-resp>}"
=/  [shp=@p chn=@tas act=@tas id=time data=@t]  (decode-generated-notebook json-resp)
=/  flag=flag.g  [shp chn]  :: output to this ship & channel (regardless of group)

~&  "shp {<shp>}"
~&  "chn {<chn>}"
~&  "act {<act>}"
~&  "id {<id>}"
~&  "data {<data>}"

?+  act    (pure:m !>(['Error' vase.bird]))
    %add
  ~&  "inside default"
  :: default (can I do this??)
  =/  verse  [%inline `(list inline.d)`~[data]]

  =/  essay=essay.d
    :*  title='AI generated notebook'  :: this will be the name of the noteboook, but it will be assigned an id no.??
        image='https://wolfun.syd1.digitaloceanspaces.com/img--2023.7.11..01.07.50..4d65.jpg'
        content=`(list verse.d)`~[verse]
        author=our-ship
        sent=(time now)
    ==

  =/  delt  [%add essay]  :: have to work out how to deal with '%comment' as the action
  ::=/  diff=diff.notes.d  [%notes (time now) delt]
  ::=/  diff-diary=diff.d  diff
  ::=/  flag-add=flag.g  [shp chn]
  =/  flag-add=flag.g  [our-ship %test-notebook]  :: ASM the group should be passed in at setup
  =/  diff-diary=diff.d  [%notes (time now) delt]
  =/  diary-action=action.d  [flag-add [(time now) diff-diary]]
  ;<  ~            bind:m  (poke-our %diary [%diary-action !>([diary-action])])
  (pure:m !>(['Output in a new note.' vase.bird]))
  ::
    %edit
  ~&  "inside %edit"
  =/  verse  [%inline `(list inline.d)`~[data]]

  =/  essay=essay.d
    :*  title='AI generated notebook'  :: this will be the name of the noteboook, but it will be assigned an id no.??
        image='https://wolfun.syd1.digitaloceanspaces.com/img--2023.7.11..01.07.50..4d65.jpg'
        content=`(list verse.d)`~[verse]
        author=our-ship
        sent=(time now)
    ==

  =/  delt  [act essay]
  
  ::=/  diff=diff.notes.d  [%notes id delt]
  ::=/  diff-diary=diff.d  diff
  
  =/  diff-diary=diff.d  [%notes id delt]
  
  =/  diary-action=action.d  [flag [*time diff-diary]]         :: for %edit, send *time, not now
  ;<  ~            bind:m  (poke-our %diary [%diary-action !>([diary-action])])
  (pure:m !>(['Note edited.' vase.bird]))
  ::
    %comment
  :: For note comment
  ~&  "inside %comment"
  =/  story=story.d  [*(list block.d) `(list inline.d)`~[data]]
  ::+$  story  (pair (list block) (list inline))
  =/  memo=memo.d
    :*  content=story
        author=our-ship
        sent=(time now)
    ==

  =/  delt  [%quips *time [%add memo]]
  =/  diff-diary=diff.d  [%notes id delt]
  =/  diary-action=action.d  [flag [*time diff-diary]]         :: for %edit, send *time, not now
  ;<  ~            bind:m  (poke-our %diary [%diary-action !>([diary-action])])
  (pure:m !>(['Commented on note.' vase.bird]))
==

:::: test by doing it manually:
::::=/  diff=diff.notes.d  [%notes ~2023.8.28..00.18.43..ed84 delt]
::=/  diff=diff.notes.d  [%notes id delt]
:::: if act is %edit then use id, if %comment, use id, if neither then act must be %add, and id = ~ (sys gen)
::
::=/  diff-diary=diff.d  diff
::
::::=/  flag=flag.g  [our-ship %test-notebook]  :: output to this ship & channel (regardless of group)
::=/  flag=flag.g  [shp chn]  :: output to this ship & channel (regardless of group)
::
::::=/  diary-action=action.d  [flag [(time now) diff-diary]]
::=/  diary-action=action.d  [flag [*time diff-diary]]         :: for %edit, send *time, not now
::
::;<  ~            bind:m  (poke-our %diary [%diary-action !>([diary-action])])
::(pure:m !>(['Output in a new note.' vase.bird]))

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
  (pure:m !>([`reply`[%story [[[%image (need +.poll-resp) 300 300 'mentat generated image'] ~] [[s3-unavailable-msg] ~]]] vase.bird]))

;<  image-vase=vase       bind:m  (get-image (need +.poll-resp) auth)
=/  image-data  !<([@tas (unit @t) (unit mime)] image-vase)

?+  -.image-data  (pure:m !>(['[mentat] unknown error' vase.bird]))
    %redirect
  ::try again with redirect url (just fail out if we don't get an image result)
  ;<  redirect-vase=vase    bind:m  (get-image (need +<.image-data) auth)
  =/  redirect-data  !<([@tas (unit @t) (unit mime)] redirect-vase)
  ?.  =(-.redirect-data %ok)
    (pure:m !>(['[mentat] image generation redirect error' vase.bird]))
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.redirect-data) (need +<.redirect-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?+  -.s3-return  (pure:m !>(['[mentat] unknown error' vase.bird]))
      %error
    (pure:m !>([+.s3-return vase.bird]))
      %ok
    (pure:m !>([`reply`[%story [[[%image +.s3-return 300 300 'mentat generated image'] ~] [[+.s3-return] ~]]] vase.bird]))
  ==
    %fail
  (pure:m !>([(crip (weld "mentat] error: " (trip (need +<.image-data)))) vase.bird]))
    %ok
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.image-data) (need +<.image-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?+  -.s3-return  (pure:m !>(['[mentat] unknown error' vase.bird]))
      %error
    (pure:m !>([+.s3-return vase.bird]))
      %ok
    (pure:m !>([`reply`[%story [[[%image +.s3-return 300 300 'mentat generated image'] ~] [[+.s3-return] ~]]] vase.bird]))
  ==
==
==