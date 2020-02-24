# Author: DS
# Date:   20171020
#
#reads file version_num.v
#searches for determined string "//VERSION:" above the version data
#replaces the string vith version assignment with YYMMDDHH data

# File parcing and rewriting procedure
proc gen_ver_v { dec_ver_value } {

 
if { [catch {
     set infile [open "version_num.v" r]
     set file_data [read $infile]

     close $infile
	  
	  set cntr 0
	  set ver_found 0
	  
	  set line_data [split $file_data "\n"]
     foreach line $line_data {
	    incr cntr
       if {[string match "//VERSION:" $line]} {
		   post_message "Version string is found:"
			 post_message [lindex $line_data $cntr ]			
			 lset line_data $cntr $dec_ver_value
		   post_message "Replaced with:"
			 post_message [lindex $line_data $cntr ]			
			 set ver_found 1
			 break
			}	 
     }
	  
     if {$ver_found == 1} {
	  	  set outfile [open "version_num.v" w]
		  foreach line $line_data {
		   puts $outfile $line
		  }
		  close $outfile
	  }

	  
    } res ] } {
        return -code error $res
    } else {
        return 1
    }

}


# Program Start
init_tk

set DATE_TIME_STR [clock format [clock seconds] -format {assign VERSION = 32'h%y%m%d%H;}]
  
# go to the root project directory
#cd ".../"
#cd ".../"
# change to the output files directory
set dir "version_num/source/"
cd $dir
  
binary scan $DATE_TIME_STR A* out_dec

gen_ver_v $out_dec
