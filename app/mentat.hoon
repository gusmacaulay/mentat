:: Agent is only required to store conversation state as conversation
:: models require sending the entire conversation to the AI in order for
:: it to work.
::
:: The thread will poke this app to add lines to the conversation
:: and scry this app to find the current state of the converstation.
::
/-  *gato, *mentat
/+  default-agent, dbug, mentat
|%
+$  versioned-state
  $%  state-0
  ==
+$  card  card:agent:gall
+$  state-0  [%0 =conversations]
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
++  on-init   `..on-init
++  on-save   !>(~)
:: don't worry about saving or loading state?  Happy to lose it during updates?
++  on-load   |=(vase `..on-init)
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  !!
      %add
    :: Update/create conversation
    =/  [key=@t conv=[participant @t]]  !<([@t [participant @t]] vase)
    ?:  (~(has by conversations) key)
      =/  convo  (~(got by conversations) key)                      :: get the conversation (list [@tas @t])
      =/  convo-upd  (into convo (lent convo) conv)                 :: update the conversation
      `this(conversations (~(put by conversations) key convo-upd))  :: update the conversations list
    =/  new-conv  `conversation`[conv ~]
    `this(conversations (~(put by conversations) key new-conv))     :: add a new conversation to the list
  ::
      %clear
    =/  key=@t  !<(@t vase)
    `this(conversations (~(del by conversations) key))
  ==

++  on-watch  |=(path !!)
++  on-leave  |=(path `..on-init)
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
      [%x %has @t ~]
    =/  key=@t  i.t.t.path
    ``noun+!>(`?`(~(has by conversations) key))
    ::
      [%x %conversation @t ~]
    =/  key=@t  i.t.t.path
    ``noun+!>(`conversation`(~(got by conversations) key))
  ==
++  on-agent  |=([wire sign:agent:gall] !!)
++  on-arvo   |=([wire sign-arvo] !!)
++  on-fail   |=([term tang] `..on-init)
--