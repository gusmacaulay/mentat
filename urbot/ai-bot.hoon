/-  spider, *gato, *s3
/+  *strandio, aws
=,  strand=strand:spider
|%
  ::  Parse the user input
  ::
  ::    A needle such as "foo=" in a haystack such as "this is foo=bar really"
  ::    Will return the value "bar"
  ::

::  ++  aws-client  ~(. aws [reg 's3' secret key now])

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
  ++  decode-response
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
--
=/  m  (strand ,vase)
^-  thread:spider
|=  arg=vase
^-  form:m
=/  =bird  !<(bird arg)

:: stack trace on
!:

~&  "Running urbit AI chatbot"

::
:: Parse text.bird
::

=/  msg-origin=@p  author.memo.bird
;<  our-ship=@p   bind:m  get-our

:: is vase.bird the original text the 
:: bot was set up with?? Can use this
:: as the ai-url to call
:: or ai=<api-url> key=<api-key>

:: keep, or remove this as required
:: without it, the bot will respond
:: to chat messages originating from
:: any ship.
?.  =(msg-origin our-ship)
  ~&  "Message origin not our ship - ignoring"
  !!
::  Need to ensure we're only interacting with our own ship's questions
=/  question  text.bird

::
:: Build HTTP request for Hugging Face
::
:: URL
=/  url  'https://api-inference.huggingface.co/models/Joeythemonster/anything-midjourney-v-4-1'

:: Headers (Auth key must be hidden!  ** DO NOT COMMIT **)
=/  type  ['Content-Type' 'application/json']
=/  auth  ['Authorization' 'Bearer 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']

=/  headers  `(list [@t @t])`[type auth ~]

:: Body
=/  prompt  ['inputs' s+question]

:: Depending on whether or not this is running before 
:: or after the breaking json changes
:: 413
::  =/  json-body  (en:json:html o+(malt (limo ~[prompt])))
:: 414+
=/  json-body  (crip (en-json:html o+(malt (limo ~[prompt]))))

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
?~  resp 
:: response is [%done ~] from %cancel
  (pure:m !>(['http error - cancelled' vase.bird]))
:: reponse is [%done `client-response] from %finished
;<  our=@p     bind:m  get-our
;<  now=@da    bind:m  get-time
::  Poke silo with the mime

::
:: Text/chat response
::
::;<  answer=@t  bind:m  (extract-body (need resp))
:: 413
::=/  answer-json  (de:json:html answer)  
:: 414+
::=/  answer-json  (need (de-json:html answer))
::=/  ai-answer  (decode-response answer-json)

::(pure:m !>([ai-answer vase.bird]))

::
:: Image response
::
~&  "extracting http response body..."
;<  answer=mime  bind:m  (extract-mime-body (need resp))
::~&  "... response recieved {<answer>}"  ::binary response

:: Get S3 credentials and configuration
;<  cred=update  bind:m  (scry update `path`['gx' 's3-store' 'credentials' 'noun' ~])
;<  cnfg=update  bind:m  (scry update `path`['gx' 's3-store' 'configuration' 'noun' ~])

::~&  "config is: {<+.cnfg>}"
?>  ?=([%credentials *] cred)
=/  endpoint  endpoint.credentials.cred
=/  secret  secret-access-key.credentials.cred
=/  access-id  access-key-id.credentials.cred

?>  ?=([%configuration *] cnfg)
=/  bucket  current-bucket.configuration.cnfg
=/  region  region.configuration.cnfg

~&  "{<endpoint>}  {<secret>}  {<access-id>}  {<bucket>}  {<region>}"

:: host should be wolfun.syd1.digitaloceanspaces.com according to spaces example
:: ** silo front-end sends to syd1.digitaloceanspaces.com
=/  bare-host  (scan (trip endpoint) ;~(pfix (jest 'https://') (star prn)))  :: syd1.digitaloceanspaces.com
=/  host  (crip ;:(weld (trip bucket) "." bare-host))  :: spaces example
::=/  host  (crip bare-host)                             :: silo front-end

~&  "host is: {<host>}" 

=/  filename  'file4.jpg'

:: url should be wolfun.syd1.digitaloceanspaces.com/<file/key> according to spaces specs
:: ** silo front end sends to the url: https://syd1.digitaloceanspaces.com/wolfun/date-stamp-filename?x-id=PutObject
=/  s3-url  (crip ;:(weld "https://" (trip bucket) "." bare-host "/" (trip filename)))  :: spaces spec
::=/  s3-url  (crip ;:(weld "https://" bare-host "/" (trip bucket) "/" (trip filename)))  :: silo front-end
~&  "endpoint-url: {<s3-url>}"

:: Get content-length, convert to @t to go in header
=/  answ-lent  `tape`(scow %ud p.q.answer)                      :: gives "13.245" instead of "13245"
=/  cont-lent  (crip `tape`(skip answ-lent |=(a=@ =('.' a))))   :: '13245'
~&  "cont-lent {<cont-lent>}" 

:: ** silo front-end sends as image/jpeg
::=/  content-type  'application/octet-stream'
=/  content-type  'image/jpeg'

::  set up aws (lib/aws.hoon)
=/  aws-client  ~(. aws [region 's3' secret access-id now])

=/  s3-headers=(list [@t @t])  ~[['Host' host] ['Date' (crip (dust:chrono:userlib (yore now)))] ['Content-Length' cont-lent] ['content-type' content-type]]
~&  "s3-headers list is: {<s3-headers>}"

=/  s3-req=request:http
  :*  method=%'PUT'                                   :: 'PUT' file on S3
      url=s3-url                                      :: url as cord
      header-list=s3-headers                          :: (list [key=@t value=@t])
      `q.answer                                       :: body - image file as mime
  ==

=/  authenticated-req  (auth:aws-client s3-req)  ::authenticate request
~&  "authenticated-req: {<authenticated-req>}"

;<  ~                                    bind:m  (send-request authenticated-req)
;<  s3-resp=(unit client-response:iris)  bind:m  take-maybe-response  

?~  s3-resp 
  :: response is [%done ~] from %cancel
  (pure:m !>(['s3 upload failed - cancelled' vase.bird]))
::=/  ret-type  -:(need s3-resp)
::?+  ret-type  (pure:m !>(['s3 upload failed']))
::  %finished
=/  ret-msg  +:(need s3-resp)
=/  ret-file  +.ret-msg
=/  ret-xml  (cord +>+.ret-file)
~&  "xml is: {<ret-xml>}"

::=/  ret-xml  (cord q.data.full-file.ret-msg)
::=/  ret-xml  (cord q.data.+>.ret-msg)
::~&  "ret-xml is: {<ret-xml>}"

:: create link for user and return in chat:
::=/  image-link  

(pure:m !>(['image file generated' vase.bird]))