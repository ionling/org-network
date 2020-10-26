(import asyncio)

(import docs)
(import models)

(import [humps [camelize]])
(import [sanic [Sanic Blueprint]])
(import [sanic.response [json]])
(import [sanic_cors [CORS]])
(import [sanic-openapi [doc swagger_blueprint]])

(import [config [cfg]])
(import [models [bind close Node]])


(setv app (Sanic "org-network"))
(CORS app :resources {r"/api/*" {"origins" "*"}})

(defn to-resp [data]
  (cond [(isinstance data dict) (camelize data)]
        [(isinstance data (. models db Model))
         (to-resp (.to-dict data))]))


#@((.listener app "before_server_start")
    (defn/a connect-db [app loop]
      (await (bind))))


#@((.listener app "after_server_stop")
    (defn/a close-db [app loop]
      (await (close))))


#@((.route app "/hello")
    (defn/a hello [req]
      (json {"hello" "world"})))


(setv node-bp (Blueprint "node" :url-prefix "/nodes"))
(setv api (.group Blueprint node-bp :url-prefix "api"))


#@((.route node-bp "/")
    (.produces doc (.List doc (. docs NodeResp)) :content-type "application/json")
   (defn/a index [req]
     (setv q (.get req.args "q"))
     (setv query
           (lif-not q
                    Node.query
                    (.where Node.query
                            (.like Node.title f"%{q}%"))))
     (->> query.gino
          .all
          await
          (map (fn [node] (to-resp node)))
          list
          json)))


(.static app "" "static/index.html")
(.static app "/static" "static")

(.blueprint app api)
(.blueprint app swagger_blueprint)


(defmain [&rest args]
  (setv c (get cfg "server"))
  (.run app :host (get c "host") :port (get c "port") :debug (get c "debug")))
