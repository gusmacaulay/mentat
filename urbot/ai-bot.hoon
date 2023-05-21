/-  spider, *gato
/+  *strandio
=,  strand=strand:spider
|%
  ::  Parse the user input
  ::
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
--
=/  m  (strand ,vase)
^-  thread:spider
|=  arg=vase
^-  form:m
=/  =bird  !<(bird arg)

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

:: Base our request off this curl request:
:: https://platform.openai.com/docs/api-reference/completions/create for more info
:: may also be able to use /chat/completions for a full chatbot experience

::
:: Build HTTP request
::
:: Headers (Authorization key should be hidden! ** DO NOT COMMMIT **')
=/  type  ['Content-Type' 'application/json']
=/  auth  ['Authorization' 'Bearer <**** KEY HERE ****>']

=/  headers  `(list [@t @t])`[type auth ~]

:: Body
  =/  model  ['model' s+'text-davinci-003']
  =/  prompt  ['prompt' s+question]
  =/  temperature  ['temperature' n+'0.75']
  =/  tokens  ['max_tokens' n+'256']

:: Depending on whether or not this is running before 
:: or after the breaking json changes
:: 413
::  =/  json-body  (en:json:html o+(malt (limo ~[model prompt temperature tokens])))
:: 414+
  =/  json-body  (crip (en-json:html o+(malt (limo ~[model prompt temperature tokens]))))

  =/  =request:http
    :*  method=%'POST'                                  :: 'POST', not 'GET'
        url='https://api.openai.com/v1/completions'     :: url as cord
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
  ;<  answer=@t  bind:m  (extract-body (need resp))
  :: 413
  ::=/  answer-json  (de:json:html answer)  
  :: 414+
  =/  answer-json  (need (de-json:html answer))
  =/  ai-answer  (decode-response answer-json)
  (pure:m !>([ai-answer vase.bird]))
