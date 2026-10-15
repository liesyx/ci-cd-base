// Flow: GitHub push -> Jenkins (test + build) -> Harbor -> Helm deploy to k3s
pipeline {
  agent any

  environment {
    // ===== EDIT THESE =====
    REGISTRY   = 'harbor.oci.lexsy.pro.vn'   // Harbor domain
    IMAGE_NAME = 'cicd/cicd-demo'            // <harbor-project>/<repo>, lowercase
    NAMESPACE  = 'demo'
    RELEASE    = 'cicd-demo'
    CHART_DIR  = 'helm/cicd-demo'
    // ======================

    // docker, kubectl, helm live in the persistent Jenkins volume
    PATH = "/var/jenkins_home/bin:${env.PATH}"
    DOCKER_BUILDKIT = '1'
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.GIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_SHORT}"
          env.IMAGE     = "${env.REGISTRY}/${env.IMAGE_NAME}"
        }
        echo "Image will be ${env.IMAGE}:${env.IMAGE_TAG}"
      }
    }

    stage('CI: Test') {
      steps {
        // Runs `npm test` inside the Dockerfile's "test" stage; fails the build if tests fail
        sh 'docker build --target test -t $IMAGE:test-$IMAGE_TAG .'
      }
    }

    stage('CI: Build image') {
      steps {
        sh 'docker build --target runtime -t $IMAGE:$IMAGE_TAG -t $IMAGE:latest .'
      }
    }

    stage('Push to Harbor') {
      steps {
        withCredentials([usernamePassword(
            credentialsId: 'harbor-login',       // Harbor robot account (push + pull)
            usernameVariable: 'REG_USER',
            passwordVariable: 'REG_PASS')]) {
          sh '''
            echo "$REG_PASS" | docker login $REGISTRY -u "$REG_USER" --password-stdin
            docker push $IMAGE:$IMAGE_TAG
            docker push $IMAGE:latest
            docker logout $REGISTRY
          '''
        }
      }
    }

    stage('Helm lint') {
      steps {
        sh 'helm lint $CHART_DIR --set image.tag=$IMAGE_TAG'
      }
    }

    stage('CD: Helm deploy to k3s') {
      // only deploy from main (works for both plain Pipeline and Multibranch jobs)
      when { expression { env.BRANCH_NAME == 'main' || env.GIT_BRANCH in ['main', 'origin/main'] } }
      steps {
        withCredentials([file(credentialsId: 'kubeconfig-k3s', variable: 'KUBECONFIG')]) {
          sh '''
            helm upgrade --install $RELEASE $CHART_DIR \
              --namespace $NAMESPACE \
              --set image.repository=$IMAGE \
              --set image.tag=$IMAGE_TAG \
              --set appVersion=$IMAGE_TAG \
              --atomic --wait --timeout 3m \
              --history-max 10

            helm -n $NAMESPACE history $RELEASE --max 5
            kubectl -n $NAMESPACE get pods -l app.kubernetes.io/instance=$RELEASE
          '''
        }
      }
    }
  }

  post {
    always {
      // free disk on the host: remove local copies built in this run
      sh 'docker rmi $IMAGE:test-$IMAGE_TAG $IMAGE:$IMAGE_TAG $IMAGE:latest 2>/dev/null || true'
    }
    success {
      echo "✅ ${env.IMAGE}:${env.IMAGE_TAG} deployed with Helm (release ${env.RELEASE}, ns ${env.NAMESPACE})"
    }
    failure {
      echo "❌ Failed. --atomic rolled the release back automatically if the deploy step failed."
    }
  }
}
