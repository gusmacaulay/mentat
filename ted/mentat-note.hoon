::
:: %mentat sub-thread to process LLM requests
:: to add, edit, or comment on notes
::
/-  spider, *gato, *mentat
/-  d=diary, g=groups, ha=hark :: not sure which of these we'll need
/+  *strandio, *mentat, regex
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
=/  pre-prompt  'You are a helpful and very clever editor.  Always answer with a single JSON string in the format: {"notebook": $notebook-id "action": $action"data": $data}.  If you find a string in the input text that is in the format "~let/test-notebook/note/170141184506385861578430265978091732992" it must be returned as $notebook-id, otherwise return "null".  If you are asked to edit or modify a file, text or data, return $action with the value "edit".  If asked to comment or respond to a file, text or data return $action with the value "comment".  Return $data as a text string of all other parts of your response.'

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time

::
:: Ignore messages from other ships if set to %private
::
?:  &(=(view.model %private) ?!(=(msg-origin our)))
  ~&  "Message origin not our ship - ignoring"
  !!


::
:: Scan for note-id, if found, read in as context
::    note id format ~let/test-notebook/note/170141184506391138791970685596915990528
::
=/  note-id  (run:regex "~[a-z,-]+/[a-z,0-9,-]+/note/[0-9]*" (trip question))
;<  upd-q=vase  bind:m  ?:(=(note-id ~) (pure:m !>(question)) (append-note question (crip q.->+:(need note-id))))
=/  upd-question  !<(@t upd-q)
~&  "**** upd-question {<upd-question>}"

::
:: Query replicate.com
::
;<  replicate-vase=vase  bind:m  (query-replicate [bird model pre-prompt upd-question])
=/  replicate-resp  !<([@tas @t] replicate-vase)


?:  =(-.replicate-resp %error)
  (pure:m !>([%error `reply`+.replicate-resp ~]))

::
:: Text response
::
~&  "TEXT RESPONSE"
:: let's take the text output and use it to create a notebook instead
:: we need to poke diary.hoon with %diary-action (or %diary-action-1 or %diary-action-0 ??) and the diary-action

:: parse the (need +.poll-resp) as json, looking for the
:: notebook and data fields.
:: return the ship, channel, notebook id, and data
=/  json-resp  (need (de:json:html +.replicate-resp))
~&  "json-resp: {<json-resp>}"
=/  [shp=@p chn=@tas act=@tas id=time data=@t]  (decode-generated-notebook json-resp)
=/  flag=flag.g  [shp chn]  :: output to this ship & channel (regardless of group)

~&  "shp {<shp>}"
~&  "chn {<chn>}"
~&  "act {<act>}"
~&  "id {<id>}"
~&  "data {<data>}"

?+  act    (pure:m !>([%error `reply`'Unexpected error']))
    %add
  ~&  "inside default"
  :: default (can I do this??)
  =/  verse  [%inline `(list inline.d)`~[data]]

  =/  essay=essay.d
    :*  title='AI generated notebook'  :: this will be the name of the noteboook, but it will be assigned an id no.??
        image='https://wolfun.syd1.digitaloceanspaces.com/img--2023.7.11..01.07.50..4d65.jpg'
        content=`(list verse.d)`~[verse]
        author=our
        sent=(time now)
    ==

  =/  delt  [%add essay]  :: have to work out how to deal with '%comment' as the action
  ::=/  diff=diff.notes.d  [%notes (time now) delt]
  ::=/  diff-diary=diff.d  diff
  ::=/  flag-add=flag.g  [shp chn]
  =/  flag-add=flag.g  [our %test-notebook]  :: ASM the group should be passed in at setup
  =/  diff-diary=diff.d  [%notes (time now) delt]
  =/  diary-action=action.d  [flag-add [(time now) diff-diary]]
  ;<  ~            bind:m  (poke-our %diary [%diary-action-1 !>([diary-action])])
  (pure:m !>([%ok `reply`'Output in a new note.' 'Output in new note']))
  ::
    %edit
  ~&  "inside %edit"
  =/  verse  [%inline `(list inline.d)`~[data]]

  =/  essay=essay.d
    :*  title='AI generated notebook'  :: this will be the name of the noteboook, but it will be assigned an id no.??
        image='https://wolfun.syd1.digitaloceanspaces.com/img--2023.7.11..01.07.50..4d65.jpg'
        content=`(list verse.d)`~[verse]
        author=our
        sent=(time now)
    ==

  =/  delt  [act essay]
  
  ::=/  diff=diff.notes.d  [%notes id delt]
  ::=/  diff-diary=diff.d  diff
  
  =/  diff-diary=diff.d  [%notes id delt]
  
  =/  diary-action=action.d  [flag [*time diff-diary]]         :: for %edit, send *time, not now
  ;<  ~            bind:m  (poke-our %diary [%diary-action !>([diary-action])])
  (pure:m !>([%ok `reply`'Note edited.' 'Note edited']))
  ::
    %comment
  :: For note comment
  ~&  "inside %comment"
  =/  story=story.d  [*(list block.d) `(list inline.d)`~[data]]
  ::+$  story  (pair (list block) (list inline))
  =/  memo=memo.d
    :*  content=story
        author=our
        sent=(time now)
    ==

  =/  delt  [%quips *time [%add memo]]
  =/  diff-diary=diff.d  [%notes id delt]
  =/  diary-action=action.d  [flag [*time diff-diary]]         :: for %edit, send *time, not now
  ;<  ~            bind:m  (poke-our %diary [%diary-action !>([diary-action])])
  (pure:m !>([%ok `reply`'Commented on note.' 'Commented on note']))
==
