# Title #
Author: [Jim Hester](http://jimhester.com)
Created: 2013 Apr 02 03:17:40 PM
Last Modified: 2013 May 30 02:47:06 PM

A skeleton R analysis framework for use with knitr and git.

I like to abide by these guidelines to keep things organized.

* try to commit changes regularly!
* make a tag of the state if you send a plot/analysis to someone!
* all input data does in data/
* all intermediate files go in tmp/
* all tabulated,count,stat files go in output/
* any complied source code is put in src/, R code in R/ scripts in exec/
* each major task is split into a separate Rmd file and placed in the base directory
* every Rmd file is added as a child document to the full_report.Rmd
* I generally cache all my Rmd chunks, but to be safe set eval=F for very long
  running jobs after they have been run in case the cache is invalidated
  accidentally.
* For nice styled reports that work well with this framework see [knitr_bootstrap](https://github.com/jimhester/knitr_bootstrap).
