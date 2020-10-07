(import asyncio)

(import [gino [Gino]])

(import [config [cfg]])


(setv db (Gino))
(setv dsn (-> (get cfg "db")
              (get "dsn")))


(defclass Node [db.Model]
  (setv __tablename__ "node")
  (setv id (.Column db (.Integer db) :primary-key True))
  (setv parent-id (.Column db (.Integer db) :nullable False))
  (setv title (.Column db (.String db) :nullable False))
  (setv level (.Column db (.Integer db) :nullable False)))


(defn/a bind []
  "Connect to database."
  (await (.set_bind db dsn)))


(defn/a close []
  "Close db connection."
  (await (.close (.pop_bind db))))


(defn/a create []
  "Create all tables."
  (await (.set_bind db dsn))
  (await (.create_all db.gino))
  (await (.close (.pop_bind db))))


(defmain [&rest args]
  (print "Create all tables")
  (-> asyncio
      .get_event_loop
      (.run_until_complete (create))))
