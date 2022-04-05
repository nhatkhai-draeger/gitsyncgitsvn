pipeline
{
  agent { label 'ATT' }

  options
  {
    skipDefaultCheckout true
    buildDiscarder logRotator( daysToKeepStr:'30' )
    timeout time: 2, unit: 'HOURS'
    ansiColor('xterm')
  }

  environment
  {
    cacheL1     = "$BASE\\caches"
    DEF_ENV_URL = "http://att/distribution/config/env/jenkins.txt"

    CIUTILS     = "ciUtils.cmd"

    // Bellow try to use clean windows environment
    USERPROFILE = pwd( tmp: true )
    HOME        = pwd( tmp: true )
    APPDATA     = pwd( tmp: true )
    LOCALAPPDATA= pwd( tmp: true )
    TMP         = pwd( tmp: true )
    TEMP        = pwd( tmp: true )
  }

  stages
  {
    // Checkout the repository. Install Windows Git if the agent machine
    // don't have git installed
    stage('checkout') { steps { script
    {
      writeFile file:CIUTILS, text:readTrusted(CIUTILS).replace('\n','\r\n')
      st=0; retry(7) { sleep(st); st=20; bat "$CIUTILS gitFetchCache" }
      readProperties(file: ".ret").each { k, v -> env."$k"=v } 
      env.PATH = "$env.GIT_INST_DEF;$env.PATH"

      checkout scm: scm
    } } /*steps*/ } /*stage*/

    stage("main") { parallel
    {
      stage("syntax") { steps { bat "bash ./cijobs.sh . syntax" } }
      stage("test"  ) { steps { bat "bash ./cijobs.sh . test"   } }
    } /*parallel*/ } /*stage*/
  }

  post
  {
    unsuccessful { script { sendEmail() } }
    fixed        { script { sendEmail() } }
  }
}


def sendEmail()
{
  emailext \
    subject : "$currentBuild.currentResult: $env.JOB_NAME #$env.BUILD_NUMBER",
    body    : """Following reports are for $env.BRANCH_NAME branch:
      * Branch's builds summary: $env.JOB_URL
      * Build summary: $env.RUN_DISPLAY_URL
      * Build detail console: $env.BUILD_URL/console
    """,
    recipientProviders: [developers(), culprits(), requestor()]
}
