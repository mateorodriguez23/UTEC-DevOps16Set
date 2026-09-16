pipeline {
    agent any

    environment {
        IMAGE_NAME     = 'mi-app-web'
        CONTAINER_NAME = 'mi-contenedor-web'

        // ====================================================================
        // ---> CAMBIA ESTAS VARIABLES POR LOS DATOS DE TU ENTORNO <---
        // ====================================================================
        VM_IP     = '192.168.1.122'      // IP de la máquina destino (donde corre el contenedor)
        VM_USER   = 'jenkins'            // Usuario SSH en la máquina destino
        SSH_CREDS = 'ssh-vm-vmware'      // ID de la credencial creada en Jenkins (Paso 3)
        // REPO_URL = 'https://github.com/TU_USUARIO/TU_REPOSITORIO.git'
    }

    stages {
        stage('Descargar código') {
            steps {
                // Si la tarea de Jenkins está configurada como "Pipeline script from SCM",
                // Jenkins clona automáticamente el repositorio. Si se corre como script manual:
                checkout scm
                // Alternativa manual (descomentar si no se usa "Pipeline script from SCM"):
                // git branch: 'main', url: 'https://github.com/johonlieghton-source/pipelinetalerjenkins.git'
            }
        }

        stage('Construir Imagen Docker') {
            steps {
                echo 'Construyendo imagen Docker en el Servidor Jenkins...'
                sh "docker build -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Empaquetar Imagen') {
            steps {
                echo 'Convirtiendo imagen a archivo .tar para enviarla...'
                sh "docker save ${IMAGE_NAME}:latest -o ${IMAGE_NAME}.tar"
            }
        }

        stage('Enviar a VM remota') {
            steps {
                echo 'Enviando archivo por SSH a la máquina destino...'
                withCredentials([sshUserPrivateKey(credentialsId: "${SSH_CREDS}", keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        scp -i "\$SSH_KEY" -o StrictHostKeyChecking=no "${IMAGE_NAME}.tar" "${VM_USER}@${VM_IP}:/tmp/${IMAGE_NAME}.tar"
                    """
                }
            }
        }

        stage('Desplegar en VM remota') {
            steps {
                echo 'Levantando el contenedor en la VM remota...'
                withCredentials([sshUserPrivateKey(credentialsId: "${SSH_CREDS}", keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        ssh -i \$SSH_KEY -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} '
                            echo "Deteniendo contenedor anterior (si existe)..."
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true
                            echo "Cargando nueva imagen Docker..."
                            docker load -i /tmp/${IMAGE_NAME}.tar
                            echo "Levantando nuevo contenedor en puerto 80..."
                            docker run -d -p 80:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:latest
                            echo "Limpiando archivo temporal en destino..."
                            rm -f /tmp/${IMAGE_NAME}.tar
                        '
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Limpiando archivos temporales en Servidor Jenkins...'
            sh "rm -f ${IMAGE_NAME}.tar"
        }
        success {
            echo "========================================================="
            echo " ¡Despliegue exitoso en la VM ${VM_IP}:80! "
            echo "========================================================="
        }
        failure {
            echo 'El despliegue falló. Revisa los logs de la consola de Jenkins.'
        }
    }
}
