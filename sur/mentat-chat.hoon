:: Store conversation data in order to use conversation models
/-  mnt=mentat
|%

+$  llm-chat
  $:  text=@t
      timestamp=@da
  ==

+$  llm-chat-key  @t
+$  llm-conversation  (list [participant.mnt llm-chat])
+$  llm-conversations  (map llm-chat-key llm-conversation)
--