(import asyncio)
(import re)
(import subprocess)

(import [collections [namedtuple]])
(import [pathlib [Path]])

(import [config [cfg]])
(import [models [bind close Node]])


(setv Heading (namedtuple "Heading" ["title" "level"]))
(setv HeadingRecord (namedtuple "HeadingRecord" ["id" "parent_id" "title" "level"]))

(setv rg-cmd ["rg" "-n" "^\*+ "])


(defn get-headings-from-file [file-path]
  (setv path (.expanduser (Path file-path)))
  (setv cmd (list rg-cmd))
  (.append cmd path)
  (setv cp (.run subprocess cmd :capture-output True))
  (for [line (-> cp.stdout
                 .decode
                 .splitlines)]
    ;; 10865:*** Browser
    (setv pattern r"(\d+):(\*+) (.+)")
    (setv groups (.groups
                   (.match re pattern line)))
    (yield (Heading (get groups 2) (len (get groups 1))))))


(defn get-heading-records [file-path]
  (setv last-id 1)
  (setv stem (. (Path file-path) stem))
  (setv parent-records [(HeadingRecord last-id 0 stem 0)])
  (yield (get parent-records -1))

  (for [heading (get-headings-from-file file-path)]
    (setv parent-records
          (->> parent-records
               (filter (fn [record]
                         (< record.level heading.level)))
               (list)))
    (setv last-id (inc last-id))
    (setv record
          (HeadingRecord last-id
                         (. (get parent-records -1) id)
                         heading.title
                         heading.level))
    (.append parent-records record)
    (yield record)))


(defn/a refresh []
  (setv org-file (-> (get cfg "org")
                     (get "file")))
  (await (bind))
  (await (.status Node.delete.gino))
  (await (as-> (get cfg "org") it
               (get it "file")
               (get-heading-records it)
               (map (fn [r]
                      {
                       "id" r.id
                       "parent_id" r.parent-id
                       "title" r.title
                       "level" r.level
                       })
                    it)
               (list it)
               (.gino.all (.insert Node) it)))
  (await (close)))


(defmain [&rest args]
  (.run_until_complete
    (.get_event_loop asyncio)
    (refresh)))
