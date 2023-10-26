::
:: %mentat sub-thread to set a message to be sent later
::
::  NB: 
::    User should specific "AM" for a given time
::      LLM will not consistently interpret user times as a 24-hour format
::    User should interpret all input and output times as UTC.
::    User must specify repetition as one of the pre-define intervals.
::      I experimented with a getting the LLM to produce a list of intervals, 
::      for a Pomodoro session for example, but had limited success in getting
::      accurate results.
::    Repeated events are limited to an arbitrary count of ten reps since there is no easy way to cancel them presently.
::    Repeated events may be stopped early (along with all other threads) with the Dojo :spider|kill
::
::  There is something wrong with running several events at once.
::    Running a one-off event at the same time as a repeated event generally works.
::    Running a one-off event while another one-off event is in progress generally doesn't.
::      The most recently started event wins, not the chronologically next event to happen.
::    With +timers / scrying %behn I have even observed:
::      Three timers waiting to %wake as expected, but only two produced the expected chat messages.
::
/-  spider, *gato, *mentat, c=chat, *mentat-remind
/+  *strandio, *mentat, regex
::
=>
|%
::
++  chat
  |=  [=flag.c message=@t]

  =/  m  (strand ,~)
  ;<  our=@p   bind:m  get-our
  ;<  now=@da  bind:m  get-time

  ?:  =(message '')
    (pure:m ~)
  =/  txt-list  ~[message]

  :: Need to send through a high precision time to get this to work
  =/  now-high-precision  (time (add now (unm:chrono:userlib now)))
  =/  id  `(pair ship time)`[our now-high-precision]

  =/  memo=memo:c
    :*  replying=~  :: ~ is latest message, an `id, which is [ship time] replies to a specific message
        author=p.id
        sent=q.id
        [%story [*(list block.c) `(list inline.c)`txt-list]]
    ==

  =/  delt-add  [%add memo]
  =/  diff-add  `diff:c`[%writs `diff:writs:c`[id delt-add]]
  =/  update-add  [q.id diff-add]
  =/  action-add=action.c  [flag update-add]

  ;<  ~  bind:m  (poke-our %chat [%chat-action-0 !>([action-add])])
  (pure:m ~)
::
++  get-start
  |=  [now=@da delay=@dr when=@da]
  ?~  delay
    when
  (add delay now)
::
++  get-next-delay
  |=  =freq
  ^-  @dr
  ?-  freq
    %once      ~s0
    %minutely  ~m1
    %hourly    ~h1
    %daily     ~d1
    %weekly    ~d7
  ==
--
::
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
=/  question-raw  text.bird

::
::  Remove a possible %remind centag prefix from the user input.
::  Maybe the parent thread should do this for all child threads.
::
=/  question  
%-  crip
%+  fall
  (rust (trip question-raw) ;~(pfix (jest '%remind') (star prn)))
(trip question-raw)

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time
  
::
:: Ignore messages from other ships if set to %private
::
?:  &(=(view.model %private) ?!(=(msg-origin our)))
  !!

::  UTC
=/  dt  (yore now)
::  "2.023" -> "2023"
::
=/  y-text  (scow %ud y:dt)
=/  y=tape  (weld (scag 1 y-text) (swag [2 3] y-text))
::
=/  sys-prompt-context  "The current year is {<y>}. The current month is {<m:dt>}. The current day of the month is {<d.t:dt>}. The current hour is {<h.t:dt>}. The current minute is {<m.t:dt>}. The current second is {<s.t:dt>}."
=/  sys-prompt-static  'You are a helpful and very clever assistant for setting reminders. Your entire answer must be a JSON document in the format: {"action": $action, "delay": $delay, "when": $when, "repeat": $repeat, "message": $message}. Never under any circumstances respond with anything but a JSON document. $action may be "remind" or "poke". $delay may be null. $delay is a period of time until the message will be sent, expressed as a whole number of seconds. If the user does not ask for a duration of time $delay must be set to null. $when is a string. $when may be null. $when is an ISO time-stamp when the message will be sent. $when will have no UTC offset. If $delay is null then $when is null.  $repeat may be "minutely", "hourly", "daily", "weekly" or "once". $repeat defaults to "once". $message is a string which is the reminder text to send later.'
=/  sys-prompt  (crip (weld sys-prompt-context (trip sys-prompt-static)))

::
:: Query replicate.com
::
;<  replicate-vase=vase  bind:m  (query-replicate [bird model sys-prompt question])
=/  replicate-resp  !<([@tas @t] replicate-vase)

::
:: Return [@tas reply] to ted/mentat.hoon
::
?+  -.replicate-resp  (pure:m !>([%error 'Error in replicate.com response' ~]))
    %error
  (pure:m !>([%error `reply`+.replicate-resp ~]))
    %ok
  =/  json-maybe  (de:json:html +.replicate-resp)
  ?~  json-maybe
    (pure:m !>([%error 'ERROR: LLM response not JSON' ~]))
  ::  TODO +decode-generate-reminder should produce a unit
  ::    ?~  reminder  (pure:m !>([%error 'ERROR: LLM response not understood' ~]))
  ::
  =/  reminder  (decode-generated-reminder (need json-maybe))
  ~&  "delay: {<delay:reminder>}"
  ~&  "when: {<when:reminder>}"
  ?:  =(action:reminder %poke)
    (pure:m !>([%error '%poke is not yet supported' ~]))
  ::
  =/  rep  0
  =/  max-rep  10
  ;<  now=@da  bind:m  get-time
  =/  start  (get-start now delay:reminder when:reminder)
  |-
  ~&  "now: {<now>}"
  ~&  "start: {<start>}"
  =/  =task:behn  [%wait start]
  =/  =card:agent:gall  [%pass /mentat-reminder %arvo %b task]
  =/  event-start-text=@t  ?:(=(rep 0) (crip "Event set for {<start>}") '')
  =/  event-trigger-text=@t  ?:(=(rep 0) '' message:reminder)
  ?:  =(rep max-rep)
    (pure:m !>([%ok `reply`message:reminder `@t`message:reminder]))
  ;<  ~  bind:m  (chat flag.bird event-start-text)
  ;<  ~  bind:m  (chat flag.bird event-trigger-text)
  ;<  ~  bind:m  (send-raw-card card)
  ;<  res=(pair wire sign-arvo)  bind:m  take-sign-arvo
  ?>  ?=([%mentat-reminder ~] p.res)
  ?>  ?=([%behn %wake *] q.res)
  ?~  error.q.res
    ?:  =(repeat:reminder %once)
      (pure:m !>([%ok `reply`message:reminder `@t`message:reminder]))
    ;<  now=@da  bind:m  get-time
    =/  next-delay=@dr  (get-next-delay repeat:reminder)
    ~&  "now: {<now>}"
    ~&  "next-delay: {<next-delay>}"
    $(start (add now next-delay), rep +(rep))
  (pure:m !>([%error 'ERROR: %behn timer' ~]))
  ==