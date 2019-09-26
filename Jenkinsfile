pipeline
{
  agent any
  stages
  {
    stage("syntax") { steps { script
    {
      // Search all the bash script files
      sh """grep "^#!.*/bash" * -l > .tmp.bashFiles"""

      // Check syntax on all bash script files
      sh """#!/bin/bash -e
        rm -f .tmp.errors
        while read f; do 
          echo "Check \$f";
          bash -n "\$f" || printf "\$f, ">>.tmp.errors; 
        done < .tmp.bashFiles"""

      if (fileExists(".tmp.errors"))
        error "${readFile('.tmp.errors')} fail syntax check"

    } /*script*/ } } /*stage*/
  }
}
