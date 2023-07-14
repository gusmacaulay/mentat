|%
:: model details, set up specifically to use hugging face inference models
:: https://huggingface.co/inference-api
+$  type  ?(%image-generation %text-generation %conversation)

+$  inference-model
  $:  =type
      id=@t           :: "https://api-inference.huggingface.co/models/{id}"
      api-key=@t
      ::options=(list [@t @t])
  ==
--
