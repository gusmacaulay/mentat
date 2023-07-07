=,  hmac:crypto
|_  [reg=@t op=@t secret=@t key=@t now=@da]
+$  purl  purl:eyre
++  auth-dbg
  |=  =request:http
  =/  bod       (pile body.request)
  =.  header-list.request   (attach header-list.request 'x-amz-content-sha256' bod)
  =.  header-list.request   (attach header-list.request 'x-amz-date' (crip clock))
  =/  canonical  (canonical request)
  =/  digest  (hash (crip canonical))
  =/  contract  (contract request digest)
  :*  canonical=canonical 
      digest=digest 
      contract=contract 
      signer=(en:base16:mimes:html 32 signer)
      sign=(sign contract)
  ==
++  auth
  |=  =request:http
  ^-  request:http
  ~&  "reg, op, secret, key, now: {<reg>} {<op>} {<secret>} {<key>} {<now>}"
    =.  header-list.request
    (cred request)
  ~&  "[auth] (cred-ed request) {<request>}"
  request
++  cred
  |=  =request:http
  ^-  header-list:http
  =/  bod       (pile body.request)
  =.  header-list.request   (attach header-list.request 'x-amz-content-sha256' bod)
  =.  header-list.request   (attach header-list.request 'x-amz-date' (crip clock))
  %^  attach  header-list.request
    'Authorization'
  %-  crip
  %+  weld
    "AWS4-HMAC-SHA256 "
  ^-  tape
  %-  zing  
  %+  join
    ", "
  ^.  (list tape)
  :~  ;:  weld
          "Credential="
          (trip key)
          "/"
          scope
      ==
      %+  weld
          "SignedHeaders="
          %-  facet
            +:(crest header-list.request)
      %+  weld
          "Signature="
          %-  trip
            %-  sign
          %+  contract
            request
          %-  hash
            %-  crip
          (canonical request)
  ==
++  sign
  |=  deal=@t
  %+  en:base16:mimes:html  32 
  (hmac-sha256 signer (swp 3 deal))
++  signer
  %+  hmac-sha256
    %+  hmac-sha256
      %+  hmac-sha256
        %+  hmac-sha256t
          (crip (weld "AWS4" (trip secret)))
        (crip cal)
      (swp 3 reg)
    (swp 3 op)
  (swp 3 'aws4_request')
++  contract
  |=  [=request:http digest=@t]
  ^-  @t
  =/  hydra=(map @t @t)  (malt header-list.request)
  %-  crip
  %+  weld
    %+  roll
      ^-  (list tape)
      :~  "AWS4-HMAC-SHA256"
          %-  trip
            %+  ~(gut by hydra)
              'x-amz-date'
            (crip clock)
          scope
      ==
    link
  (trip digest)
++  scope
  ^-  tape
  %+  join  '/'
    ^-  (list @t)
    :~  (crip cal)
        reg
        op
        'aws4_request'
    ==  
++  canonical
  |=  =request:http
  =/  url=purl  (need (de-purl:html url.request))
  =/  crown     (crest header-list.request)
  %+  weld
    %+  roll
      ^-  (list tape)
      :~  `tape`[method.request ~]
          (trail url)
          (quiz url)
          -.crown
          (facet +.crown)
      ==
    link
  (trip (pile body.request))
++  link
  |=  [item=tape pole=tape]
  ^-  tape
  (weld pole (snoc item '\0a'))
++  trail
  |=  url=purl
  ^-  tape
  =/  parts=(list tape)  (turn q.q.url trip)
  =/  road=tape  `tape`(zing (join "/" `(list tape)`(turn parts en-urlt:html)))
  :: ASM ensure that file extension is added if we have one
  ?~  p.q.url
    :: no file extension
      (weld ~['/'] road)
  :: have file extension
  =/  last  (rear parts)
  =/  extn  ;:(weld last "." (trip +:p.q.url))
  =/  new-parts=(list tape)  (snoc (snip parts) extn)
  =/  new-road=tape  `tape`(zing (join "/" `(list tape)`(turn new-parts en-urlt:html)))
  (weld ~['/'] new-road)
  
::  =/  ext=tape  ?~  p.q.url  :: no file extension
::    ~
::  (trip +:p.q.url)
::  ::~&  "[ASM] TRAIL - extension: {<+:p.q.url>}"
::  =/  parts=(list tape)  (turn q.q.url trip)
::  ::=/  ext=tape  (trip +:p.q.url)
::  ~&  "[ASM] TRAIL - parts {<parts>} - ext {<ext>}"
::  =/  road=tape  `tape`(zing (join "/" `(list tape)`(turn parts en-urlt:html)))
::  :: ASM
::  :: should be full path including extension (so last tape in list gets extension appended?)
::  :: then uri encode
::  :: then join with '/'
::  :: how do I add the ext to the last list element???
::  ?~  ext
::    ~&  "[ASM] TRAIL - road {<(weld ~['/'] road)>}"
::    (weld ~['/'] road)
::  =/  last  (rear parts)  :: last element
::  =/  extn  ;:(weld last "." ext)
::  =/  new-parts=(list tape)  (snoc (snip parts) extn)
::  =/  new-road=tape  `tape`(zing (join "/" `(list tape)`(turn new-parts en-urlt:html)))
::  ~&  "[ASM] TRAIL - new-road {<(weld ~['/'] new-road)>}"
::  (weld ~['/'] new-road)
::    
::  ::(weld ~['/'] road)  ::original
::  ::(weld ~['/'] new-road)
++  quiz
  |=  url=purl
  =/  quay  r.url
  ^-  tape
  ?~  quay  ""
  =/  squr  %+  sort  quay
  |=  [a=[@t @t] b=[@t @t]]
  (gth -.a -.b)
  =/  tqur  %+  turn  squr
  |=  item=[@t @t]
  :(weld (en-urlt:html (trip -.item)) "=" (en-urlt:html (trip +.item)))
  %+  roll  `(list tape)`(join "&" tqur)
  |=  [item=tape pole=tape]
  (weld pole item)
++  crest
  |=  heads=header-list:http 
  :: ASM - redo this so that the list of headers and values
  :: is also returned in alphabetical order (as per Amazon S3 doc)
  =/  sorted-heads  (sort heads aor) 
  =/  sorted-cleaned-heads  (turn sorted-heads |=([k=@t v=@t] [(crip (cass (trip k))) (crip (trimall v))]))
  =/  heads-tape  `tape`(zing (turn sorted-cleaned-heads |=([k=@t v=@t] ;:(weld (trip k) ":" (snoc (trip v) '\0a')))))
  [heads-tape `(map @t @t)`(malt sorted-cleaned-heads)]

::  =/  hydra=(map @t @t)  (malt heads)
::  %+  ~(rib by hydra)  *tape
::    |=  [[k=@t v=@t] acc=tape]
::    =/  key=tape    (cass (trip k))
::    =/  value=tape  (trimall v)
::    =/  combo=tape  (weld (snoc key ':') value)
::    :-  (link combo acc) 
::      [(crip key) (crip value)]
++  facet
  |=  heads=(map @t @t)
  ^-  tape
  =/  hydra=(list @t)  `(list @t)`~(tap in ~(key by heads))
  (join ';' (sort hydra aor))
++  pile
  |=  body=(unit octs)
  ^-  @t
  %-  hash
  ?~  body  ''  
    +:(need body)
++  hash
  |=  content=@t
  ~&  "[hash] content {<content>}"
  ^-  @t
  %+  en:base16:mimes:html  32 
  %^  rev  3
      32
  (shax content)
++  attach
  |=  [top=header-list:http key=@t value=@t]
  ^-  header-list:http
  =/  hydra  (malt top)
  %~  tap  by
  %+  ~(put by hydra)
    key
  value
++  trimall
  |=  value=@t
  |^  ^-  tape
  %+  rash  value
  %+  ifix  [(star ws) (star ws)]
  %-  star
  ;~  less
    ;~(plug (plus ws) ;~(less next (easy ~)))
    ;~(pose (cold ' ' (plus ws)) next)
  ==
  ++  ws  (mask " \0a\0d\09")
  --
++  cal
  (swag [0 8] clock)
++  clock
  (esoo now)
::  ISO8601
::
++  esoo
  |=  d=@d
  ^-  tape
  =/  t  (yore d)
  ;:  welp
      (scag 1 (scow %ud y.t))
      (swag [2 3] (scow %ud y.t))
      (double m.t)
      (double d.t.t)
      "T"
      (double h.t.t)
      (double m.t.t)
      (double s.t.t)
      "Z"
  ==
:: ud to leading zero tape
++  double
  |=  a=@ud
  ^-  tape
  =/  x  (scow %ud a)
  ?:  (lth a 10)
    (welp "0" x)
  x
--