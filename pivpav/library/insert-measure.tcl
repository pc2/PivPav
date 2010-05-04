#!/opt/pc2_amd64/FPGA/Xilinx/11.1/ISE/bin/lin64/xtclsh

set PATH_LEVEL ".."

if {  [ namespace exists "::INSERT_DB" ] } { return }
namespace eval ::INSERT_DB ""


# ===================================================================== #

proc ::INSERT_DB::usage {} {
  puts "[info script] <-debug> <-db fname> fname " 
  puts "\t fname                 : read all data from file"
  puts "\t override values specified read from fname file:"
  puts "\t -db     fname         : database file name"
  puts "\t -no_files             : do not store files in db"
  puts "\t -debug                : enable debugging mode"
  puts ""
}

# ===================================================================== #
proc ::INSERT_DB::insert_file_or_dir { var_name } {
  dputs "* Inserting file to db"
  if { [ info exists $var_name ] } {
    upvar $var_name name
  } else {
    dputs "  - missing file"
    return 0 
  }
  dputs "  $name"
  namespace eval FILE_ATTR ""

  set FILE_ATTR::f_is_dir 0
  set FILE_ATTR::f_is_file 0
  set FILE_ATTR::f_is_tgz  ""

  # is it dir or file?
  if {[ file isdirectory $name ] } { set FILE_ATTR::f_is_dir 1 } else { set FILE_ATTR::f_is_file 1 }

  # compress files
  set bin_data  [ ::UTILS::compress_tgz "$name" ]
  set FILE_ATTR::f_is_tgz 1

  # build list of suffix we are interested
  set suffixes ""
  foreach v [ info procs ::PARSER::F_HAS_* ]  {
    if { [ regexp {.*_(.*)} $v {} suffix ] }  {
      lappend suffixes $suffix
    }
  }

  # check which files are there
  # compare suffixes with file_or_directory
  # results store in FILE_ATTR namespace
  foreach s $suffixes {
    set s [ string tolower $s ]
    set wc [ exec find $name -type f -name "\*.$s" | wc -l ]
    if {$wc > 0 } {
      dputs "  $s $wc"
      set FILE_ATTR::f_has_$s $wc 
    } 
  }

  # check for logfiles
  if { $FILE_ATTR::f_is_dir == 1 } {
    if {[ exec find $name -type f -name "${::CONFIG::gen_cg_stdout_dup_file}" | wc -l ]  } {
      set FILE_ATTR::f_is_stdout 1
    }
    if {[ exec find $name -type f -name "${::CONFIG::gen_cg_stderr_dup_file}" | wc -l ]  } {
      set FILE_ATTR::f_is_stderr 1
    }
  }

  # dexec foreach i [ lsort [ info vars FILE_ATTR::* ] ] { puts "$i [ set $i ]" }

  # build sql query
  set cols [ regsub -all {::INSERT_DB::FILE_ATTR::} [ lsort [ info vars ::INSERT_DB::FILE_ATTR::* ] ] {} ]
  set cols [ join $cols ", " ]
  set vals ""
  foreach v [ lsort [ info vars ::INSERT_DB::FILE_ATTR::* ] ] {
    lappend vals  [ set $v ]
  }
  set vals [ join $vals ", " ]
  set sql "INSERT INTO file(f_store, $cols) VALUES(@bin_data, $vals);"
  dputs "  $sql"

  db eval $sql
  set f_key [ db eval { SELECT last_insert_rowid() } ]
  dputs "  $f_key"

  namespace delete ::INSERT_DB::FILE_ATTR
  return $f_key
}

# ===================================================================== #
proc ::INSERT_DB::select_or_insert_table { table_name preffix  } {
  dputs "* Insert to $table_name table"
  set vars ""
  foreach p $preffix {
    set vars " $vars [  info vars ::DATA::${p} ] "
  }
  if {[ regexp {^\s*$}  $vars ]} {
    dputs "   There are no data for table: $table_name"
    return 0 
  }

  set cols [ lsort [ regsub -all {::DATA::} $vars {} ] ]
  set vals ""
  set pairs ""
  foreach v $cols {
    set v_name ::DATA::$v
    set val [ join [ set $v_name ] ]
    lappend vals '$val' 
    lappend pairs "${v}=\"$val\""
  }
  set cols [ join $cols ", " ]
  set vals [ join $vals ", " ]
  # dputs "  cols: $cols"
  # dputs "  vals: $vals"

  # find in database
  set key "[ string trimright [ lindex $preffix 0 ] * ]key"
  set constrains [ join $pairs " and " ] 
  set sql "SELECT $key from ${table_name} WHERE $constrains;"
  dputs "  $sql"
  set rowid [ db eval $sql ]
  if { [ string compare $rowid "" ] != 0 } { 
    dputs "  FOUND: $key=$rowid"
    return $rowid 
  }

  # if not found insert
  set sql "INSERT INTO ${table_name}($cols) VALUES($vals);"
  db eval $sql
  set rowid [ db eval { SELECT last_insert_rowid() } ]
  dputs "  $sql"
  dputs "  INSERTED: rowid= $rowid"
  return $rowid
}

# ===================================================================== #
# return "" if this is script is not linked
# return "linked fname" otherwise
proc is_linked {fname} {
  set rc [ catch {set link [ file link $fname ]} ]
  if {$rc == 0} {
    return $link
  }
  return ""
}

proc get_homedir {} {
  upvar #0 argv0 script_name

  # when linked
  set fname [ is_linked $script_name ] 
  if { [ string compare $fname "" ] != 0 } {
    set script_name $fname
  }
  # find homedir of the script
  set HOMEDIR [ file dirname $script_name ]
  return $HOMEDIR
}

# ===================================================================== #
proc ::INSERT_DB::parse_args {} {
  set ::db_flag 0
  set ::db_val ""
  set ::g_dir_flag 0
  set ::g_dir_val ""
  set ::time_flag 0
  set ::time_val  0 
  set ::ports_flag 0
  set ::ports_val ""
  set ::src_fname ""
  set ::no_files_flag 0


  set size [ llength $::argv ]
  for {set i 0} {$i < $size} {incr i 1} {
    set flag [lindex $::argv $i ]
    set val  [lindex $::argv [ expr $i+1 ] ]

    switch -- $flag {
      "-db" {
        set ::db_flag 1
        set ::CONFIG::db_file $val
        set_full_path db_file
        incr i 1
      }
      "-no_files" {
        set ::no_files_flag 1
      }
      "-debug" {
        set ::DEBUG 1
      }
      default {
          set ::src_fname [ lindex $::argv $i]
          incr i
          break;
      }
    }
  }

  if {[string compare $::src_fname ""] == 0} {
    puts stderr "Source file not specified.\n"
    usage
    exit
  }
  if { [ file exists $::src_fname ] == 0 } {
    puts stderr "source file: '$fname' does not exists."
    exit 1
  }
}


# ===================================================================== #
# parser   

proc ::INSERT_DB::create_parser {} {
  namespace eval ::PARSER {

    # PARSED VALUES WILL BE STORED IN THIS NS
    namespace eval ::DATA ""

    # STATIC PART OF PARSER
    proc _DB_FNAME      { args } { set ::DATA::_db_fname  $args }
    proc _M_F_KEY        { args } { set ::DATA::_mf_key    $args }


    ### DYNAMICALLY BUILD PARSER ###
    # - it will be used to parse input file
    # - each line of the input file will be parser agains corresponding column name in database
    # - the dynamic part of the parser will produce code like STATIC part

    eval [ exec awk {$1 ~ /^m_/ { printf "proc %-15s {args} {set ::DATA::%-15s $args}\n", 
		toupper($1), tolower($1)}} ${::CONFIG::db_sql_schema_file_full} ]

    proc parse { fname } { 
      set ::DATA::_mf_db_file $fname
      if { [ catch { source $fname} errmsg]} {
        puts stderr "An error occured while parsing the source file: $fname"
        puts stderr "We do not know to which table and column in database this value should be mapped."
        puts stderr "PLEASE DEFINE PROC for this entry in PARSER"
        puts stderr $errmsg
        exit 3
      }
      if { ! [ info exists ::DATA::_db_fname ] } {
        puts stderr "_DB_FNAME directive not found in $fname file"
        exit 1
      }
    }
  }
}

proc ::INSERT_DB::insert_db {} {

  # overwrite db name
  if { $::db_flag == 1 } {
   set ::DATA::_db_fname $::CONFIG::db_file 
  } else {
    if {[ file exists $::DATA::_db_fname ] == 0 } {
     puts stderr "ERROR: database file does not exists: $::DATA::_db_fname"
     exit 1
    }
  }


 sqlite3 db $::DATA::_db_fname

 db eval { BEGIN TRANSACTION; }
 if { $::no_files_flag == 0 } {
  if { [ set t [ insert_file_or_dir ::DATA::_mf_db_file ] ]   > 0 } { set ::DATA::m_f_db_key   $t }
  if { [ set t [ insert_file_or_dir ::DATA::_mf_key ] ]       > 0 } { set ::DATA::m_f_key      $t }
 }
  if { [ set t [ select_or_insert_table measure m_*  ] ]      > 0 } { set ::DATA::m_key       $t }
 db eval { COMMIT; }
 db close
 return $::DATA::m_key
}
# ===================================================================== #
# Main
# ===================================================================== #

# IT WORKS LIKE THIS:
# 1. create parser which is based on database schema layout
#   - each column has corresponding variable
#   - variable name and column name are the same
#   - there is static part of parser (the names of vars begin with _)
#   - there is dynamic part which creates parser based on schema
# 2. The input file is read and parsed with the parser
#   - all variables are stored in ::DATA:: namespace
# 3. The command line of this script is used to overwrite the vars in ::DATA::
#   - this allows to overwritte certain vars from cmd line
# 4. The sql queires are generated automatically
#   - this is achieved by browsing ::DATA:: namespace for each table
#   - each table has unique prefix -> therefor for e.g. generate with are
#   searching for ::DATA::g?_* variables
#   - based on that we generate sql queries
#   - this queires are evaluated to db
#   - the results (such as keys) are stored again in ::DATA::var
#   - this allows to be automatically picked up by other sql generators in other tables

source "[get_homedir]/$PATH_LEVEL/_conf.tcl"
set DEBUG $::CONFIG::db_debug
source "${::CONFIG::utils_file_full}"
source "${::CONFIG::vhdl_parse_api_file_full}"
source "${::CONFIG::vhdl_ports_api_file_full}"

# If this script was executed, and not just "source"'d, handle argv
set linked_fname [ is_linked [info script ]]
if { [ string compare $linked_fname "" ] != 0 || [string compare [info script] $argv0] == 0} { 
  if {$argc == 0} { 
    ::INSERT_DB::usage
    exit
  }

  # command line options
  ::INSERT_DB::parse_args

  # parse data from file
  ::INSERT_DB::create_parser
  ::PARSER::parse $::src_fname
  if {$::db_flag} { set ::DATA::_db_fname $::CONFIG::db_file } 

  # store in db
  set c_key [ ::INSERT_DB::insert_db ]
  puts "Success. Circuit ROWID = $c_key"
}
