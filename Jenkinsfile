pipeline {
  agent {
    dockerfile {
      additionalBuildArgs '--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)'
    }
  }
  stages {
    stage("Init title") {
      when { changeRequest() }
      steps {
        script {
          currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}"
        }
      }
    }
    stage('Build') {
      steps {
        ansiColor('xterm') {
          sh '''
            export PATH=$HOME/.local/bin:$PATH
            make clean
            make deps
            make build -j2
          '''
        }
      }
    }
    stage('Test') {
      steps {
        ansiColor('xterm') {
          sh '''
            export PATH=$HOME/.local/bin:$PATH
            make test -j6
          '''
        }
      }
    }
  }
}
