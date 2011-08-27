Jm doc "Various bits of code to handle data storage."

proc APP.READY {} {
  file mkdir [path ""]
  mk file open db [path db]
  mk layout db.version v
  mk set db.version!0 v 1
  PeriodicSave
}

proc PeriodicSave {} {
  # trigger once a minute, ON the minute
  set remain [- 60000 [% [clock millis] 60000]]
  after $remain [namespace which PeriodicSave]
  mk file commit db
  app hook STORAGE.PERIODIC
}

proc path {name} {
  file join ./storage $name
}

# proc row {view index} {
#   return db.view!$index
# }
