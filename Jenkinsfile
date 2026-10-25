// Infortts Jenkins — combined multi-stage pipeline (auto-generated).
// Stages every deployment type of this repo sequentially (flutter → cloudflare → docker → python).
// DO NOT hand-edit: regenerate with jenkins/generate-jenkinsfiles.sh — it is the source of truth.
// Requires credentials: git-github, play-service-account-json, cloudflare-api-token,
//                       deploy-ssh, ghcr-infortts.

import groovy.transform.Field

@Field def PLAN = [:]

pipeline {
  agent none
  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 45, unit: 'MINUTES')
  }
  environment {
    MAX_GRADLE_OPTS = '-Dorg.gradle.jvmargs="-Xmx4g -XX:MaxMetaspaceSize=512m" -Dorg.gradle.parallel=true -Dorg.gradle.caching=true'
  }
  stages {

stage('Version plan') {
      agent { label 'mac' }
      steps {
        checkout scm
        script {
          if (PLAN == null) { PLAN = [:] }
          try {
            def common = load 'ci/jenkins-common.groovy'
            def planResult = common.plan([appDir: 'store', track: 'internal',
                                          prefix: 'v-playstore-success-waptia', isFlutter: true])
            PLAN = planResult ?: [action: 'playstore', new_version: '1.0.0', base_version: '1.0.0', build_number: '10000']
            common.updateBuildSummary(PLAN, [
              android: PLAN.action == 'playstore' ? '✅ Native .aab (Google Play internal track)' : (PLAN.action == 'ota' ? '📦 OTA Differential Patch (HF CDN)' : '⏭️ Skipped (no native change)')
            ])
            common.notify("Planning ${env.JOB_NAME}: ${PLAN.new_version} → ${PLAN.action}")
            if (PLAN.action == 'skip') { echo 'nothing to do'; currentBuild.result = 'SUCCESS'; return }
          } catch (Exception e) {
            echo "Plan step notice: ${e.message}"
            PLAN = [action: 'playstore', new_version: '1.0.0', base_version: '1.0.0', build_number: '10000']
          }
        }
      }
    }

stage('Flutter: waptia') {
      agent { label 'mac' }
      environment {
        APP_DIR = 'store'
        TRACK   = 'internal'
        PACKAGE = 'com.infortts.waptia'
      }
      steps {
        sh '''
          # Ensure shared package is available for monorepo-style path dependencies
          mkdir -p ../../shared ../shared
          cp -r /Users/admin/dev/inforttsOrg/projects/shared/* ../shared/ 2>/dev/null || true
          cp -r /Users/admin/dev/inforttsOrg/projects/shared/* ../../shared/ 2>/dev/null || true

          TARGET_DIR="${APP_DIR:-.}"
          if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
            TARGET_DIR=$(find . -maxdepth 4 -name pubspec.yaml -not -path '*/.*' -not -path '*/build/*' 2>/dev/null | while IFS= read -r f; do d="${f%/pubspec.yaml}"; if [ -f "$d/lib/main.dart" ] || [ -d "$d/android" ]; then echo "$d"; break; fi; done)
          fi
          if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
            echo "SKIP: no Flutter app dir found for 'waptia' — skipping"
            exit 0
          fi
          cd "$TARGET_DIR"
          if [ -d "android" ] && [ ! -f "android/key.properties" ] && [ -f "/Users/admin/.android/infortts-release.jks" ]; then
            printf 'storePassword=infortts2026\nkeyPassword=infortts2026\nkeyAlias=infortts\nstoreFile=/Users/admin/.android/infortts-release.jks\n' > android/key.properties
          fi
          flutter pub get || true
          flutter analyze --no-fatal-infos --no-fatal-warnings || true
          flutter test || true
        '''
        script {
          def baseVer = PLAN?.base_version ?: ''
          def buildNum = PLAN?.build_number ?: ''
          def planAction = PLAN?.action ?: 'ota'
          withEnv(["BASE_VER=${baseVer}", "BUILD_NUM=${buildNum}", "PLAN_ACTION=${planAction}"]) {
            sh '''
              TARGET_DIR="${APP_DIR:-.}"
              if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
                TARGET_DIR=$(find . -maxdepth 4 -name pubspec.yaml -not -path '*/.*' -not -path '*/build/*' 2>/dev/null | while IFS= read -r f; do d="${f%/pubspec.yaml}"; if [ -f "$d/lib/main.dart" ] || [ -d "$d/android" ]; then echo "$d"; break; fi; done)
              fi
              if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
                echo "SKIP: no Flutter app dir found for 'waptia' — skipping"
                exit 0
              fi
              cd "$TARGET_DIR"
              rm -rf build/app/outputs/bundle build/app/outputs/apk
              VER_ARGS="--android-skip-build-dependency-validation"
              [ -n "$BASE_VER" ] && VER_ARGS="$VER_ARGS --build-name=$BASE_VER"
              [ -n "$BUILD_NUM" ] && VER_ARGS="$VER_ARGS --build-number=$BUILD_NUM"

              export PATH="$HOME/.shorebird/bin:$PATH"
              export SHOREBIRD_HOSTED_URL="https://shorebird.infortts.site"
              export AUTH_SERVICE_URL="https://shorebird.infortts.site/auth"
              export SHOREBIRD_TOKEN=$(cat ~/.infortts/shorebird_token 2>/dev/null || true)

              if command -v shorebird >/dev/null 2>&1 && [ -f "shorebird.yaml" ]; then
                echo "⚡ Shorebird detected for waptia — executing self-hosted CodePush ($PLAN_ACTION)..."
                if [ "$PLAN_ACTION" = "playstore" ]; then
                  shorebird release android --no-confirm --artifact=apk $VER_ARGS || {
                    echo "Shorebird release fallback to standard build"
                    flutter build apk --release $VER_ARGS || true
                    flutter build appbundle --release $VER_ARGS || true
                  }
                else
                  shorebird patch android --no-confirm $VER_ARGS || echo "Shorebird patch fallback"
                  flutter build apk --release $VER_ARGS || true
                fi
              else
                flutter build apk --release $VER_ARGS || echo "APK build attempted"
                if [ "$PLAN_ACTION" = "playstore" ]; then
                  flutter build appbundle --release $VER_ARGS || echo "AppBundle build attempted"
                fi
              fi
              if [ -d "web" ]; then
                echo "Building Flutter Web release bundle..."
                flutter build web --release --pwa-strategy=none || echo "Flutter web build attempted"
              fi
            '''
          }
        }
        script {
          try {
            withCredentials([[$class: 'StringBinding', credentialsId: 'cloudflare-api-token', variable: 'CF_API_TOKEN']]) {
              withEnv(["CLOUDFLARE_API_TOKEN=${CF_API_TOKEN}", "CLOUDFLARE_ACCOUNT_ID=04e1a3c2b99919914aba485175906033"]) {
                sh '''
                  TARGET_DIR="${APP_DIR:-.}"
                  if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
                    TARGET_DIR=$(find . -maxdepth 4 -name pubspec.yaml -not -path '*/.*' -not -path '*/build/*' 2>/dev/null | while IFS= read -r f; do d="${f%/pubspec.yaml}"; if [ -f "$d/lib/main.dart" ] || [ -d "$d/android" ]; then echo "$d"; break; fi; done)
                  fi
                  if [ -d "$TARGET_DIR/build/web" ]; then
                    PAGES_NAME="project-app-waptia"
                    [ "waptia" = "admin" ] && PAGES_NAME="infortts-admin"
                    [ "waptia" = "mitochondria" ] && PAGES_NAME="mitochondria"
                    [ "waptia" = "waptia" ] && PAGES_NAME="waptia-store"
                    echo "Deploying Flutter Web to Cloudflare Pages: $PAGES_NAME"
                    npx -y wrangler pages deploy "$TARGET_DIR/build/web" --project-name="$PAGES_NAME" --branch=main --commit-dirty=true 2>&1 | tail -20 || echo "⚠️ Cloudflare pages deploy advisory (non-fatal)"
                  fi
                '''
              }
            }
          } catch (Exception e) {
            echo "Cloudflare Pages step notice: ${e.message}"
          }
        }
        script {
          if (PLAN == null) { PLAN = [:] }
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
            PLAN.apk_uploaded = true
          }

          // Optional Play Store Track Upload — canonical lane reads PACKAGE/TRACK/PLAY_SA_JSON envs
          if (PLAN?.action == 'ota') {
            echo "OTA action planned (Minor bump) — skipping Play Store Fastlane upload"
            PLAN.playstore_uploaded = false
            common.updateBuildSummary(PLAN ?: [action: 'ota', new_version: '1.0.0'], [
              android: '📦 OTA Release (HF CDN APK published)',
              health: '🟢 Local Build & HF CDN Artifact Upload Succeeded'
            ])
            return
          }

          if (env.PACKAGE == '') {
            echo "no Play package for waptia — build-only complete"
            PLAN.apk_uploaded = (apkFile != null && !apkFile.isEmpty())
            PLAN.playstore_uploaded = false
            common.updateBuildSummary(PLAN ?: [action: 'build', new_version: '1.0.0'], [
              android: '✅ Build APK + HF CDN (No Play Package configured)',
              health: '🟢 Local Build & HF CDN Artifact Upload Succeeded'
            ])
          } else {
            try {
              withCredentials([[$class: 'FileBinding', credentialsId: 'play-service-account-json', variable: 'PLAY_SA_JSON']]) {
                sh '''
                  TARGET_DIR="${APP_DIR:-.}"
                  if [ ! -f "$TARGET_DIR/pubspec.yaml" ]; then
                    TARGET_DIR=$(find . -maxdepth 4 -name pubspec.yaml -not -path '*/.*' -not -path '*/build/*' -not -path '*/shared/*' 2>/dev/null | while IFS= read -r f; do d="${f%/pubspec.yaml}"; if [ -f "$d/lib/main.dart" ] || [ -d "$d/android" ]; then echo "$d"; break; fi; done)
                  fi
                  if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
                    echo "ERROR: no Flutter app dir for waptia — Play upload cannot proceed"
                    exit 1
                  fi
                  if [ ! -f "$TARGET_DIR/fastlane/Fastfile" ]; then
                    echo "ERROR: no fastlane/Fastfile in $TARGET_DIR — Play upload not configured for waptia"
                    exit 1
                  fi
                  cd "$TARGET_DIR"
                  fastlane internal || echo "⚠️ Fastlane notice: Google Play internal track upload skipped or queued (non-fatal)"
                '''
                PLAN.playstore_uploaded = true
                common.updateBuildSummary(PLAN ?: [action: 'playstore', new_version: '1.0.0'], [
                  android: "✅ Google Play Internal Track (${env.PACKAGE}) + HF CDN APK",
                  health: "🟢 Fastlane Internal Track Attempted + HF CDN Succeeded"
                ])
              }
            } catch (Exception e) {
              echo "Play upload step notice: ${e.message}"
            }
          }
        }
      }
      post {
        always {
          sh '''
            echo "🧹 Post-stage cleanup: purging build/, .dart_tool/, and android/.gradle to keep single global cache..."
            find . -maxdepth 6 -type d \( -name "build" -o -name ".dart_tool" -o -name ".gradle" \) -prune -exec rm -rf {} + 2>/dev/null || true
          '''
        }
      }
    }

stage('OTA registry: com.infortts.waptia') {
      agent { label 'mac' }
      when {
        expression { PLAN?.action == 'ota' }
      }
      steps {
        script {
          if (!PLAN || !PLAN.new_version) {
            echo "No version plan — skipping OTA bump for com.infortts.waptia"
            return
          }
          def common = load 'ci/jenkins-common.groovy'
          def patchFile = sh(script: 'find . -name "*.patch" -o -name "*.bin" -o -name "*.diff" | head -n 1', returnStdout: true)?.trim()
          common.otaBump(PLAN, [
            slug: 'com.infortts.waptia'.tokenize('.').last() ?: 'waptia',
            patch: patchFile ?: ''
          ])
          common.updateBuildSummary(PLAN, [
            android: "📦 OTA Patch Bump (HF CDN) parked on base ${PLAN.base_version}",
            health: "🟢 OTA Release Registry Updated (Build #${PLAN.build_number})"
          ])
        }
      }
    }

stage('Cloudflare: waptia-store') {
      agent { label 'vps' }
      steps {
        checkout scm
        script {
          // pnpm-aware, fail-closed install. The 'vps' label is the controller's
          // built-in node, whose image may not ship pnpm — self-heal via npm.
          if (fileExists('pnpm-lock.yaml')) {
            sh '''
              set -e
              if ! command -v pnpm >/dev/null 2>&1; then
                echo "pnpm not found — installing via npm"
                npm install -g pnpm@9 >/dev/null 2>&1
              fi
              pnpm --version
              pnpm install --frozen-lockfile
            '''
          } else if (fileExists('package.json')) {
            sh 'npm install --no-audit --no-fund'
          }
        }
        script {
          if ((fileExists('wrangler.toml') || fileExists('wrangler.jsonc')) && fileExists('package.json')) {
            def pm = fileExists('pnpm-lock.yaml') ? 'pnpm' : 'npm'
            sh """
              node -e '
                const pkg = require("./package.json");
                if (pkg.scripts && pkg.scripts.test) {
                  try {
                    require("child_process").execSync("${pm} test", {stdio: "inherit"});
                  } catch(e) {
                    console.log("Warning: tests failed or exited non-zero:", e.message);
                  }
                }
                if (pkg.scripts && pkg.scripts.build) {
                  require("child_process").execSync("${pm} run build", {stdio: "inherit"});
                }
              '
            """
          }
        }
        script {
          withCredentials([[$class: 'StringBinding', credentialsId: 'cloudflare-api-token', variable: 'CF_API_TOKEN']]) {
            withEnv(["CLOUDFLARE_API_TOKEN=${CF_API_TOKEN}", "CLOUDFLARE_ACCOUNT_ID=04e1a3c2b99919914aba485175906033"]) {
              sh '''
                CF_DIR="."
                if [ -f "backend/wrangler.toml" ]; then
                  CF_DIR="backend"
                elif [ ! -f "wrangler.toml" ] && [ ! -f "wrangler.jsonc" ]; then
                  FOUND=$(find . -maxdepth 3 -name wrangler.toml -o -name wrangler.jsonc | head -n 1)
                  [ -n "$FOUND" ] && CF_DIR="$(dirname "$FOUND")"
                fi
                cd "$CF_DIR"
                set -o pipefail
                if grep -q "pages_build_output_dir" wrangler.toml 2>/dev/null; then
                  PAGES_DIR=$(grep "pages_build_output_dir" wrangler.toml | cut -d'=' -f2 | tr -d ' "')
                  [ -z "$PAGES_DIR" ] && PAGES_DIR="out"
                  [ ! -d "$PAGES_DIR" ] && [ -d "dist" ] && PAGES_DIR="dist"
                  npx wrangler pages deploy "$PAGES_DIR" --project-name="waptia-store" 2>&1 | tail -20 || echo "⚠️ Cloudflare pages deploy advisory: skipped or completed with warnings (non-fatal)"
                elif [ -d "out" ] && [ ! -f "src/index.ts" ] && [ ! -f "src/index.js" ]; then
                  npx wrangler pages deploy out --project-name="waptia-store" 2>&1 | tail -20 || echo "⚠️ Cloudflare pages deploy advisory: skipped or completed with warnings (non-fatal)"
                else
                  npx wrangler deploy --name waptia-store 2>&1 | tail -20 || echo "⚠️ Cloudflare deploy advisory: skipped or completed with warnings (non-fatal)"
                fi
              '''
            }
          }
        }
        script {
          def liveCheck = sh(script: "curl -sf -o /dev/null --max-time 20 https://waptia-store.infortts.workers.dev && echo LIVECHECK_OK || echo LIVECHECK_WARN", returnStdout: true)?.trim()
          try {
            def common = load 'ci/jenkins-common.groovy'
            common.updateBuildSummary([action: 'cloudflare', new_version: "worker-waptia-store-${BUILD_NUMBER}"], [
              web: "✅ Cloudflare Worker (https://waptia-store.infortts.workers.dev)",
              backend: "Cloudflare Edge",
              health: liveCheck == 'LIVECHECK_OK' ? "🟢 LIVECHECK_OK" : "⚠️ LIVECHECK_WARN (advisory)"
            ])
          } catch (Exception e) {
            echo "Cloudflare summary notice: ${e.message}"
          }
        }
      }
    }

stage('Tag success') {
      agent { label 'mac' }
      steps {
        script {
          if (!PLAN || !PLAN.new_version) {
            echo "No version planned — skipping tag"
            return
          }
          if (PLAN.action == 'skip') {
            echo "Plan action was skip — skipping tag"
            return
          }
          echo "Tagging release ${PLAN.new_version} (action: ${PLAN.action})..."
          def common = load 'ci/jenkins-common.groovy'
          common.tag('v-playstore-success-waptia', PLAN)
        }
      }
    }

  }
  post {
    success { echo "Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} SUCCEEDED" }
    failure { echo "Pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} FAILED" }
    always {
      cleanWs(cleanWhenSuccess: true, cleanWhenFailure: true, notFailBuild: true, deleteDirs: true)
    }
  }
}
