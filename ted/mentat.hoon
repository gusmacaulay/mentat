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
;<  our=@p         bind:m  get-our
;<  now=@da        bind:m  get-time


:: Ignore messages from other ships if set to %private
?:  &(=(view.model %private) ?!(=(msg-origin our)))
  ~&  "Message origin not our ship - ignoring"
  !!

=/  question  text.bird

::
:: Check centags to route question to correct sub-thread
::

=/  centag  (run:regex "%[a-z]+" (trip question))                                 :: the first "%blah" in the question
=/  cntg  ?:(=(centag ~) %default `@tas`(crip (oust [0 1] q.->+:(need centag))))  :: actual centag  

:: Map centag to sub-thread name
=/  cntg-tpl
  :~  [%chat %mentat-chat]
      [%clear %mentat-chat]
      [%query %mentat-query] 
      [%img %mentat-image] 
      [%comment %mentat-note]
      [%edit %mentat-note]
      [%note %mentat-note]
      [%default %mentat-query]
  ==

=/  cntg-map  (malt (limo cntg-tpl))
=/  sub-ted  (~(got by cntg-map) (cen-type cntg))  :: cast to cen-type

;<  query-vase=vase    bind:m  (custom-await-thread sub-ted !>([bird (cen-type cntg)]))
=/  query-result  !<([@tas [@tas reply]] query-vase)

?+  -.query-result  (pure:m !>(['Error in %mentat-query thread' vase.bird]))
    %fail
  :: thread itself failed
  =/  fail-msg  +.query-result
  (pure:m !>([+.fail-msg vase.bird]))
    %done
  :: thread succeeded, call to LLM may still have failed
  :: check +<.query result if necessary
  =/  done-msg  +.query-result
  (pure:m !>([+.done-msg vase.bird]))
==