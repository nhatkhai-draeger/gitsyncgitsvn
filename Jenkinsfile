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

    PATH        = "$ProgramFiles\\Git LFS;$PATH"
  }

  stages
  {
    // Checkout the repository. Install Windows Git if the agent machine
    // don't have git installed
    stage('checkout') { steps
    {
      writeFile file:CIUTILS, text:readTrusted(CIUTILS).replace('\n','\r\n')
      retry(7) { sleep(binding.variables.putIfAbsent('delay', 20)?:0)
        bat "$CIUTILS gitFetchCache" }

      checkout scm: scm
    } /*steps*/ } /*stage*/

    stage("setup") { steps
    {
      // Install cygwin
      bat """$CIUTILS getCygPkg https://cygwin.com/setup-x86_64.exe \
        git git-svn subversion sed gawk bash"""

      // Install Git LFS to work with git Cygwin if not found
      bat """IF NOT EXIST "$ProgramFiles\\Git LFS\\git-lfs.exe" \
        $CIUTILS runUrl \
          https://github.com/git-lfs/git-lfs/releases/download/v2.13.3/git-lfs-windows-v2.13.3.exe\
          /VERYSILENT
      """
    } /*steps*/ } /*stage*/

    stage("main") { parallel
    {
      stage("syntax") { steps { bat "$CIUTILS runBash ./cijobs.sh syntax" } }
      stage("test"  ) { steps { bat "$CIUTILS runBash ./cijobs.sh test"   } }
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
