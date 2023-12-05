::
:: %mentat sub-thread to create images from LLM and store
:: them in users S3 bucket if available
::
/-  spider, *gato, s=storage, *mentat
/+  *strandio, aws, *mentat, regex
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
=/  pre-prompt  ''
=/  auth  ['Authorization' (crip (weld "Token " (trip api-key.model)))]

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time

::
:: Ignore messages from other ships if set to %private
::
?:  &(=(view.model %private) ?!(=(msg-origin our)))
  !!

::
:: Query replicate.com
::
;<  replicate-vase=vase  bind:m  (query-replicate [bird model pre-prompt question])
=/  replicate-resp  !<([@tas @t] replicate-vase)

?:  =(-.replicate-resp %error)
  (pure:m !>([%error `reply`+.replicate-resp +.replicate-resp]))

::
:: Image response (poke silo with returned data)
::
:: Get S3 credentials and configuration - (S3-store has been changed to storage)
;<  cred=update.s  bind:m  (scry update.s `path`['gx' 'storage' 'credentials' 'noun' ~])
;<  cnfg=update.s  bind:m  (scry update.s `path`['gx' 'storage' 'configuration' 'noun' ~])

?>  ?=([%credentials *] cred)
=/  endpoint  endpoint.credentials.cred
=/  secret  secret-access-key.credentials.cred
=/  access-id  access-key-id.credentials.cred

?>  ?=([%configuration *] cnfg)
=/  bucket  current-bucket.configuration.cnfg
=/  region  region.configuration.cnfg

:: No S3 credentials, return error message and replicate link (available 24hrs only)
?:  |(=(endpoint '') =(access-id '') =(secret '') =(bucket '') =(region ''))
  =/  s3-unavailable-msg  (crip (weld "No S3 access - temporary link: " (trip +.replicate-resp)))
  (pure:m !>([%ok `reply`[%story [[[%image +.replicate-resp 300 300 'mentat generated image'] ~] [[s3-unavailable-msg] ~]]] s3-unavailable-msg]))

;<  image-vase=vase       bind:m  (get-image +.replicate-resp auth)
=/  image-data  !<([@tas (unit @t) (unit mime)] image-vase)

?+  -.image-data  (pure:m !>([%error `reply`'[mentat] unknown error' 'unknown %mentat error']))
    %redirect
  ::try again with redirect url (just fail out if we don't get an image result)
  ;<  redirect-vase=vase    bind:m  (get-image (need +<.image-data) auth)
  =/  redirect-data  !<([@tas (unit @t) (unit mime)] redirect-vase)
  ?.  =(-.redirect-data %ok)  (pure:m !>([%error `reply`'[mentat] image generation redirect error' 'mentat error - image generation redirect failed']))
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.redirect-data) (need +<.redirect-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?+  -.s3-return  (pure:m !>([%error `reply`'[mentat] unknown error' 'unknown %mentat error']))
      %error
    (pure:m !>([%error `reply`+.s3-return +.s3-return]))
      %ok
    (pure:m !>([%ok `reply`[%story [[[%image +.s3-return 300 300 'mentat generated image'] ~] [[+.s3-return] ~]]] +.s3-return]))
  ==
    %fail
  (pure:m !>([%error `reply`(crip (weld "[mentat] error: " (trip (need +<.image-data)))) (need +<.image-data)]))
    %ok
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.image-data) (need +<.image-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?+  -.s3-return  (pure:m !>([%error `reply`'[mentat] unknown error' 'unknown %mentat error']))
      %error
    (pure:m !>([%error `reply`+.s3-return +.s3-return]))
      %ok
    (pure:m !>([%ok `reply`[%story [[[%image +.s3-return 300 300 'mentat generated image'] ~] [[+.s3-return] ~]]] +.s3-return]))
  ==
==
