/-  spider, *gato, *mentat, mc=mentat-chat
/-  d=diary, g=groups, ha=hark
/+  *strandio, regex
=,  strand=strand:spider
|%
  ::
  ::  Build conversation cord for conversation models
  ::
  ++  build-conversation
    |=  [=bird =bot-id =centag =label]
    =/  m  (strand ,vase)
    ^-  form:m

    ;<  has-dialogue=update        bind:m  (scry update `path`['gx' 'mentat' 'has-dialogue' bot-id centag label 'noun' ~])
    ?.  (? +:has-dialogue)
      :: Start of dialogue
      (pure:m !>((crip ;:(weld "[INST] " (trip text.bird) " [/INST]"))))
    :: Append question to dialogue
    ;<  dlog=update          bind:m  (scry update `path`['gx' 'mentat' 'get-dialogue' bot-id centag label 'noun' ~])
    =/  dlg  (dialogue +:dlog)
  
    :: TODO:
    ::   trim dialogue to size of context window, default to entire dialogue
    ::   we'll need to scry the app for the current context-id to get the window

::    ?.  =(windows.dlg *windows.dialogue)
::      (not doing it this way now, but still need to work out context)

      :: have a context window - just fail at this stage, dev required
      :: as below, but filter by date in the subroutine
::      !!
  
    :: empty, use entire dialogue - flatten to tape
::    =/  inter-parts  `(list tape)`(turn +.dlg flatten-interaction)
    =/  inter-parts  `(list tape)`(turn dlg flatten-interaction)
    =/  inter-tape  `tape`(zing inter-parts)
    =/  inter-upd  (crip ;:(weld inter-tape "[INST] " (trip text.bird) " [/INST]"))
    (pure:m !>(inter-upd))
  ::
  ::  Convert llm-conversation structure to flat text that works for replicate.com models
  ::
  ++  flatten-interaction
    |=  [=interaction]
    ^-  tape
    ?-  participant.interaction
        %ai
      (trip text.interaction)
        %user
      ;:(weld "[INST] " (trip text.interaction) " [/INST]")
    ==
--