# Flask Todo Application

A full-featured Todo application built with Flask, featuring user authentication and AWS deployment capabilities.

## Features

- User Authentication (Sign up, Login, Logout)
- Create, Read, Update, and Delete Todos
- Mark Todos as Complete/Incomplete
- Secure Password Hashing
- SQLite Database
- AWS Infrastructure as Code with Terraform
- CI/CD Pipeline with GitHub Actions

## Tech Stack

- **Backend**: Flask, SQLAlchemy
- **Database**: SQLite
- **Authentication**: Flask-Login
- **Infrastructure**: AWS (EC2, VPC, etc.)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Testing**: pytest

## Local Development Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd todo-app
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Run the application:
   ```bash
   python app/app.py
   ```

5. Access the application at `http://localhost:5000`

## Testing

Run the tests using pytest:
```bash
python -m pytest
```

## Deployment

### Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI configured
3. Terraform installed
4. GitHub repository set up

### Setting up AWS Infrastructure

1. First, set up the Terraform state backend:
   ```bash
   cd terraform/state-backend
   terraform init
   terraform apply
   ```

2. Configure the following GitHub Secrets for CI/CD:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `AWS_KEY_NAME`

3. The CI/CD pipeline will automatically:
   - Run tests
   - Deploy to AWS when pushing to the main branch

### Manual Deployment

If you prefer to deploy manually:

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Plan the changes:
   ```bash
   terraform plan
   ```

4. Apply the changes:
   ```bash
   terraform apply
   ```

## Project Structure

```
├── app/
│   ├── __init__.py
│   ├── app.py
│   └── templates/
│       ├── index.html
│       ├── login.html
│       └── signup.html
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── state-backend/
│       └── main.tf
├── tests/
│   ├── conftest.py
│   └── test_app.py
├── requirements.txt
└── README.md
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

This project is licensed under the terms specified in the LICENSE file.