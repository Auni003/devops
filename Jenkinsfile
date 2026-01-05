pipeline {
    agent any

    environment {
        IMAGE_NAME     = "wm-employee-api"
        IMAGE_TAG      = "v1"
        CONTAINER_NAME = "wm-employee-api"
        NETWORK_NAME   = "jenkins-net"
        IS_PORT        = "5555"

        // Sample request payload for smoke test
        EMP_PAYLOAD = '''{
            "empCode": "E001",
            "empName": "Auni",
            "department": "IT"
        }'''
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Ensure Docker Network') {
            steps {
                sh """
                docker network inspect ${NETWORK_NAME} >/dev/null 2>&1 || \
                docker network create ${NETWORK_NAME}
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🔨 Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Stop & Remove Existing Container') {
            steps {
                sh """
                docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
                docker rm   ${CONTAINER_NAME} >/dev/null 2>&1 || true
                """
            }
        }

        stage('Run API Container') {
            steps {
                sh """
                docker run -d \
                  --name ${CONTAINER_NAME} \
                  --network ${NETWORK_NAME} \
                  -p ${IS_PORT}:5555 \
                  ${IMAGE_NAME}:${IMAGE_TAG}
                """

                echo "⏳ Waiting for webMethods IS to start..."
                sleep 40
            }
        }

        stage('Readiness Check (IS Up)') {
            steps {
                script {
                    boolean ready = false

                    for (int i = 1; i <= 12; i++) {
                        sleep 6
                        def status = sh(
                            script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:${IS_PORT}/invoke/wm.server/ping",
                            returnStdout: true
                        ).trim()

                        echo "Attempt ${i}: HTTP ${status}"

                        if (status == "200") {
                            ready = true
                            break
                        }
                    }

                    if (!ready) {
                        error "❌ webMethods IS did not become ready"
                    }
                }
            }
        }

        stage('Smoke Test: POST Employee API') {
            steps {
                script {
                    def status = sh(
                        script: """
                        curl -s -o /dev/null -w '%{http_code}' \
                        -X POST http://localhost:${IS_PORT}/rad/employee.resources:rad_employee/insertEmployee \
                        -H 'Content-Type: application/json' \
                        -d '${EMP_PAYLOAD}'
                        """,
                        returnStdout: true
                    ).trim()

                    echo "POST /employee -> HTTP ${status}"

                    if (!(status in ["200", "201", "202"])) {
                        error "❌ Smoke test failed (HTTP ${status})"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully"
        }
        failure {
            echo "❌ Pipeline failed"
        }
        always {
            sh "docker ps | grep ${CONTAINER_NAME} || true"
        }
    }
}
