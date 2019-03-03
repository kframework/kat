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
    stage('Dependencies') {
      steps {
        ansiColor('xterm') {
          sh '''
            make clean
            make deps
          '''
        }
      }
    }
    stage('Build') {
      steps {
        ansiColor('xterm') {
          sh '''
            make build -j4
          '''
        }
      }
    }
    stage('Test') {
      steps {
        ansiColor('xterm') {
          sh '''
            make test -j8
          '''
        }
      }
    }
  }
}
