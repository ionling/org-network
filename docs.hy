(import [sanic_openapi [doc]])


(defclass NodeResp []
  (^int id)
  (^int parent-id)
  (^str title)
  (^int level))
