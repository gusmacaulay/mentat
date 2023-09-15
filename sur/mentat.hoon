:: Was set up for inference/huggingface (https://huggingface.co/inference-api), 
:: but have changed to using Replicate which uses a slightly different API, 
:: this structure still works, but it will be used in a different way (id is sent in the request
:: rather than as part of the URL)

|%
+$  type  ?(%image-generation %text-generation %conversation)  ::type no longer required
+$  cen-type  ?(%chat %query %img %comment %edit %note %default %clear)
+$  view  ?(%public %private)

+$  inference-model
  $:  =view
      =type
      id=@t           :: "https://api-inference.huggingface.co/models/{id}"
      api-key=@t
      :: optional parameters??
      ::options=(unit (list [@t @t]))
      timeout=(unit [%timeout @ud])
      tokens=(unit [%tokens @ud])

  ==

:: Store conversation data in order to use conversation models
+$  participant  ?(%ai %user)
+$  conversation  (list [participant @t])
+$  conversations  (map @t conversation)
--