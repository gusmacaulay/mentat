::
:: %mentat sub-thread to create images from LLM and store
:: them in users S3 bucket if available
::
/-  spider, *gato, *s3, *mentat
/+  *strandio, aws, *mentat, regex
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
=/  auth  ['Authorization' (crip (weld "Token " (trip api-key.model)))]

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time

::
:: Query replicate.com
::
;<  replicate-vase=vase  bind:m  (query-replicate [bird model pre-prompt question])
=/  replicate-resp  !<([@tas @t] replicate-vase)

?:  =(-.replicate-resp %error)
  (pure:m !>([%error `reply`+.replicate-resp]))

::
:: Image response (poke silo with returned data)
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
  =/  s3-unavailable-msg  (crip (weld "No S3 access - temporary link: " (trip +.replicate-resp)))
  (pure:m !>([%ok `reply`[%story [[[%image +.replicate-resp 300 300 'mentat generated image'] ~] [[s3-unavailable-msg] ~]]]]))

;<  image-vase=vase       bind:m  (get-image +.replicate-resp auth)
=/  image-data  !<([@tas (unit @t) (unit mime)] image-vase)

?+  -.image-data  (pure:m !>([%error `reply`'[mentat] unknown error']))
    %redirect
  ::try again with redirect url (just fail out if we don't get an image result)
  ;<  redirect-vase=vase    bind:m  (get-image (need +<.image-data) auth)
  =/  redirect-data  !<([@tas (unit @t) (unit mime)] redirect-vase)
  ?.  =(-.redirect-data %ok)
    (pure:m !>([%error `reply`'[mentat] image generation redirect error']))
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.redirect-data) (need +<.redirect-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?+  -.s3-return  (pure:m !>(['[mentat] unknown error' vase.bird]))
      %error
    (pure:m !>([%error `reply`+.s3-return]))
      %ok
    (pure:m !>([%ok `reply`[%story [[[%image +.s3-return 300 300 'mentat generated image'] ~] [[+.s3-return] ~]]]]))
  ==
    %fail
  (pure:m !>([%error `reply`(crip (weld "mentat] error: " (trip (need +<.image-data))))]))
    %ok
  :: upload data to s3
  ;<  s3-link=vase    bind:m  (s3-upload (need +>.image-data) (need +<.image-data) auth bucket region secret access-id endpoint)
  =/  s3-return  !<([@tas @t] s3-link)
  ?+  -.s3-return  (pure:m !>([%error `reply`'[mentat] unknown error']))
      %error
    (pure:m !>([%error `reply`+.s3-return]))
      %ok
    (pure:m !>([%ok `reply`[%story [[[%image +.s3-return 300 300 'mentat generated image'] ~] [[+.s3-return] ~]]]]))
  ==
==