::
:: %mentat sub-thread to process LLM requests
:: to add, edit, or comment on notes
::
/-  spider, *gato, *mentat, tasks, *mentat-chat
/-  d=diary, g=groups, ha=hark, c=chat :: not sure which of these we'll need
/+  *strandio, *mentat, *mentat-chat, regex
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
=/  pre-prompt  'You are a JSON producing personal assistant. YOU CAN ONLY PRODUCE JSON OBJECTS.  ALWAYS REPLY WITH ONLY A SINGLE VALID JSON OBJECT REGARDLESS OF THE PROMPT.  DO NOT PUT ANYTHING ELSE IN THE REPLY EXCEPT VALID JSON.  Please reply to my prompts in a succinct and helpful way. I will tell you things I need to to do, you will reply with a JSON object which contains your chat response and a list of JSON formatted tasks. Do not include any response outside the JSON object.  The whole of your reply must be in JSON format.  Please ask questions if you need further details or clarification.  Please carefully follow my instructions for using the JSON tasks format:  \0a \0a{ "reply" : "I have prepared your task list for today in the daily notebook" \0a  "tasks" : [ { "description": "description of a task",  \0a               "completed": true|false,  \0a               "priority": "lowest|low|normal|medium|high|highest",  \0a               "completion": YYYY-MM-DD,  \0a               "created": YYYY-MM-DD,  \0a               "scheduled": YYYY-MM-DD } ... ] \0a}    \0a \0a. The "reply" and "tasks" fields ARE BOTH MANDATORY. DO NOT put newlines in any fields. The reply field is for your text chat reply to me, including any questions, comments or suggestions etc. or any other notes you wish to make, the default reply should be "I have prepared your task list for today". The description field is mandatory and should be inferred from the tasks I describe.  The completed field should default to false unless I have told you the task is complete. The created field should be set to the current date for any new task.  The scheduled due date will default to today unless I say otherwise.  The priority will default to normal unless otherwise specified.\0a \0a'

;<  our=@p               bind:m  get-our
;<  now=@da              bind:m  get-time
=/  flag=flag.g  [our %daily]    ::: TODO - WHY, oh WHY is this hardcoded???

:: Build conversation from data
::
:: TODO conversation labels
;<  qst-vase=vase     bind:m  (build-conversation-n bird bot-id centag 'default' 3)
=/  history  !<(@t qst-vase)

;<  prev-note=tape      bind:m  (fetch-latest-todo flag.bird)

::
:: Query replicate.com
:: ...using mistral and it doesn't have separate pre-prompt, so just welding for now
=/  pre-history  (weld (trip pre-prompt) (trip history))
=/  inter-prompt  "The tasks currently in the todo list are:\0a"
=/  date-prompt  (trip (crip ;:(weld "Today Is " (scag 17 `tape`(dust:chrono:userlib (deal:chrono:userlib now))) "\0a")))
=/  summary  "My Request for you:\0a"
=/  final-warning  "REMEMBER REPLY IN THE JSON FORMAT SPECIFIED"
=/  all-prompt  (crip ;:(weld (trip pre-prompt) inter-prompt prev-note summary date-prompt (trip question)))

;<  replicate-vase=vase  bind:m  (query-replicate [bird model pre-prompt all-prompt])
=/  replicate-resp  !<([@tas @t] replicate-vase)

?:  =(-.replicate-resp %error)
  (pure:m !>([%error `reply`+.replicate-resp]))
::
:: Text response
::
=/  json-resp  (need (de:json:html +.replicate-resp))
=/  replytasks  (decode-task-response json-resp)
=/  replytext  reply.replytasks
=/  tasks  tasks.replytasks

=/  tasks-inline  `(list inline.d)`(render-tasks tasks.tasks)
=/  verse  [%inline tasks-inline]
=/  timestamp  (time (add now (unm:chrono:userlib now)))

::  TODO: The date here is not timezone localised?
=/  essay=essay.d
:*  title=(crip (weld "Daily todo - " (scag 17 `tape`(dust:chrono:userlib (deal:chrono:userlib now)))))
    image='' ::'https://wolfun.syd1.digitaloceanspaces.com/img--2023.8.24..02.17.07..6bc1.png'
    content=`(list verse.d)`~[verse]
    author=our
    sent=timestamp
  ==

:: Determine what group we're currently chatting in
=/  scry-chat=path  (stab '/gx/chat/chats/noun')
;<  chats=(map flag:c chat:c)      bind:m  (scry (map flag:c chat:c) scry-chat)
=/  group-flag  (flag:g group:perm:(~(got by chats) flag.bird)) ::find the details of the chat we're conversing in

:: Check for existence of a %daily notebook channel in our current group, shelf=(map flag diary)
=/  scry-path=path  (stab '/gx/diary/shelf/noun')
;<  shelf=shelf.d        bind:m  (scry shelf.d scry-path)  :: Shelf is all diary data for all channels
:: flatten shelf to a list ~[[flag diary] [flag diary] ...] and skim to pull out the %daily channel
:: for this group.  Due to unique naming, may actually be %daily-123, etc.
=/  shlf-list  ~(tap by shelf)
::=/  skim-list  (skim shlf-list |=([=flag.d =diary.d] &(=(group:perm:diary group-flag) =((find "daily" (trip +.flag)) [~ 0]))))  
=/  skim-list  (skim shlf-list |=([=flag.d =diary.d] &(=(group:perm:diary group-flag) =((find "daily" (trip +.flag)) [~ 0]))))  

?:  =(skim-list ~)
  :: Create a new %daily notebook channel
  =/  create=create.d
    :*  group=group-flag  :: Create notebook in the same group that we're chatting in
        name=+.flag
        title='Daily Tasks'
        description='Daily task list prepared with %mentat'
        readers=~  :: leave empty for default
        writers=~  :: leave empty for default
    ==

  ;<  ~            bind:m  (poke-our %diary [%diary-create !>([create])])
  :: Add a new note to the new notebook channel
  =/  delt-add  [%add essay]
  =/  diff-add=diff.d  [%notes timestamp delt-add]
  =/  diary-add=action.d  [flag [timestamp diff-add]]         :: for %edit, send *time, not now
  ;<  ~            bind:m  (poke-our %diary [%diary-action !>([diary-add])])
  (pure:m !>([%ok `reply`replytext replytext]))

:: Have %daily notebook channel
=/  diary-flag  -:(snag 0 skim-list)  :: flag of first item in list of matching notebooks in the group
=/  channel  (~(got by shelf) diary-flag)
=/  note-ids  ~(tap in ~(key by notes.channel))        :: a set of note ids flattened to a list
=/  day-ids  (turn note-ids |=(d=@da [-:(yell d) d]))  :: -:(yell d) gives us the day, without hours, mins, etc.
=/  today  -:(yell now)
=/  skim-for-today  (skim day-ids |=(a=[@ud @da] =(-.a today)))  :: skim list looking for an id from today

?:  =(skim-for-today ~)
  :: Add a new note to existing channel
  =/  delt-add  [%add essay]
  =/  diff-add=diff.d  [%notes timestamp delt-add]
  =/  diary-add=action.d  [diary-flag [timestamp diff-add]]         :: for %edit, send *time, not now
  ;<  ~           bind:m  (poke-our %diary [%diary-action !>([diary-add])])

  (pure:m !>([%ok `reply`replytext replytext]))
:: Edit existing note in existing channel
=/  delt-edit  [%edit essay]
=/  edit-id  +:(snag 0 skim-for-today)  :: get first ID that is today
=/  diff-edit=diff.d  [%notes edit-id delt-edit]
=/  diary-edit=action.d  [diary-flag [timestamp diff-edit]]         :: for %edit, send *time, not now
;<  ~            bind:m  (poke-our %diary [%diary-action !>([diary-edit])])
(pure:m !>([%ok `reply`replytext replytext]))
