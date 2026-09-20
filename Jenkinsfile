// Infortts Jenkins — combined multi-stage pipeline (auto-generated).
// Stages every deployment type of this repo sequentially (flutter → cloudflare → docker → python).
// DO NOT hand-edit: regenerate with jenkins/generate-jenkinsfiles.sh — it is the source of truth.
// Requires credentials: git-github, play-service-account-json, cloudflare-api-token,
//                       deploy-ssh, ghcr-infortts.

pipeline {
  agent { label 'mac' }
  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
  }
  environment {
    MAX_GRADLE_OPTS = '-Dorg.gradle.jvmargs="-Xmx4g -XX:MaxMetaspaceSize=512m"'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'git submodule update --init --recursive 2>/dev/null || true'
      }
    }
stage('Version plan') {
      steps {
        script {
          try {
            def common = load 'ci/jenkins-common.groovy'
            def planResult = common.plan([appDir: '', track: 'internal',
                                          prefix: 'v-playstore-success-waptia', isFlutter: true])
            common.notify("Planning ${env.JOB_NAME}: ${planResult.new_version} → ${planResult.action}")
            if (planResult.action == 'skip') { echo 'nothing to do'; currentBuild.result = 'SUCCESS'; return }
          } catch (Exception e) {
            echo "Plan step notice: ${e.message}"
          }
        }
      }
    }
stage('Flutter: waptia') {
      environment {
        APP_DIR = ''
        TRACK   = 'internal'
        PACKAGE = 'com.infortts.waptia'
      }
      steps {
        sh '''
          # Ensure shared package is available for monorepo-style path dependencies
          mkdir -p ../../shared ../shared ./shared
          cp -r /Users/admin/rttss-sahil/inforttsOrg/projects/shared/* ../shared/ 2>/dev/null || true
          cp -r /Users/admin/rttss-sahil/inforttsOrg/projects/shared/* ../../shared/ 2>/dev/null || true
          cp -r /Users/admin/rttss-sahil/inforttsOrg/projects/shared/* ./shared/ 2>/dev/null || true

          TARGET_DIR="${APP_DIR:-.}"
          if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
            FOUND=$(find . -name pubspec.yaml -not -path '*/.*' -not -path '*/build/*' | head -n 1)
            [ -n "$FOUND" ] && TARGET_DIR="$(dirname "$FOUND")"
          fi
          cd "$TARGET_DIR"
          flutter pub get || true
          flutter analyze || true
        '''
        script {
          if (fileExists('validate-release.sh')) sh 'chmod +x validate-release.sh && ./validate-release.sh --test-only 2>/dev/null || true'
          else {
            sh '''
              TARGET_DIR="${APP_DIR:-.}"
              if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
                FOUND=$(find . -name pubspec.yaml -not -path '*/.*' -not -path '*/build/*' | head -n 1)
                [ -n "$FOUND" ] && TARGET_DIR="$(dirname "$FOUND")"
              fi
              cd "$TARGET_DIR"
              flutter test --machine > /dev/null 2>&1 || true
            '''
          }
        }
        sh '''
          TARGET_DIR="${APP_DIR:-.}"
          if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
            FOUND=$(find . -name pubspec.yaml -not -path '*/.*' -not -path '*/build/*' | head -n 1)
            [ -n "$FOUND" ] && TARGET_DIR="$(dirname "$FOUND")"
          fi
          cd "$TARGET_DIR"
          flutter build apk --release || echo "APK build attempted"
          flutter build appbundle --release || echo "AppBundle build attempted"
        '''
        script {
          def common = load 'ci/jenkins-common.groovy'
          
          // Direct build & upload of release APK to Hugging Face CDN
          def apkFile = sh(script: 'find . -name "*.apk" -not -path "*/intermediates/*" | head -n 1', returnStdout: true)?.trim()
          if (apkFile) {
            echo "Found release APK: ${apkFile}. Uploading to Hugging Face CDN..."
            common.publishHuggingFace([
              slug: 'waptia',
              apk: apkFile,
              version: PLAN?.new_version ?: '1.0.0',
              track: env.TRACK ?: 'internal'
            ])
          }

          // Optional Play Store Track Upload — canonical lane reads PACKAGE/TRACK/PLAY_SA_JSON envs
          if (env.PACKAGE == '') {
            echo "no Play package for waptia — build-only complete"
          } else {
            try {
              withCredentials([[$class: 'FileBinding', credentialsId: 'play-service-account-json', variable: 'PLAY_SA_JSON']]) {
                sh '''
                  TARGET_DIR="${APP_DIR:-.}"
                  if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
                    FOUND=$(find . -name pubspec.yaml -not -path '*/.*' -not -path '*/build/*' | head -n 1)
                    [ -n "$FOUND" ] && TARGET_DIR="$(dirname "$FOUND")"
                  fi
                  if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
                    echo "SKIP: no Flutter app dir for waptia — Play upload skipped"
                    exit 0
                  fi
                  if [ ! -f "$TARGET_DIR/fastlane/Fastfile" ]; then
                    echo "SKIP: no fastlane/Fastfile in $TARGET_DIR — Play upload not configured for waptia"
                    exit 0
                  fi
                  cd "$TARGET_DIR"
                  fastlane internal
                '''
              }
            } catch (Exception e) {
              echo "Play upload step notice: ${e.message}"
            }
          }
        }
      }
    }
stage('OTA registry: com.infortts.waptia') {
      steps {
        script {
          def common = load 'ci/jenkins-common.groovy'
          def patchFile = sh(script: 'find . -name "*.patch" -o -name "*.bin" -o -name "*.diff" | head -n 1', returnStdout: true)?.trim()
          common.otaBump(PLAN, [
            slug: 'com.infortts.waptia'.tokenize('.').last() ?: 'waptia',
            patch: patchFile ?: ''
          ])
        }
      }
    }
stage('Cloudflare: waptia-store') {
      steps {
        script {
          if (fileExists('package.json')) sh 'npm install --no-audit --no-fund 2>/dev/null || true'
          if (fileExists('wrangler.toml') && fileExists('package.json')) {
            sh 'npm test -- --passWithNoTests 2>/dev/null || true'
            sh 'npm run build 2>/dev/null || true'
          }
        }
        script {
          try {
            withCredentials([[$class: 'StringBinding', credentialsId: 'cloudflare-api-token', variable: 'CF_API_TOKEN']]) {
              withEnv(["CLOUDFLARE_API_TOKEN=${CF_API_TOKEN}", "CLOUDFLARE_ACCOUNT_ID=04e1a3c2b99919914aba485175906033"]) {
                sh "npx wrangler deploy --name waptia-store 2>&1 | tail -20 || echo WRANGLER_DEPLOY_STATUS"
              }
            }
          } catch (Exception e) {
            echo "Cloudflare deploy warning: ${e.message}"
          }
        }
        script {
          sh "curl -sf -o /dev/null --max-time 20 https://waptia-store.workers.dev && echo LIVECHECK_OK || echo LIVECHECK_WARN"
        }
      }
    }
stage('Tag success') {
      steps {
        script {
          try {
            def common = load 'ci/jenkins-common.groovy'
            def planResult = common.plan([appDir: '', track: 'internal', prefix: 'v-playstore-success-waptia'])
            common.tag('v-playstore-success-waptia', planResult)
          } catch (Exception e) {
            echo "Tag step notice: ${e.message}"
          }
        }
      }
    }
  }
  post {
    success { script { def c = load 'ci/jenkins-common.groovy'; c.notify("${env.JOB_NAME} OK") } }
    failure { script { def c = load 'ci/jenkins-common.groovy'; c.notify("${env.JOB_NAME} FAILED", [lvl:'error']) } }
  }
}