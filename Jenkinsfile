// Jenkinsfile
// Complete CI/CD pipeline for Terraform + Terragrunt automation
// Stages: Checkout → Validate → Plan → Approve → Apply → Report

pipeline {
    agent any
    
    // Build parameters - allow manual overrides
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target environment for deployment'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
            description: 'Action to perform (plan shows changes, apply deploys)'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Skip manual approval (use with caution!)'
        )
    }
    
    // Environment variables
    environment {
        AWS_REGION = 'us-east-1'
        TERRAFORM_VERSION = '1.7.0'
        TERRAGRUNT_VERSION = '0.54.0'
        TF_LOG = 'INFO'  // Change to DEBUG for troubleshooting
        PATH = "${PATH}:/usr/local/bin"
    }
    
    // Build triggers
    triggers {
        // Trigger on GitHub push to main branch
        githubPush()
        
        // Poll GitHub every 5 minutes (fallback if webhook fails)
        pollSCM('H/5 * * * *')
    }
    
    options {
        // Keep last 30 builds
        buildDiscarder(logRotator(numToKeepStr: '30'))
        
        // Build timeout after 1 hour
        timeout(time: 1, unit: 'HOURS')
        
        // Don't run concurrent builds for same branch
        disableConcurrentBuilds()
        
        // Add timestamps to log output
        timestamps()
    }
    
    stages {
        stage('01: Checkout Code') {
            steps {
                script {
                    echo "========== Stage 1: Checkout Code =========="
                    echo "Repository: ${GIT_URL}"
                    echo "Branch: ${GIT_BRANCH}"
                }
                
                checkout(scm)
                
                script {
                    // Get commit info for reporting
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=%an',
                        returnStdout: true
                    ).trim()
                }
                
                echo "✓ Code checked out successfully"
                echo "Commit: ${GIT_COMMIT}"
                echo "Message: ${GIT_COMMIT_MSG}"
                echo "Author: ${GIT_AUTHOR}"
            }
        }
        
        stage('02: Validate Code') {
    steps {
        script {
            echo "========== Stage 2: Validate Code =========="
        }

        sh '''
            echo "→ Initializing and validating Terraform..."
            cd environments/${ENVIRONMENT}/vpc
            terraform init
            terraform fmt -check
            terraform validate
            echo "✓ Terraform validation passed"
        '''
    }
}
        
        stage('03: Generate Plan') {
            steps {
                script {
                    echo "========== Stage 3: Generate Plan =========="
                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "Action: ${params.ACTION}"
                }
                
                sh '''
    echo "→ Initializing Terraform for ${ENVIRONMENT}..."
    cd environments/${ENVIRONMENT}/vpc
    terraform init
    echo "✓ Terraform initialized"
'''

sh '''
    echo "→ Generating Terraform plan..."
    cd environments/${ENVIRONMENT}/vpc
    terraform plan -out=tfplan.binary
    echo "✓ Plan generated and saved"
'''
                
                script {
    // Parse plan output for summary
    def planOutput = sh(
        script: '''
            cd environments/${ENVIRONMENT}/vpc
            terraform show tfplan.binary | grep -E "(Plan:|Destroy|Change)" || echo "Plan output captured"
        ''',
        returnStdout: true
    ).trim()
    
    env.PLAN_SUMMARY = planOutput
    echo "Plan Summary:"
    echo planOutput
}
            }
        }
        
        stage('04: Approval Gate') {
            when {
                expression {
                    // Skip approval for 'plan' action, require for 'apply'
                    params.ACTION == 'apply'
                }
            }
            steps {
                script {
                    echo "========== Stage 4: Manual Approval =========="
                    echo "Environment: ${params.ENVIRONMENT}"
                    
                    if (params.AUTO_APPROVE) {
                        echo "⚠ AUTO_APPROVE enabled - skipping manual approval"
                    } else if (params.ENVIRONMENT == 'prod') {
                        echo "⚠ PRODUCTION ENVIRONMENT - Requires explicit approval"
                        echo "Plan output: ${PLAN_SUMMARY}"
                        
                        timeout(time: 30, unit: 'MINUTES') {
                            input(
                                message: "Do you want to deploy to PRODUCTION?",
                                submitter: "ops-team,devops-team",  // Only these Jenkins groups can approve
                                ok: "Deploy to PROD"
                            )
                        }
                        echo "✓ Production deployment approved"
                    } else {
                        echo "ℹ Non-production environment - auto-approved"
                    }
                }
            }
        }
        
        stage('05: Apply Changes') {
            when {
                expression {
                    params.ACTION == 'apply'
                }
            }
            steps {
                script {
                    echo "========== Stage 5: Apply Changes =========="
                    echo "Deploying to ${params.ENVIRONMENT}..."
                }
                
                sh '''
    echo "→ Applying Terraform configuration..."
    cd environments/${ENVIRONMENT}/vpc
    terraform apply tfplan.binary
    echo "✓ Terraform apply completed"
'''
                
                sh '''
    echo "→ Capturing outputs..."
    cd environments/${ENVIRONMENT}/vpc
    terraform output -json > outputs.json
    cat outputs.json
'''
                
                script {
                    // Capture output values
                    def outputs = readJSON file: "environments/${ENVIRONMENT}/vpc/outputs.json"
                    env.VPC_ID = outputs.vpc_id?.value ?: "N/A"
                    env.SUBNETS = outputs.public_subnet_ids?.value?.join(", ") ?: "N/A"
                    
                    echo "VPC ID: ${VPC_ID}"
                    echo "Subnets: ${SUBNETS}"
                }
            }
        }
        
        stage('06: Report Results') {
            steps {
                script {
                    echo "========== Stage 6: Report Results =========="
                }
                
                // Archive artifacts
                archiveArtifacts(
                    artifacts: "environments/${ENVIRONMENT}/vpc/*.json,environments/${ENVIRONMENT}/vpc/tfplan.binary",
                    allowEmptyArchive: true
                )
                
                // Publish test results if available
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'terraform-reports',
                    reportFiles: 'index.html',
                    reportName: 'Terraform Report'
                ])
                
                script {
                    // Prepare notification message
                    def status = currentBuild.result ?: 'SUCCESS'
                    def message = """
                    ✓ Infrastructure Deployment Report
                    
                    Environment: ${params.ENVIRONMENT}
                    Action: ${params.ACTION}
                    Status: ${status}
                    Build: ${env.BUILD_NUMBER}
                    
                    Triggered by: ${env.GIT_AUTHOR}
                    Commit: ${env.GIT_COMMIT}
                    Message: ${env.GIT_COMMIT_MSG}
                    
                    Details: ${env.BUILD_URL}console
                    """
                    
                    echo message
                    env.NOTIFICATION_MESSAGE = message
                }
                
                // Send to Slack if webhook configured
                sh '''
                    if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
                        echo "Sending Slack notification..."
                        curl -X POST $SLACK_WEBHOOK_URL \
                            -H 'Content-Type: application/json' \
                            -d "{\"text\":\"${NOTIFICATION_MESSAGE}\"}" || true
                    fi
                '''
            }
        }
    }
    
    post {
        always {
            script {
                echo "========== Pipeline Completed =========="
                echo "Build Status: ${currentBuild.result}"
                echo "Duration: ${currentBuild.durationString}"
            }
            
            // Clean up workspace
            cleanWs()
        }
        
        success {
            script {
                echo "✓ Infrastructure automation pipeline completed successfully"
            }
        }
        
        failure {
            script {
                echo "✗ Pipeline failed - review logs for errors"
                
                // Send failure notification
                sh '''
                    if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
                        curl -X POST $SLACK_WEBHOOK_URL \
                            -H 'Content-Type: application/json' \
                            -d '{"text":"Infrastructure pipeline FAILED - ${ENVIRONMENT} - Build #${BUILD_NUMBER}"}' || true
                    fi
                '''
            }
        }
    }
}
