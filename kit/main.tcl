# Main JeeMon startup logic. Each new launch starts here.

namespace eval Jm {
  variable root_dir [file dir [dict get [info frame 0] file]]
  variable rigs_loaded	;# array of rigs currelty loaded
  variable rigs_extra		;# array of files skipped by autoloader

  namespace eval initial {
    # Collect info about environment before anything is defined
    variable vars [info vars ::*] 
    variable commands [info commands ::*]
    variable namespaces [namespace children ::]
  }  

  proc loadRig {path {ns ""}} {
    # Load or re-load a rig from file.
    # path: path of file to load
    # ns: namespace to load the file/rig into
    # Returns the name of the loaded rig.
    variable rigs_loaded
    set name [file root [file tail $path]]
    set newns ::${ns}$name
    #TODO change ::${ns}$name to ${ns}::$name - everywhere!
    namespace eval $newns {
      namespace export -clear {[a-z]*}
      # namespace ensemble create
      namespace ensemble create -unknown {apply {{ns t args} {
        upvar #0 auto_index([string range $ns 2 end]::$t) cmd
        if {[info exists cmd]} {
          uplevel #0 $cmd
        }
        return
      }}}
    }
    # set up the namespace path to chain to each of the parent namespaces
    set nspath {}
    for {set p $newns} {[set q [namespace parent $p]] ne "::"} {set p $q} {
      lappend nspath $q
    }
    namespace inscope $newns namespace path $nspath  
    # now load the actual code from file and remember when it was last loaded
    set rigs_loaded($newns) [list $path [file mtime $path]]
    namespace inscope $newns source $path
    return $name
  }
  
  proc autoLoader {path {match *} {ns ""}} {
    # Scan a directory tree and set up autmoatic loading of rigs on first use.
    # path: path to directory tree where rigs files are found
    # match: glob pattern to match file names
    # ns: namespace to load the file/rig into
    if {[file isfile $path] && [file ext $path] eq ".zip"} {
      package require vfs::zip
      vfs::zip::Mount $path $path
    }
    if {[file isfile $path] && [file ext $path] eq ".kit"} {
      package require vfs::mk4
      vfs::mk4::Mount $path $path -readonly
    }
    if {[file isdir $path]} {
      variable rigs_extra
      set path [file normalize $path]
      set unused {}
      foreach tail [glob -nocomplain -dir $path -tails $match] {
        set name [file root $tail]
        # set name [regsub -- {-[^-]*$} $name {}]
        set full [file join $path $tail]
        if {[file isfile $full] && [file ext $tail] eq ".tcl"} {
          set prefix $ns
          if {[string match *::${name}:: ::$prefix]} {
            set prefix [string range $prefix 0 end-[string length ${name}::]]
          }
          set ::auto_index(${prefix}$name) [list ::Jm::loadRig $full $prefix]
        } elseif {[file exists [file join $full $name.tcl]]} {
					#TODO rigs_extra is not very useful this way, it forgets the top level
          set rigs_extra(::${ns}${name}) [autoLoader $full * ${ns}${name}::]
        } else {
          lappend unused $tail
        }
      }
      return $unused
    }
  }
  
  proc setupRigPaths {} {
    # Initialize the default paths where rigs will be loaded from.
    variable root_dir
    
    # set up a number of directories for auto-loading, if they exist
    set dirs {rigs1 rigs2 rigs3}
    # the default directory set can be changed with the JEEREV_RIG_DIRS env var
    catch { set dirs $::env(JEEREV_RIG_DIRS) }
    foreach d $dirs {
      autoLoader [file join $root_dir $d]
    }

    # if ./app.tcl exists, use it before falling back to above version
    autoLoader . app.tcl

    # need to deal with two cases: unwrapped "kit" and wrapped "JeeMon_kit"
    set rigsBase [file join [file dir $root_dir] JeeMon]

    if {[file isdir $rigsBase-rigs]} {
      autoLoader $rigsBase-rigs
    } elseif {[file isfile $rigsBase-rigs.zip]} {
      autoLoader $rigsBase-rigs.zip
    } elseif {[file isfile $rigsBase-rigs.kit]} {
      autoLoader $rigsBase-rigs.kit
    }

    if {[lindex $::argv 0] ne ""} {
      autoLoader $rigsBase-[lindex $::argv 0]
      autoLoader [lindex $::argv 0]
    }
  }
}

# Jm is not an ensemble yet, so we still need to use the Jm::* notation
# this can (and should) be avoided, once rig paths have been set up

Jm::setupRigPaths

# The following command is a rig call, i.e. the "Jm" command is located and
# loaded from file according to the rig search path set up so far. At this
# point the ::Jm namespace already exists, but once the rig is loaded, that
# namespace will become an ensemble. By having a custom "Jm.tcl" take over,
# the rest of this startup process can be completely changed and customized.
# Note that the returned list is expanded and evaluated, i.e. the main app.

{*}[Jm launch]
