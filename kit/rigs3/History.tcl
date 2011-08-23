Jm doc "Manage historical data storage"

variable defaults { step 30s range 3d type n }

variable sizes {
  c 1 t 2 n 4 m 8 f 4 d 8
}

variable nulls {
  c -128 t -32768 n -2147483648 m -9223372036854775808 f NaN d NaN
}

proc APP.READY {} {
  State subscribe * [namespace which StateChanged]
}

proc StateChanged {name} {
  variable sizes
  # puts <$args>
  dict extract [State getInfo $name] v t
  set path x-hist/[string map {: /} $name] ;#FIXME
  if {![file exists $path.txt]} {
    file mkdir [file dir $path]
    variable defaults
    Ju writeFile $path.txt $defaults -newline
  }
  dict extract [Ju readFile $path.txt] step range type
  set step [Ju asSeconds $step]
  set range [Ju asSeconds $range]
  set count [/ $range $step]
  set width [dict get $sizes $type]
  if {![file exists $path]} {
    variable nulls
    set missing [binary format $type [dict get $nulls $type]]
    Ju writeFile $path [string repeat $missing $count] -binary
  }
}
