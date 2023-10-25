|%

:: A bot can be defined as having a compendium (all intereractions) and a context (all windows)
:: A ship can run many bots.  Each bot is defined by a bot-id (which is the command that identifies
:: it in %gato e.g. /mentat)
+$  bot-id  @t

+$  bot
  $:  =contexts
      =compendium
      =models
      =status
  ==

+$  status  
  $~  %stopped
  ?(%running %stopped)

+$  bots  (map bot-id bot)      :: The sum of all bots

::
:: Model
::
+$  centag  ?(%chat %query %img %comment %edit %note %default %clear %remind)  :: like a hashtag, but for Urbit
+$  view  ?(%public %private)
+$  participant  ?(%ai %user)

+$  model-id  @t

+$  inference-model
  $:  =view
      =model-id
      api-key=@t
      timeout=(unit @ud)
      tokens=(unit @ud)
      :: To implement once no longer putting this in via the back end.
      :: pre-prompt  @t
      :: any other useful fields.
  ==

:: Keep track of models being used
+$  model-set  (map label inference-model)
+$  models  (map centag model-set)
  
::
:: State for all interactions with LLM
::
+$  label  @t

+$  interaction
  $:  =participant
      text=@t
      date=@da
      =model-id
  ==

+$  dialogue  (list interaction)

+$  conversation
  $~  *(map label dialogue)
  (map label dialogue)

+$  compendium  (map centag conversation)


::
:: Context windows
::
+$  context-id  @t

+$  contexts  (map context-id context)       :: A context for each context-id

+$  context  (map [centag label] window)     :: A start and end time for each [centag label] combination forms a context

+$  window
  $~  [*@da *@da]
  $:  begin=@da
      end=@da
  ==

::
:: Actions & updates
::

+$  update
  $%
    [%has-dialogue ?]
    [%get-dialogue =dialogue]
    [%has-window ?]
    [%get-window =window]
    [%has-context ?]
    [%get-context =context]
    [%get-compendium =compendium]
    [%get-conversation =conversation]
    [%get-model =inference-model]
    [%get-models =models]
    [%get-bots-set (set [bot-id status])]
  ==

+$  action
  $%
    [%start-bot =bot-id]  :: start and stop gato thread
    [%stop-bot =bot-id]
    [%add-interaction =bot-id =centag =interaction =label]
    [%delete-dialogue =bot-id =centag =label]  ::TODO
    [%delete-conversation]  ::TODO
    [%delete-compendium]  ::TODO
    [%delete-context]  ::TODO
    [%add-context]  ::TODO
    [%update-context]  ::TODO
    [%delete-context]  ::TODO
    [%add-window]  ::TODO
    [%delete-window]  ::TODO
    [%add-model =bot-id =centag =label =inference-model]
    [%delete-model =bot-id =centag =label]
  ==

--