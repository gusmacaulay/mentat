|%
+$  priority  ?(%lowest %low %normal %medium %high %highest)
+$  task
  $:  description=@t
      priority=@t ::use tape for now
      completed=?
      created=@t
      ::due=@t :: obsidian calls this scheduled but seems to confuse llm
      ::completion=@t
  ==
      
+$  task-response
  $:  reply=cord
      tasks=(list task)
  ==

--