Dưới đây là bản **hướng dẫn CI/CD với Jenkins** bạn có thể **copy thẳng vào README project** (đã viết lại gọn, chuẩn, dễ follow cho team):

---

# 🚀 CI/CD với Jenkins

## 📌 Mục tiêu

Thiết lập pipeline CI/CD:

* Pull code từ GitHub
* Build project
* (Optional) Build Docker image
* (Optional) Deploy

---

# 🧱 1. Cài Jenkins bằng Docker

Chạy lệnh:

```bash
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins \
-v jenkins_home:/var/jenkins_home \
-v /var/run/docker.sock:/var/run/docker.sock \
jenkins/jenkins:lts
```

👉 Truy cập:

```
http://localhost:8080
```

👉 Lấy password:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

---

# 🔌 2. Cài plugin

Chọn:

```
Install suggested plugins
```

---

# 🔐 3. Kết nối GitHub

## 3.1 Tạo Personal Access Token

Trên GitHub:

```
Settings → Developer settings → Personal access tokens
```

* Scope: `repo`

---

## 3.2 Thêm credentials vào Jenkins

* Manage Jenkins → Credentials → Add

| Field    | Value                  |
| -------- | ---------------------- |
| Kind     | Username with password |
| Username | GitHub username        |
| Password | Personal Access Token  |
| ID       | `github-creds`         |

---

# 📦 4. Tạo Pipeline Job

* New Item → Pipeline
* Nhập tên job

---

# 🔗 5. Kết nối Repository

Trong job:

* Chọn:

```
Pipeline script from SCM
```

* Cấu hình:

| Field          | Value                       |
| -------------- | --------------------------- |
| SCM            | Git                         |
| Repository URL | Repo GitHub                 |
| Credentials    | github-creds                |
| Branch         | main (hoặc branch bạn dùng) |

---

# 📜 6. Tạo Jenkinsfile

Tạo file `Jenkinsfile` ở root project:

## 🔹 Pipeline cơ bản

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-username/your-repo.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Build project...'
            }
        }
    }
}
```

---

## 🔹 Ví dụ với Java (Maven)

```groovy
stage('Build') {
    steps {
        sh 'mvn clean package -DskipTests'
    }
}
```

---

## 🔹 Ví dụ với NodeJS

```groovy
stage('Build') {
    steps {
        sh 'npm install'
        sh 'npm run build'
    }
}
```

---

# ▶️ 7. Chạy Pipeline

* Click **Build Now**

👉 Kết quả mong đợi:

```
Cloning repository...
Build project...
```

---


# 🐳 9. (Optional) Build & Push Docker

## Thêm credentials Docker Hub

| Field    | Value              |
| -------- | ------------------ |
| ID       | dockerhub          |
| Username | DockerHub username |
| Password | DockerHub password |

---

## Jenkinsfile

```groovy
stage('Docker Build') {
    steps {
        sh 'docker build -t youruser/app .'
    }
}

stage('Docker Push') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub',
            usernameVariable: 'USER',
            passwordVariable: 'PASS'
        )]) {
            sh 'docker login -u $USER -p $PASS'
            sh 'docker push youruser/app'
        }
    }
}
```

---

# 🚀 10. (Optional) Deploy

Ví dụ với docker-compose:

```groovy
stage('Deploy') {
    steps {
        sh 'docker-compose down && docker-compose up -d'
    }
}
```

---

# ⚠️ Lưu ý

* Jenkins chạy trong Docker cần mount:

  ```
  /var/run/docker.sock
  ```
* Không dùng `^` trong PowerShell
* Repo private phải dùng credentials
* Test fail → pipeline fail

---

# 🎯 Kết quả đạt được

* ✅ Tự động build khi push code
* ✅ Kiểm tra lỗi sớm (CI)
* ✅ Sẵn sàng deploy (CD)

---

# 🚀 Gợi ý nâng cao

* Pipeline cho nhiều service (microservices)
* Dùng Kubernetes để deploy
* Tối ưu cache build
* Parallel pipeline

---
