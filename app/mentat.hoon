::TODO:
:: This app should interface with a web UI and with %gato so that
:: dojo setup for %gato isn't required.
:: Pokes from the UI should be validated, and the data used to poke
:: %gato to run a new %mentat thread.
::
/-  *gato, *mentat, *mentat-chat
/+  default-agent, dbug, mentat, api-key
|%
+$  versioned-state
  $%  state-0
  ==
+$  card  card:agent:gall
+$  state-0  [%0 =bots]
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
::++  on-init  on-init:def
++  on-init
  :: setup default models
  ~&  "on-init - installing default mentat bot..."

  =/  img-model=[label inference-model]
    :-  'default'
    :*  %private
        'ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4'  :: Stability-ai
        api-key=default-api-key.api-key
        timeout=`360
        tokens=`500
    ==
  =/  img-set  (~(put by *model-set) img-model)

  =/  query-model=[label inference-model]
    :-  'default'
    :*  %private
        '02e509c789964a7ea8736978a43525956ef40397be9033abf9fd2badfe68c9e3'  :: LLAMA-2-70b
        api-key=default-api-key.api-key
        timeout=`360
        tokens=`500
    ==
  =/  query-set  (~(put by *model-set) query-model)

  =/  chat-model=[label inference-model]
    :-  'default'
    :*  %private
        'f4e2de70d66816a838a89eeeb621910adffb0dd0baba3976c96980970978018d'  :: LLAMA-2-13b
        api-key=default-api-key.api-key
        timeout=`360
        tokens=`500
    ==
  =/  chat-set  (~(put by *model-set) chat-model)

  =/  todo-model=[label inference-model]
    :-  'default'
    :*  %private
        '83b6a56e7c828e667f21fd596c338fd4f0039b46bcfa18d973e8e70e455fda70'  :: Mistral-7b-instruct-v0.1
        api-key=default-api-key.api-key
        timeout=`360
        tokens=`500
    ==
  =/  todo-set  (~(put by *model-set) todo-model)

  =/  remind-model=[label inference-model]
    :-  'default'
    :*  %private
        'f4e2de70d66816a838a89eeeb621910adffb0dd0baba3976c96980970978018d'  :: LLAMA-2-13b-chat
        api-key=default-api-key.api-key
        timeout=`360
        tokens=`500
    ==
  =/  remind-set  (~(put by *model-set) todo-model)


  =/  default-models  (models (malt (limo ~[[%img img-set] [%query query-set] [%chat chat-set] [%todo todo-set] [%remind remind-set]])))
  =/  default-bot  `bot`[*contexts *compendium default-models %stopped]
  `this(bots (~(put by bots) 'mentat' default-bot))
::
++  on-save   !>(state)
::++  on-load  on-load:def
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  `this(state !<(state-0 old))
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
      %mentat-action
    =/  action  !<(action vase)

    ?+  -.action  !!
        %add-interaction
    :: Update/create dialogue
      =/  [=bot-id =centag =interaction =label]  +.action

      ?.  (~(has by bots) bot-id)
        :: No bot in bots
        =/  cnv  (~(put by *conversation) label (snoc *dialogue interaction))
        =/  cmp  (~(put by *compendium) centag cnv)
        `this(bots (~(put by bots) bot-id [*contexts cmp *models *status]))
      ::
      =/  bot  (~(got by bots) bot-id)
      ?.  (~(has by compendium.bot) centag)
        :: No conversation in the compendium
        =/  cnv  (~(put by *conversation) label (snoc *dialogue interaction))
        =/  cmp  (~(put by compendium.bot) centag cnv)
        `this(bots (~(put by bots) bot-id [contexts.bot cmp models.bot status.bot]))
      ::
      =/  conv  (~(got by compendium.bot) centag)
      ?.  (~(has by conv) label)
        :: No dialogue in the conversation
        =/  cnv  (~(put by conv) label (snoc *dialogue interaction))
        =/  cmp  (~(put by compendium.bot) centag cnv)
        `this(bots (~(put by bots) bot-id [contexts.bot cmp models.bot status.bot]))
      ::
      :: Update existing dialogue
      =/  dlog  (~(got by conv) label)
      =/  updt  (~(put by compendium.bot) centag (~(put by conv) label (snoc dlog interaction)))   
      `this(bots (~(put by bots) bot-id [contexts.bot updt models.bot status.bot]))
    ::
::      %delete-dialogue
::    =/  [=bot-id =centag =label]  +.action
::    `this
::    ::
::      %delete-conversation
::    `this
::    ::
::      %delete-compendium
::    `this
::    ::
::      %delete-context
::    `this
::    ::
::      %add-context
::    `this
::    ::
::      %update-context
::    `this
::    ::
::      %delete-context
::    `this
::    ::
::      %add-window
::    `this
::    ::
::      %delete-window
::    `this
    ::
      %add-model
    =/  [=bot-id =centag =label =inference-model]  +.action

    ?.  (~(has by bots) bot-id)
      :: Add model to empty bot
      =/  new-models  (~(put by *models) centag (~(put by *model-set) label inference-model))
      `this(bots (~(put by bots) bot-id [*contexts *compendium new-models *status]))
    :: Update existing bot
    =/  bot  (~(got by bots) bot-id)
    =/  mod-set  (~(get by models.bot) centag)
    ?:  =(mod-set ~)
      :: Update existing model with no model-set
      =/  models  (~(put by models.bot) centag (~(put by *model-set) label inference-model))
      `this(bots (~(put by bots) bot-id [contexts.bot compendium.bot models status.bot]))
    :: Update existing model
    =/  mod-upd  (~(put by models.bot) centag (~(put by (need mod-set)) label inference-model))
    `this(bots (~(put by bots) bot-id [contexts.bot compendium.bot mod-upd status.bot]))
    ::
      %delete-model
    =/  [=bot-id =centag =label]  +.action
    
    =/  bot  (~(got by bots) bot-id)
  
    =/  upd-mod-set  (~(del by (~(got by models.bot) centag)) label)
    =/  upd-models  (~(put by models.bot) centag upd-mod-set)
  
    `this(bots (~(put by bots) bot-id [contexts.bot compendium.bot upd-models status.bot]))
    ::
      %start-bot
    =/  =bot-id  +.action
    =/  bot  (~(got by bots) bot-id)
    
    :_  this
    :~  [%pass /bot-start/[bot-id] %agent [our.bowl %gato] %poke %add !>([bot-id [%mentat %mentat] !>(bot-id)])]
    ==
    ::
      %stop-bot
    =/  =bot-id  +.action
    =/  bot  (~(got by bots) bot-id)
    :_  this
    :~  [%pass /bot-stop/[bot-id] %agent [our.bowl %gato] %poke %remove !>(bot-id)]
    ==
  ==
==
::
++  on-watch  |=(path !!)
::
++  on-leave  |=(path `..on-init)
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
    :: 
      [%x %has-dialogue bot-id centag label ~]
    =/  [=bot-id =centag =label]  [i.t.t.path i.t.t.t.path i.t.t.t.t.path]

    ?.  (~(has by bots) bot-id)
      ``mentat-update+!>([%has-dialogue %.n])
    ?.  (~(has by compendium:(~(got by bots) bot-id)) centag)
      ``mentat-update+!>([%has-dialogue %.n])
    ?.  (~(has by (~(got by compendium:(~(got by bots) bot-id)) centag)) label)
      ``mentat-update+!>([%has-dialogue %.n])
    ``mentat-update+!>([%has-dialogue %.y])
    ::
      [%x %get-dialogue bot-id centag label ~]
    =/  [=bot-id =centag =label]  [i.t.t.path i.t.t.t.path i.t.t.t.t.path]

    ?:  =(bots ~)
      ``mentat-update+!>([%get-dialogue *dialogue])

    =/  dlog  (need (~(get by (need (~(get by compendium:(need (~(get by bots) bot-id))) centag))) label))
    :: TODO - dlog fails when empty, rather than producing ~
    ?:  =(dlog ~)
      ``mentat-update+!>([%get-dialogue *dialogue])
    ``mentat-update+!>([%get-dialogue `dialogue`dlog])
    ::
      [%x %has-context bot-id context-id ~]
    =/  [=bot-id =context-id]  [i.t.t.path i.t.t.t.path]

    ?:  =(bots ~)
      ``noun+!>(`?`%.n)
    =/  contexts  contexts:(~(got by bots) bot-id)
    ``mentat-update+!>([%has-context (~(has by contexts:(~(got by bots) bot-id)) context-id)])
    ::
      [%x %get-context bot-id context-id ~]
    =/  [=bot-id =context-id]  [i.t.t.path i.t.t.t.path]

    ?:  =(bots ~)
      ``mentat-update+!>([%get-context *context])

    =/  contx  (need (~(get by contexts:(need (~(get by bots) bot-id))) context-id))
    ?:  =(contx ~)
      ``mentat-update+!>([%get-context *context])
    ``mentat-update+!>([%get-context contx])
    ::
      [%x %has-window bot-id context-id centag label ~]
    =/  [=bot-id =context-id =centag =label]  [i.t.t.path i.t.t.t.path i.t.t.t.t.path i.t.t.t.t.t.path]
    ``mentat-update+!>([%has-window (~(has by (need (~(get by contexts:(need (~(get by bots) bot-id))) context-id))) [centag label])])
    ::
      [%x %get-window bot-id context-id centag label ~]
    =/  [=bot-id =context-id =centag =label]  [i.t.t.path i.t.t.t.path i.t.t.t.t.path i.t.t.t.t.t.path]

    ?:  =(bots ~)
      ``mentat-update+!>([%get-window *window])

    =/  wind  (need (~(get by (need (~(get by contexts:(need (~(get by bots) bot-id))) context-id))) [centag label]))
    ?:  =(wind ~)
      ``mentat-update+!>([%get-window *window])
    ``mentat-update+!>([%get-window wind])
    ::
      [%x %get-models bot-id ~]
    =/  [=bot-id]  [i.t.t.path]
    
    ?:  =(bots ~)
      ``mentat-update+!>([%get-models *(map centag (map label inference-model))])
    ``mentat-update+!>([%get-models models:(~(got by bots) bot-id)])
    ::
      [%x %get-model bot-id centag label ~]
    =/  [=bot-id =centag =label]  [i.t.t.path i.t.t.t.path i.t.t.t.t.path]
    
    ?:  =(bots ~)
      ``mentat-update+!>([%get-model *inference-model])
    ``mentat-update+!>([%get-model (~(got by (~(got by models:(~(got by bots) bot-id)) centag)) label)])
    ::
      [%x %get-compendium bot-id ~]
    =/  [=bot-id]  [i.t.t.path]
    
    ?:  =(bots ~)
      ``mentat-update+!>([%get-compendium *(map [centag label] inference-model)])
    ``mentat-update+!>([%get-compendium compendium:(~(got by bots) bot-id)])
    ::
      [%x %get-conversation bot-id centag label ~]
    =/  [=bot-id =centag =label]  [i.t.t.path i.t.t.t.path i.t.t.t.t.path]

    ?:  =(bots ~)
      ``mentat-update+!>([%get-conversation *conversation])

    ``mentat-update+!>([%get-conversation (~(got by (~(got by compendium:(~(got by bots) bot-id)) centag)) label)])
    ::
    ::  Return set of [bot-id status]
      [%x %get-bots-set ~]
    ?:  =(bots ~)
      ``mentat-update+!>([%get-bots-set *(set [bot-id status])])
    =/  bots-red  (~(run by bots) |=(=bot status.bot))   :: map of [bot-id status]
    =/  bots-set  (silt ~(tap by bots-red))              :: set of [bot-id status]
    ``mentat-update+!>([%get-bots-set bots-set])
    ::
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  
  ?+  wire  (on-agent:def wire sign)
      [%bot-start @ ~]
     =/  bid  (bot-id i.t.wire)

    ?+  -.sign  (on-agent:def wire sign)
        %poke-ack
      ?~  p.sign
        =/  bot  (~(got by bots) bid)
        `this(bots (~(put by bots) bid [contexts.bot compendium.bot models.bot %running]))
      `this
    ==
    ::
      [%bot-stop @ ~]
     =/  bid  (bot-id i.t.wire)

    ?+  -.sign  (on-agent:def wire sign)
        %poke-ack
      ?~  p.sign
        =/  bot  (~(got by bots) bid)
        `this(bots (~(put by bots) bid [contexts.bot compendium.bot models.bot %stopped]))
      `this
    ==
  ==
::
++  on-arvo   |=([wire sign-arvo] !!)
::
++  on-fail   |=([term tang] `..on-init)
--
