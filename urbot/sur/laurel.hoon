|%
:: model details, set up specifically to use hugging face inference models
:: https://huggingface.co/inference-api
+$  type  ?(%image-generation %text-generation %conversation)
+$  view  ?(%public %private)

:: Was set up for inference/huggingface, but changing to replicate
:: which uses a slightly different API, this structure should still
:: work, but it will be used in a different way (id is sent in the request
:: rather than as part of the URL)

+$  inference-model
  $:  =view
      =type
      id=@t           :: "https://api-inference.huggingface.co/models/{id}"
      api-key=@t
      ::options=(list [@t @t])
      :: optional options??
      ::options=(unit (list [@t @t]))
      timeout=(unit [%timeout @ud])
      tokens=(unit [%tokens @ud])

  ==
--
