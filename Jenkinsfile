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

  environment {
    cacheL1     = "$BASE\\caches"
    cacheL2     = "\\\\att\\distribution\\cached"
    ci_proxy    = "http://185.46.212.91:80"
    CIUTILS     = "${pwd( tmp: true )}\\ciUtils.cmd"

    // Bellow try to use clean windows environment
    APPDATA     = pwd( tmp: true )
    LOCALAPPDATA= "$APPDATA"
    USERPROFILE = pwd( tmp: true )
    HOME        = "$USERPROFILE"
    TMP         = pwd( tmp: true )
    TEMP        = "$TMP"
    PATH        = "$env.ProgramFiles\\Git LFS;$env.PATH"
  }

  stages
  {
    // Checkout the repository. Install git if the agent machine don't have
    // git installed
    stage('checkout') { steps 
    {
      writeFile file: "$CIUTILS",
                text: readTrusted("ciUtils.cmd")

      bat """where git \
        || $CIUTILS runUrl https://github.com/git-for-windows/git/releases/download/v2.22.0.windows.1/Git-2.22.0-64-bit.exe /VERYSILENT \
        && echo "There will be errors until Agent reboot completed" \
        && shutdown /r /t 0""" 

      // In case of agent machine booting, try long enough before it ready
      retry(200) { sleep(3); checkout scm: scm }
    } /*steps*/ } /*syntax stage*/ 

    stage("setup") { steps 
    { 
      // Install cygwin
      bat """$CIUTILS getCygPkg https://cygwin.com/setup-x86_64.exe \
        git git-svn subversion sed gawk bash"""

      // Install Git LFS if not found
      bat """where git-lfs \
        || $CIUTILS runUrl https://github.com/git-lfs/git-lfs/releases/download/v2.10.0/git-lfs-windows-v2.10.0.exe /VERYSILENT
      """
    } /*steps*/ } /*syntax stage*/ 

    stage("main") { parallel 
    {
      stage("syntax") { steps { bat "$CIUTILS runBash ./cijobs.sh syntax" } }
      stage("test"  ) { steps { bat "$CIUTILS runBash ./cijobs.sh test"   } }
    } /*parallel*/ } /*stage*/
  }

  post
  {
    regression { script { sendEmail() } }
    fixed      { script { sendEmail() } }
  }
}


def sendEmail()
{
  emailext \
    subject : "$env.JOB_NAME #$env.BUILD_NUMBER: $currentBuild.result",
    body    : """Following reports are for $env.BRANCH_NAME branch:
      * Branch's builds summary: $env.JOB_URL
      * Build summary: $env.RUN_DISPLAY_URL
      * Build detail console: $env.BUILD_URL/console
    """,
    recipientProviders: [culprits(), requestor()]
}
