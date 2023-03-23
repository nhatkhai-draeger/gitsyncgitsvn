def Def() { if (binding.hasVariable('_def_')) { return _def_ }
  _def_ = readProperties(file:'\\\\att\\distribution\\config\\jenkins.def')
  return _def_
} // Load default Jenkins infrastructure variables from share file

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
    DEF_ENV_URL= "${Def().envUrl}"

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
    stage('standard') { steps { script
    { buildName "$BUILD_NUMBER-$NODE_NAME"

      // Repair agent machine before do checkout to help reduce failure
      // . That also include install git if not not yet presented.
      writeFile file: CIUTILS, text: readTrusted(CIUTILS).replace('\n','\r\n')
      st=0; retry(7) { sleep(st); st=20; bat "$CIUTILS gitFetchCache" }

      readProperties(file:".ret").each{k,v-> env."$k"=v}

      checkout scm: scm

      env.PATH = "$env.GIT_INST_DEF;$env.PATH"
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

// Email extracted seemly error from console, build parameters, and result
def sendEmail()
{
  def errorPatten = ~/(?m)\b(\e\[[;0-9]+m)*ERROR(\e\[[;0-9]+m)*\b.*$/
  log = httpRequest "${env.BUILD_URL}consoleText"
  def errs = (log.content =~ errorPatten).collect{
    it[0].replaceAll(/\e\[[0-9;]+m/, "") }

  def p = params.collect{ k,v -> "$k = $v" }
  emailext \
    subject : "$currentBuild.currentResult: $env.JOB_BASE_NAME #$env.BUILD_NUMBER",
    body    : """Following reports are for $env.BRANCH_NAME:
      * Branch's builds summary: $env.JOB_URL
      * Build summary: $env.RUN_DISPLAY_URL
      * Build detail console: ${env.BUILD_URL}console
      * Build parameter(s):
            ${p.join(   '\n            ')}
      * Build Error(s):
            ${errs.join('\n            ')}
    """,
    recipientProviders: [developers(), culprits(), requestor()]
}
