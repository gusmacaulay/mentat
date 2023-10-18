/-  sur=mentat

|%
++  enjs
::  =,  enjs:format  :: it's a bit clearer when we make this explicit
  |%
  ++  update
    |=  upd=update.sur  
    ^-  json
    %+  frond:enjs:format  -.upd
    ?-  -.upd
        %has-dialogue  (bool +.upd)
        %get-dialogue  (dialogue +.upd)
        %has-window  (bool +.upd)
        %get-window  (window +.upd)
        %has-context  (bool +.upd)
        %get-context  (context +.upd)
        %get-compendium  (compendium +.upd)
        %get-conversation  (conversation +.upd)
        %get-models  (models +.upd)
        %get-model  (model +.upd)
        %get-bots-set  (bots-set +.upd)
    ==
  ::
  ++  bots-set
    |=  bots=(set [bot-id.sur status.sur])
    ^-  json
    ?:  =(bots *(set [bot-id.sur status.sur]))
      ~
    =/  bots-list  ~(tap in bots)
     =/  upd-bots-list  (turn bots-list bot-status)
     (pairs:enjs:format upd-bots-list)               :: return as objects
  ::
  ++  bot-status
    |=  [=bot-id.sur =status.sur]
    [bot-id s+status]
  ::
  ++  compendium
    |=  comp=compendium.sur
    ^-  json
    ?:  =(comp *compendium.sur)
      ~
    =/  comp-list  ~(tap by comp)
    =/  upd-comp-list  (turn comp-list compendium-content)
    (pairs:enjs:format upd-comp-list)
  ::
  ++  compendium-content
    |=  [ctg=centag.sur cnv=conversation.sur]
    ^-  [@tas json]
    [ctg (conversation cnv)]
  ::
  ++  conversation
    |=  conv=conversation.sur
    ^-  json
    ?:  =(conv *conversation.sur)
      ~
    =/  conv-list  ~(tap by conv)
    =/  upd-conv-list  (turn conv-list conversation-content)
    (pairs:enjs:format upd-conv-list)
  ::
  ++  conversation-content
    |=  [=label.sur dlg=dialogue.sur]
    ^-  [@t json]
    [label (dialogue dlg)]
  ::
  ++  models
    |=  mdls=models.sur
    ^-  json

    ?:  =(mdls *models.sur)
      ~
    =/  mdls-list  ~(tap by mdls)
    =/  upd-list  (turn mdls-list models-content)
    (pairs:enjs:format upd-list)
  ::
  ++  models-content
    |=  [ctg=centag.sur mdl=model-set.sur]
    ^-  [@tas json]
    [ctg (model-set mdl)]
  ::
  ++  model-set
    |=  mdlset=model-set.sur
    ^-  json
 
    ?:  =(mdlset *model-set.sur)
      ~
    =/  mdlset-list  ~(tap by mdlset)
    =/  upd-list  (turn mdlset-list model-set-content)
    (pairs:enjs:format upd-list)
  ::
  ++  model-set-content 
    |=  [lbl=label.sur mdl=inference-model.sur]
    ^-  [@t json]
    [lbl (model mdl)]
  ::
  ++  model
    |=  modl=inference-model.sur
    ^-  json
    
    =/  timeout  (numb:enjs:format (fall timeout.modl 0))  :: default to 0
    =/  tokens  (numb:enjs:format (fall tokens.modl 0))  :: default to 0

    %-  pairs:enjs:format
    :~
      ['view' s+view.modl]
      ['model-id' s+model-id.modl]
      ['api-key' s+api-key.modl]
      ['timeout' timeout]
      ['tokens' tokens]
    ==
  ::
  ++  window
    |=  =window.sur
    ^-  json
    %-  pairs:enjs:format
    :~
      ['begin' s+(crip (dust:chrono:userlib (deal:chrono:userlib begin.window)))]  :: UTC strings
      ['end' s+(crip (dust:chrono:userlib (deal:chrono:userlib end.window)))]
    ==
  ::
  ++  context
    |=  cont=context.sur
    ^-  json
    ?:  =(cont *context.sur)
      ~
    =/  cont-list  ~(tap by cont)  
    a+(turn cont-list context-content)
  ::
  ++  context-content
    |=  [[=centag.sur =label.sur] wind=window.sur]
    ^-  json
    %-  pairs:enjs:format
    :~
      ['centag' s+centag]
      ['label' s+label]
      ['window' (window wind)]
    ==
  ::
  ++  bool
    |=  boolean=?
    ^-  json
    ?:  boolean
      b+&
    b+|
  ::
  ++  dialogue
    |=  dial=dialogue.sur
    ^-  json
    ?:  =(dial *dialogue.sur)
      ~
    a+(turn dial interaction)
  ::
  ++  interaction
    |=  intr=interaction.sur
    ^-  json
    %-  pairs:enjs:format
    :~
      ['participant' (participant participant.intr)]
      ['text' s+text.intr]
      ['date' s+(crip (dust:chrono:userlib (deal:chrono:userlib date.intr)))]  ::date as UTC string
      ['model-id' s+model-id.intr]
    ==
  ::
  ++  participant
    |=  part=participant.sur
    ?-  part
      %ai  s+'ai'
      %user  s+'user'
    ==
  --
++  dejs
  =,  dejs:format
  |%
  ++  action
    |=  jsn=json
    ^-  action.sur

    (action.sur (to-action jsn))
  ::
  ++  to-action
    %-  of  
    :~  add-interaction+add-interaction
        delete-dialogue+delete-dialogue
        add-model+add-model
        delete-model+delete-model
        start-bot+start
        stop-bot+stop
    ==
  ::
  ++  start
    %-  ot
    :~  bot-id+so
    ==
  ::
  ++  stop
    %-  ot
    :~  bot-id+so
    ==
  ::
  ++  delete-dialogue
    %-  ot
    :~  bot-id+so
        centag+so
        label+so
    ==
  ::
  ++  delete-model
    %-  ot
    :~  bot-id+so
        centag+so
        label+so
    ==
  ::
++  add-model
    %-  ot
    :~
      bot-id+so
      centag+so
      label+so
      inference-model+inference-model
    ==
  ::
  ++  inference-model
    %-  ot
    :~
      view+so
      model-id+so
      api-key+so
      timeout+ni:dejs-soft:format  :: decode as unit - currently coming through as a string, should be a number
      tokens+ni:dejs-soft:format   :: decode as unit
    ==
  ::
  ++  add-interaction
    %-  ot
    :~
      bot-id+so
      centag+so
      interaction+interaction
      label+so
    ==
  ::
  ++  interaction
    %-  ot
    :~
      participant+so
      text+so
      date+du
      model+so
    ==
  ::    
  -- 
--